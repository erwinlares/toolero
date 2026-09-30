# R/read-output-records.R

#' Read one or more output records
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Reads the output record, `project-manifest.json`, that
#' [generate_manifest()] writes at the end of an analysis, and returns what
#' it describes as a table with one row per artifact. Given several output
#' folders, it reads each and stacks the results, so that the outputs of a
#' multi-job run (one folder per job, as `submitr::htc_collect()` leaves
#' them) can be inspected as one table.
#'
#' `read_output_records()` is the reader that goes with
#' [generate_manifest()]. The output record is toolero's own format, and this
#' is the one place that interprets it, so other code (including other
#' packages) can read the table this returns rather than parse the file.
#'
#' @param path Character vector or `NULL`. Output folders, each holding a
#'   `project-manifest.json`, an `accumulator.csv`, or both; or paths to
#'   output record files themselves. A named vector labels each folder's
#'   rows in the `source` column with its name; an unnamed one (or an
#'   element with an empty name) uses the path as given. If `NULL` (the
#'   default), reads the project's own output folder, resolved exactly as
#'   [save_output()] and [generate_manifest()] resolve it.
#' @param filename Character. Name of the output record within each folder.
#'   Defaults to `"project-manifest.json"`. Ignored for elements of `path`
#'   that are files rather than folders.
#' @param config Character or `NULL`. Path to a project configuration file
#'   (typically a project's own `_toolero.yml`). Only consulted when `path`
#'   is `NULL`, to find the project's output folder from its `output_dir`
#'   convention. Defaults to `NULL`.
#'
#' @return A tibble with one row per artifact and these columns, in order:
#'
#' * `source` -- the name given to the folder in `path`, or the path itself.
#' * `file_path`, `r_class`, `timestamp`, `function_used`, `status`,
#'   `error_message`, `note` -- the seven artifact fields, exactly as
#'   recorded (see [generate_manifest()]). All character; timestamps are kept
#'   as the strings written, and a `null` in the record becomes `NA`.
#' * `read_from` -- `"output record"`, or `"accumulator"` when the rows came
#'   from the fallback described below.
#' * `schema_version` -- integer; `NA` for rows read from an accumulator.
#' * `execution_context`, `generated_at`, `commit` -- facts about the run
#'   as a whole, repeated on each of its rows; `NA` for rows read from an
#'   accumulator, which does not record them.
#'
#' An output record with no artifacts contributes no rows. When nothing at
#' all can be read, the result is a tibble with these columns and no rows.
#'
#' @section Versions:
#' A record written by toolero 0.5.x carries no `schema_version` and is read
#' as version 1, which is the shape it has. A record with a version this
#' toolero does not know is read as far as possible, with a warning: the
#' fields listed above are taken where they exist and have a single value,
#' and anything else is ignored. The rules are the family's, set out in its
#' `CONVENTIONS.md`.
#'
#' @section When there is no usable output record:
#' An analysis that stopped before [generate_manifest()] ran, or whose
#' record cannot be parsed, may still have left its accumulator behind.
#' For each folder, `read_output_records()` reads the output record when it
#' can; otherwise it reads `accumulator.csv` from the same folder, keeping
#' the latest row per `file_path` exactly as [generate_manifest()] would,
#' and warns that it did so. A folder with neither contributes no rows,
#' also with a warning. One incomplete folder therefore never stops the
#' others from being read. A path that does not exist at all is an error,
#' since that is a mistake in the call rather than a fact about a run.
#'
#' @seealso [generate_manifest()], which writes the output record, and
#'   [save_output()], which feeds it.
#'
#' @examples
#' output_dir <- withr::local_tempdir()
#'
#' save_output(
#'   object = mtcars,
#'   file_path = fs::path(output_dir, "mtcars.rds"),
#'   .f = saveRDS,
#'   output_dir = output_dir
#' )
#' generate_manifest(output_dir = output_dir, git_root = output_dir)
#'
#' read_output_records(output_dir)
#'
#' \dontrun{
#' # Several jobs brought back by submitr: label each job's rows by group.
#' jobs <- submitr::htc_collect()
#' jobs <- jobs[!is.na(jobs$output_dir), ]
#' records <- read_output_records(stats::setNames(jobs$output_dir, jobs$group_id))
#' }
#'
#' @export
read_output_records <- function(path = NULL,
                                filename = "project-manifest.json",
                                config = NULL) {

    if (is.null(path)) {
        path <- .resolve_output_dir(NULL, config)
    }

    if (!is.character(path) || length(path) == 0L ||
        anyNA(path) || !all(nzchar(path))) {
        cli::cli_abort(c(
            "{.arg path} must be a character vector of folder or file paths, with no missing or empty elements.",
            "x" = "Received {.obj_type_friendly {path}} of length {length(path)}."
        ))
    }

    if (!rlang::is_string(filename) || !nzchar(filename)) {
        cli::cli_abort(c(
            "{.arg filename} must be a single, non-empty character string.",
            "x" = "Received {.obj_type_friendly {filename}} of length {length(filename)}."
        ))
    }

    absent <- path[!fs::file_exists(path)]
    if (length(absent) > 0L) {
        cli::cli_abort(c(
            "{length(absent)} element{?s} of {.arg path} do{?es/} not exist.",
            "x" = "Not found: {.path {unname(absent)}}."
        ))
    }

    sources <- names(path)
    paths   <- unname(as.character(path))
    if (is.null(sources)) {
        sources <- paths
    }
    unnamed <- is.na(sources) | !nzchar(sources)
    sources[unnamed] <- paths[unnamed]

    rows <- Map(
        function(p, s) .read_output_source(p, s, filename),
        paths,
        sources
    )

    out <- do.call(rbind, c(list(.output_records_template()), unname(rows)))
    rownames(out) <- NULL

    tibble::as_tibble(out)
}

#' Column template for read_output_records()
#'
#' Internal helper returning a zero-row data frame with the columns
#' [read_output_records()] returns, in order and with their types. Every
#' per-folder result is built on it, so the stacked table has the same
#' shape however many folders contributed rows, including none.
#'
#' @return A data frame with no rows.
#'
#' @keywords internal
.output_records_template <- function() {
    artifact_cols <- rep(list(character(0)), length(.accumulator_columns()))
    names(artifact_cols) <- .accumulator_columns()

    data.frame(
        c(
            list(source = character(0)),
            artifact_cols,
            list(
                read_from         = character(0),
                schema_version    = integer(0),
                execution_context = character(0),
                generated_at      = character(0),
                commit            = character(0)
            )
        ),
        stringsAsFactors = FALSE,
        check.names = FALSE
    )
}

#' Read one element of read_output_records()'s path
#'
#' Internal helper that reads one folder (or one output record file),
#' falling back to the folder's accumulator when there is no usable
#' output record, and returns its rows on [.output_records_template()].
#' Problems with the folder's contents are warnings, never errors, so
#' that one incomplete folder does not stop the rest from being read.
#'
#' @param path Character. An output folder, or an output record file.
#' @param source Character. The label for this element's rows.
#' @param filename Character. Name of the output record within a folder.
#'
#' @return A data frame on [.output_records_template()].
#'
#' @keywords internal
.read_output_source <- function(path, source, filename) {
    if (fs::is_dir(path)) {
        folder      <- path
        record_path <- fs::path(path, filename)
    } else {
        folder      <- fs::path_dir(path)
        record_path <- path
    }

    if (fs::file_exists(record_path)) {
        parsed <- .parse_output_record(record_path)
        if (is.null(parsed$problem)) {
            return(.output_record_rows(parsed$record, parsed$version, source))
        }
        problem   <- paste0("its output record could not be read (", parsed$problem, ")")
        no_record <- FALSE
    } else {
        problem   <- "it has no output record"
        no_record <- TRUE
    }

    accumulator_path <- fs::path(folder, "accumulator.csv")

    if (fs::file_exists(accumulator_path)) {
        accumulator <- tryCatch(
            .read_accumulator(folder),
            error = function(cnd) cnd
        )

        if (!inherits(accumulator, "error")) {
            artifacts <- .dedupe_accumulator(accumulator)
            cli::cli_warn(c(
                "!" = "Read {.path {path}} from its accumulator, because {problem}.",
                "i" = "{nrow(artifacts)} artifact{?s} read; run-level fields ({.field execution_context}, {.field generated_at}, {.field commit}) are {.code NA} for these rows.",
                if (no_record) {
                    c("i" = "An accumulator without an output record usually means {.fn generate_manifest} was never reached.")
                }
            ))
            return(.accumulator_rows(artifacts, source))
        }

        accumulator_problem <- conditionMessage(accumulator)
        cli::cli_warn(c(
            "!" = "Nothing was read from {.path {path}}: {problem}, and its accumulator could not be read either.",
            "x" = "{accumulator_problem}"
        ))
        return(.output_records_template())
    }

    cli::cli_warn(c(
        "!" = "Nothing was read from {.path {path}}: {problem}, and there is no accumulator beside it.",
        "i" = "{.fn save_output} writes the accumulator; {.fn generate_manifest} writes the output record."
    ))
    .output_records_template()
}

#' Parse an output record file
#'
#' Internal helper that parses one output record and checks the few things
#' a reader needs before it can trust the file at all: that it is a JSON
#' object, that `schema_version` (when present) is a single number, and
#' that `artifacts` is an array of objects. A record with a version this
#' toolero does not know is returned with a warning, to be read as far as
#' possible.
#'
#' @param record_path Character. Path to the output record.
#'
#' @return A list with elements `record` (the parsed list), `version` (an
#'   integer), and `problem` (`NULL`, or a short description of why the
#'   file cannot be read).
#'
#' @keywords internal
.parse_output_record <- function(record_path) {
    fail <- function(why) list(record = NULL, version = NA_integer_, problem = why)

    record <- tryCatch(
        jsonlite::fromJSON(record_path, simplifyVector = FALSE),
        error = function(cnd) cnd
    )

    if (inherits(record, "error")) {
        return(fail("it is not valid JSON"))
    }

    if (!is.list(record) || is.null(names(record))) {
        return(fail("it is not a JSON object"))
    }

    # [[ rather than $ throughout: $ matches partial names on a list, so a
    # key a later schema version adds could stand in for a missing one.
    version <- record[["schema_version"]]
    if (is.null(version)) {
        # Output records written by toolero 0.5.x have the version 1 shape
        # without the key.
        version <- 1L
    } else if (!is.numeric(version) || length(version) != 1L ||
               is.na(version) || version != round(version)) {
        return(fail("its schema_version is not a whole number"))
    }
    version <- as.integer(version)

    artifacts <- record[["artifacts"]]
    if (!"artifacts" %in% names(record) || !is.list(artifacts) ||
        !is.null(names(artifacts))) {
        return(fail("it has no artifacts array"))
    }

    if (!all(vapply(artifacts, function(a) is.list(a) && !is.null(names(a)), logical(1)))) {
        return(fail("an entry in its artifacts array is not an object"))
    }

    known <- .output_record_schema_version()
    if (!version %in% known) {
        cli::cli_warn(c(
            "!" = "{.path {record_path}} has schema version {version}; this version of {.pkg toolero} reads version {known}.",
            "i" = "Reading the fields it knows, as far as possible. Updating {.pkg toolero} may read more."
        ))
    }

    list(record = record, version = version, problem = NULL)
}

#' Turn a parsed output record into rows
#'
#' Internal helper used by [read_output_records()].
#'
#' @param record A parsed output record, as returned in
#'   [.parse_output_record()]'s `record` element.
#' @param version Integer. The record's schema version.
#' @param source Character. The label for these rows.
#'
#' @return A data frame on [.output_records_template()].
#'
#' @keywords internal
.output_record_rows <- function(record, version, source) {
    artifacts <- record[["artifacts"]]
    n         <- length(artifacts)

    artifact_cols <- lapply(.accumulator_columns(), function(field) {
        vapply(artifacts, function(a) .json_scalar(a[[field]]), character(1))
    })
    names(artifact_cols) <- .accumulator_columns()

    rows <- data.frame(
        c(
            list(source = rep(source, n)),
            artifact_cols,
            list(
                read_from         = rep("output record", n),
                schema_version    = rep(version, n),
                execution_context = rep(.json_scalar(record[["execution_context"]]), n),
                generated_at      = rep(.json_scalar(record[["generated_at"]]), n),
                commit            = rep(.json_scalar(record[["commit"]]), n)
            )
        ),
        stringsAsFactors = FALSE,
        check.names = FALSE
    )

    rbind(.output_records_template(), rows)
}

#' Turn deduplicated accumulator rows into rows
#'
#' Internal helper used by [read_output_records()] for the accumulator
#' fallback.
#'
#' @param artifacts A data frame with the columns given by
#'   [.accumulator_columns()], as returned by [.dedupe_accumulator()].
#' @param source Character. The label for these rows.
#'
#' @return A data frame on [.output_records_template()].
#'
#' @keywords internal
.accumulator_rows <- function(artifacts, source) {
    n <- nrow(artifacts)

    rows <- data.frame(
        c(
            list(source = rep(source, n)),
            as.list(artifacts[, .accumulator_columns(), drop = FALSE]),
            list(
                read_from         = rep("accumulator", n),
                schema_version    = rep(NA_integer_, n),
                execution_context = rep(NA_character_, n),
                generated_at      = rep(NA_character_, n),
                commit            = rep(NA_character_, n)
            )
        ),
        stringsAsFactors = FALSE,
        check.names = FALSE
    )

    rbind(.output_records_template(), rows)
}

#' Reduce a parsed JSON value to a single string
#'
#' Internal helper used by [read_output_records()]. A `null` or absent
#' value becomes `NA`, as does anything that is not a single value (an
#' array or object, which only a record with an unknown schema version
#' could hold where version 1 has a scalar).
#'
#' @param x A value from `jsonlite::fromJSON(simplifyVector = FALSE)`.
#'
#' @return A single character string, or `NA_character_`.
#'
#' @keywords internal
.json_scalar <- function(x) {
    if (is.null(x) || is.list(x) || length(x) != 1L || is.na(x)) {
        return(NA_character_)
    }
    as.character(x)
}
