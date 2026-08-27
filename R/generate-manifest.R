# R/generate-manifest.R

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
#' reached at all. Returning an empty manifest in that case would present a
#' setup mistake as a finished record.
#'
#' Every column is read as character. Timestamps in particular must not be
#' coerced, since [.dedupe_accumulator()] compares them lexicographically
#' and relies on the exact string written by [save_output()].
#'
#' Empty fields are read back as `NA` via `na.strings = ""`, matching the
#' `na = ""` convention used when the accumulator is written. Without this
#' the `error_message` column of every successful row would return as an
#' empty string rather than `NA`, and that difference would surface in the
#' manifest.
#'
#' @keywords internal
.read_accumulator <- function(output_dir = "output") {
    accumulator_path <- fs::path(output_dir, "accumulator.csv")

    if (!fs::file_exists(accumulator_path)) {
        cli::cli_abort(c(
            "No accumulator was found at {.file {accumulator_path}}.",
            "x" = "A project manifest cannot be written without one.",
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

    if (!identical(names(accumulator), .accumulator_columns())) {
        cli::cli_abort(c(
            "The accumulator does not match the expected schema.",
            "x" = "Found {length(names(accumulator))} column{?s}: {.val {names(accumulator)}}.",
            "i" = "Expected: {.val {.accumulator_columns()}}.",
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
#' what the manifest reports. This is the intended reading. The manifest
#' describes the state of the project at the end of the run, not the best
#' outcome observed along the way.
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

#' Write the project manifest
#'
#' `generate_manifest()` reads the accumulator written by [save_output()]
#' over the course of an analysis, collapses it to one row per output file,
#' and writes `project-manifest.json` describing every artifact the project
#' produced.
#'
#' @param output_dir Character. Directory containing `accumulator.csv` and
#'   receiving the manifest. Defaults to `"output"`.
#' @param filename Character. Name of the manifest file. Defaults to
#'   `"project-manifest.json"`.
#' @param overwrite Logical. When `FALSE` (default), an existing manifest
#'   at that path is an error rather than being replaced.
#'
#' @return The path to the manifest, invisibly.
#'
#' @details
#' The manifest records `execution_context` and `generated_at` once at the
#' top level, followed by an `artifacts` array with one entry per output
#' file, ordered chronologically. Context and generation time are facts
#' about the run as a whole rather than about any individual artifact, so
#' they are not repeated per entry. Package and R versions are deliberately
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
#' empty manifest would present that as a finished result. An accumulator
#' holding no rows is different -- the file exists, so the machinery was
#' wired up -- and produces an empty manifest with a warning.
#'
#' @section The project manifest and the job manifest:
#' This is the *project manifest*: a record of outputs from a computation
#' that has already happened. It is distinct from the *job manifest*
#' produced by [write_by_group()] and consumed by
#' `submitr::htc_gen_submit()`, which lists inputs to a computation about
#' to happen. The two are structurally different documents that happen to
#' share a word, which is why this one defaults to
#' `project-manifest.json` rather than `manifest.json`.
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
generate_manifest <- function(output_dir = "output",
                              filename = "project-manifest.json",
                              overwrite = FALSE) {

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
            "A manifest already exists at {.file {manifest_path}}.",
            "i" = "Set {.code overwrite = TRUE} to replace it."
        ))
    }

    artifacts <- .dedupe_accumulator(.read_accumulator(output_dir))

    if (nrow(artifacts) == 0L) {
        cli::cli_warn(c(
            "!" = "The accumulator holds no rows, so the manifest is empty.",
            "i" = "{.fn save_output} appends a row for every object it saves.",
            "i" = "An empty manifest still records that the analysis ran and produced nothing."
        ))
    }

    manifest <- list(
        execution_context = detect_execution_context(),
        generated_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%OS3Z", tz = "UTC"),
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
