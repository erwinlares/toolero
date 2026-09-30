# R/generate-manifest.R

#' Schema version of the output record
#'
#' Internal helper returning the schema version [generate_manifest()]
#' writes as the first key of the output record. Like
#' [.project_yml_schema_version()] for the project config, this is a schema
#' version, not a package version: it increments only when an existing key
#' is removed, renamed, or changes meaning or type, so a reader can decide
#' whether it understands a file without guessing from the toolero version
#' that wrote it. Output records written before the key existed (toolero
#' 0.5.x) carry no `schema_version` and are read as version 1.
#'
#' @return A single integer.
#'
#' @keywords internal
.output_record_schema_version <- function() {
    1L
}

#' Read the current git commit, if any
#'
#' Internal helper used by [generate_manifest()] to record which version of
#' the project's code was checked out when the output record was written.
#' Best effort and silent: returns `NULL` whenever `git` is not installed,
#' `path` is not inside a git repository, or the repository has no commits
#' yet, rather than aborting the output record over a fact that is
#' genuinely optional.
#'
#' Shells out to `git rev-parse HEAD` rather than depending on a git R
#' package, since this is the only place in toolero that needs git at all.
#'
#' @param path Character. Directory to check, passed to `git -C`.
#'
#' @return A single character string (the full 40-character commit SHA), or
#'   `NULL`.
#'
#' @keywords internal
.git_commit <- function(path = ".") {
    if (nzchar(Sys.which("git")) == FALSE) {
        return(NULL)
    }

    result <- tryCatch(
        system2(
            "git",
            c("-C", shQuote(path), "rev-parse", "HEAD"),
            stdout = TRUE,
            stderr = FALSE
        ),
        error = function(cnd) NULL,
        warning = function(cnd) NULL
    )

    status <- attr(result, "status")
    if (!is.null(status) && status != 0L) {
        return(NULL)
    }

    if (is.null(result) || length(result) != 1L || !nzchar(result)) {
        return(NULL)
    }

    result
}

#' Read the project accumulator
#'
#' Internal helper used by [generate_manifest()] to read
#' `output_dir/accumulator.csv` back into a data frame, validating its
#' header against the expected schema.
#'
#' @param output_dir Character. Directory containing `accumulator.csv`.
#'
#' @return A data frame with the columns given by [.accumulator_columns()],
#'   all of type character.
#'
#' @details
#' A missing accumulator is an error rather than an empty result. The file
#' is created by the first [save_output()] call, so its absence means no
#' save was ever recorded -- most often because `save_output()` was called
#' with a different `output_dir`, or with `manifest = FALSE`, or was never
#' reached at all. Returning an empty output record in that case would
#' present a setup mistake as a finished record.
#'
#' Every column is read as character. Timestamps in particular must not be
#' coerced, since [.dedupe_accumulator()] compares them lexicographically
#' and relies on the exact string written by [save_output()].
#'
#' Empty fields are read back as `NA` via `na.strings = ""`, matching the
#' `na = ""` convention used when the accumulator is written. Without this
#' the `error_message` column of every successful row would return as an
#' empty string rather than `NA`, and that difference would surface in the
#' output record.
#'
#' @keywords internal
.read_accumulator <- function(output_dir = "output") {
    accumulator_path <- fs::path(output_dir, "accumulator.csv")

    if (!fs::file_exists(accumulator_path)) {
        cli::cli_abort(c(
            "No accumulator was found at {.file {accumulator_path}}.",
            "x" = "The output record cannot be written without one.",
            "i" = "{.fn save_output} creates this file on its first call.",
            "i" = "Check that {.fn save_output} was reached, was called with {.code manifest = TRUE}, and used a matching {.arg output_dir}."
        ))
    }

    accumulator <- utils::read.csv(
        accumulator_path,
        colClasses = "character",
        na.strings = "",
        check.names = FALSE,
        stringsAsFactors = FALSE
    )

    # See the note in .append_accumulator_row(): a `{}` expression starting
    # with a dot is read by cli as an inline style name, so the expected
    # schema has to reach the message through a local.
    expected_columns <- .accumulator_columns()
    found_columns    <- names(accumulator)

    if (!identical(found_columns, expected_columns)) {
        cli::cli_abort(c(
            "The accumulator does not match the expected schema.",
            "x" = "Found {length(found_columns)} column{?s}: {.val {found_columns}}.",
            "i" = "Expected: {.val {expected_columns}}.",
            "i" = "Remove or rename {.file {accumulator_path}} and re-run the analysis."
        ))
    }

    accumulator
}

#' Deduplicate accumulator rows by file path
#'
#' Internal helper used by [generate_manifest()] to collapse an
#' append-only accumulator to one row per `file_path`, keeping the most
#' recent row for each.
#'
#' @param accumulator A data frame with the columns given by
#'   [.accumulator_columns()].
#'
#' @return A data frame with the same columns, one row per distinct
#'   `file_path`, ordered by `timestamp` ascending.
#'
#' @details
#' The accumulator is append-only, so re-running an analysis within a
#' session leaves superseded rows behind. Rows are ordered by `timestamp`
#' -- which sorts correctly as a string, since [save_output()] writes UTC
#' with millisecond precision -- and the last row for each path is kept.
#' Position in the file breaks ties, so two rows sharing a timestamp
#' resolve in append order.
#'
#' Note that the surviving row for a path may record a failure: if a save
#' succeeded and a later re-run of the same path failed, the failure is
#' what the output record reports. This is the intended reading. The
#' output record describes the state of the project at the end of the run,
#' not the best outcome observed along the way.
#'
#' @keywords internal
.dedupe_accumulator <- function(accumulator) {
    if (nrow(accumulator) == 0L) {
        return(accumulator)
    }

    ordered <- accumulator[
        order(accumulator$timestamp, seq_len(nrow(accumulator))), ,
        drop = FALSE
    ]

    keep <- !duplicated(ordered$file_path, fromLast = TRUE)

    deduplicated <- ordered[keep, , drop = FALSE]
    rownames(deduplicated) <- NULL

    deduplicated
}

#' Write the output record
#'
#' `generate_manifest()` reads the accumulator written by [save_output()]
#' over the course of an analysis, collapses it to one row per output file,
#' and writes the output record, `project-manifest.json`, describing every
#' artifact the project produced.
#'
#' @param output_dir Character or `NULL`. Directory containing
#'   `accumulator.csv` and receiving the output record. An explicit value is
#'   used exactly as given. If `NULL` (the default), resolved from
#'   `config`'s `output_dir` convention when `config` is supplied, or
#'   `"output"` otherwise, taken from the project root rather than the
#'   working directory, exactly as [save_output()] resolves it, so the two
#'   always meet at the same accumulator.
#' @param filename Character. Name of the output record file. Defaults to
#'   `"project-manifest.json"`.
#' @param overwrite Logical. When `FALSE` (default), an existing output record
#'   at that path is an error rather than being replaced.
#' @param config Character or `NULL`. Path to a project configuration file
#'   (typically a project's own `_toolero.yml`, as written by
#'   [init_project()]). Only consulted when `output_dir` is not supplied;
#'   an explicit `output_dir` always wins. Defaults to `NULL`.
#' @param git_root Character. Directory to check for a git commit to record
#'   in the output record (see the Provenance section below). Defaults to
#'   `"."`.
#'
#' @return The path to the output record, invisibly.
#'
#' @details
#' The output record opens with `schema_version`, then holds
#' `execution_context`, `generated_at`, and `commit` once at the top level,
#' followed by an `artifacts` array with one entry per output file, ordered
#' chronologically. Context, generation time, and commit are facts about the
#' run as a whole rather than about any individual artifact, so they are not
#' repeated per entry. Package and R versions are deliberately
#' absent: that is `renv`'s job, and duplicating it here would create a
#' second record to keep in sync.
#'
#' Field names are toolero's own rather than RO-Crate vocabulary. The
#' translation to `@id`, `dateCreated`, and the rest belongs in
#' `encapsulr::describe()` as a thin mapping layer, so that toolero's
#' public interface does not inherit a downstream package's data model.
#'
#' Checksums are likewise excluded. RO-Crate defers fixity to BagIt and
#' OCFL, and `rocrateR::bag_rocrate()` computes `manifest-sha512.txt`
#' automatically at bagging time.
#'
#' A missing accumulator is an error: no save was ever recorded, and an
#' empty output record would present that as a finished result. An
#' accumulator holding no rows is different -- the file exists, so the
#' machinery was wired up -- and produces an empty output record with a
#' warning.
#'
#' @section Provenance:
#' The output record also holds `commit`: the git commit checked out in
#' `git_root` at the moment the record was written, or `null` when the
#' project is not a git repository, has no commits yet, or `git` is not
#' installed. This is deliberately the one piece of "which version of the
#' code produced this" that package versions cannot supply -- `renv.lock`
#' already answers which package versions were in play, but nothing else
#' records which revision of the analysis script itself ran. Like
#' `execution_context` and `generated_at`, it describes the run as a whole
#' and is not repeated per artifact.
#'
#' `config` is entirely opt-in and affects `output_dir` only, not `commit`.
#' Without it, `output_dir` defaults to `output/` under the project root.
#' When `config` is supplied but cannot be read, this aborts with the same
#' message [init_project()] gives for a bad `config`, rather than silently
#' falling back to `"output"`.
#'
#' @section Format:
#' The output record is a single JSON object with these keys, in this
#' order:
#'
#' * `schema_version` -- integer, currently `1`.
#' * `execution_context` -- `"interactive"`, `"quarto"`, or `"rscript"`, as
#'   returned by [detect_execution_context()].
#' * `generated_at` -- when the record was written, in UTC with millisecond
#'   precision (`"2026-09-29T18:04:12.345Z"`).
#' * `commit` -- a 40-character git commit SHA, or `null`.
#' * `artifacts` -- an array, empty rather than absent when nothing was
#'   saved. Each entry carries the seven accumulator fields: `file_path`
#'   (relative to the project root when the file is inside the project,
#'   as given to [save_output()] otherwise), `r_class` (the object's
#'   classes joined with `"|"`), `timestamp` (same format as
#'   `generated_at`), `function_used`, `status` (`"success"` or
#'   `"failure"`), `error_message`, and `note`. A field with no value is
#'   written as `null`, never as an empty string.
#'
#' `schema_version` increments only when an existing key is removed,
#' renamed, or changes meaning or type. A record with no `schema_version`
#' was written by toolero 0.5.x and has the version 1 shape without the
#' key. The full specification, including the rules for readers, is in the
#' family's `CONVENTIONS.md`.
#'
#' The output record is toolero's own format. Other packages should treat
#' it as an opaque file rather than parse it.
#'
#' @section The output record and the job manifest:
#' This is the *output record*: a record of outputs from a computation
#' that has already happened. It is distinct from the *job manifest*
#' produced by [write_by_group()] and consumed by
#' `submitr::htc_gen_submit()`, which lists inputs to a computation about
#' to happen. The file name, `project-manifest.json`, and this function's
#' name predate the family's vocabulary and are kept for compatibility;
#' the file defaults to `project-manifest.json` rather than
#' `manifest.json` so the two documents cannot be confused on disk.
#'
#' @seealso [save_output()]
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
#'
#' generate_manifest(output_dir = output_dir)
#'
#' @export
generate_manifest <- function(output_dir = NULL,
                              filename = "project-manifest.json",
                              overwrite = FALSE,
                              config = NULL,
                              git_root = ".") {

    output_dir <- .resolve_output_dir(output_dir, config)

    if (!rlang::is_string(output_dir)) {
        cli::cli_abort(c(
            "{.arg output_dir} must be a single character string.",
            "x" = "Received {.obj_type_friendly {output_dir}} of length {length(output_dir)}."
        ))
    }

    if (!rlang::is_string(filename)) {
        cli::cli_abort(c(
            "{.arg filename} must be a single character string.",
            "x" = "Received {.obj_type_friendly {filename}} of length {length(filename)}."
        ))
    }

    if (!rlang::is_bool(overwrite)) {
        cli::cli_abort("{.arg overwrite} must be either {.code TRUE} or {.code FALSE}.")
    }

    manifest_path <- fs::path(output_dir, filename)

    if (fs::file_exists(manifest_path) && !overwrite) {
        cli::cli_abort(c(
            "An output record already exists at {.file {manifest_path}}.",
            "i" = "Set {.code overwrite = TRUE} to replace it."
        ))
    }

    artifacts <- .dedupe_accumulator(.read_accumulator(output_dir))

    if (nrow(artifacts) == 0L) {
        cli::cli_warn(c(
            "!" = "The accumulator holds no rows, so the output record is empty.",
            "i" = "{.fn save_output} appends a row for every object it saves.",
            "i" = "An empty output record still shows that the analysis ran and produced nothing."
        ))
    }

    # schema_version comes first, so a reader can decide whether it
    # understands the file before looking at anything else in it.
    schema_version <- .output_record_schema_version()

    manifest <- list(
        schema_version = schema_version,
        execution_context = detect_execution_context(),
        generated_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%OS3Z", tz = "UTC"),
        commit = .git_commit(git_root),
        artifacts = artifacts
    )

    .ensure_directory(manifest_path)

    jsonlite::write_json(
        manifest,
        path = manifest_path,
        auto_unbox = TRUE,
        na = "null",
        null = "null",
        pretty = TRUE
    )

    failures <- sum(artifacts$status == "failure")

    cli::cli_inform(c(
        "v" = "Wrote {.file {manifest_path}} describing {nrow(artifacts)} artifact{?s}.",
        if (failures > 0L) {
            c("!" = "{failures} artifact{?s} recorded a failed write.")
        }
    ))

    invisible(manifest_path)
}
