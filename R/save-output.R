# R/save-output.R

#' Capture a readable name for a save function
#'
#' Internal helper used by [save_output()] to turn the unevaluated `.f`
#' argument into a readable label for the accumulator's `function_used`
#' column. Named and namespaced functions are recorded as written at the
#' call site. Anonymous functions fall back to a single-line, length-capped
#' label rather than a bare multi-line dump of the function body.
#'
#' @param f_expr A character vector, the result of
#'   `deparse(substitute(.f))` evaluated in the caller's frame.
#' @param max_chars Integer. Maximum length of a returned anonymous-function
#'   label before truncation.
#'
#' @return A single character string.
#'
#' @details
#' The returned string may contain literal braces when `.f` was anonymous.
#' It is written to the accumulator as data and is safe there, but any
#' `cli` message echoing this value must interpolate it (`{.val {x}}`)
#' rather than pasting it into the message template, or the braces will be
#' evaluated as inline markup.
#'
#' @keywords internal
.capture_function_name <- function(f_expr, max_chars = 200L) {
    is_anonymous <- length(f_expr) > 1L ||
        grepl("^function\\s*\\(", trimws(f_expr[1]))

    if (!is_anonymous) {
        return(f_expr[1])
    }

    body_text <- paste(trimws(f_expr), collapse = " ")
    body_text <- gsub("\\s+", " ", body_text)

    if (nchar(body_text) > max_chars) {
        body_text <- paste0(substr(body_text, 1L, max_chars), "...")
    }

    as.character(glue::glue("anonymous function: {body_text}"))
}

#' Normalize a value for single-line CSV storage
#'
#' Internal helper collapsing embedded newlines and runs of whitespace to
#' single spaces, so that one accumulator row occupies one physical line.
#'
#' @param x A character string or `NULL`.
#'
#' @return A single character string, or `NA_character_` when `x` is `NULL`.
#'
#' @keywords internal
.flatten_field <- function(x) {
    if (is.null(x) || length(x) == 0L) {
        return(NA_character_)
    }
    trimws(gsub("\\s+", " ", paste(x, collapse = " ")))
}

#' Accumulator column schema
#'
#' Internal helper returning the canonical column names of
#' `accumulator.csv`, in order. Single source of truth shared by
#' [.append_accumulator_row()] and the manifest reader, so that schema
#' drift surfaces as an error rather than as silently misaligned rows.
#'
#' @return A character vector of column names.
#'
#' @keywords internal
.accumulator_columns <- function() {
    c(
        "file_path",
        "r_class",
        "timestamp",
        "function_used",
        "status",
        "error_message",
        "note"
    )
}

#' Append a row to the project accumulator
#'
#' Internal helper used by [save_output()] to record one row of metadata to
#' `output_dir/accumulator.csv`, creating the file (with headers) on first
#' write and appending without headers thereafter.
#'
#' @param row A single-row data frame whose columns match
#'   [.accumulator_columns()] exactly, in order.
#' @param output_dir Character. Directory containing (or to contain)
#'   `accumulator.csv`.
#'
#' @return The path to the accumulator, invisibly.
#'
#' @details
#' When the accumulator already exists, its header is read and compared
#' against the expected schema before appending. A mismatch aborts rather
#' than appending misaligned rows to a file written under a different
#' schema version.
#'
#' `NA` values are written as empty fields. Any reader of this file must
#' pass `na.strings = ""` to recover them as `NA` rather than as empty
#' strings.
#'
#' @keywords internal
.append_accumulator_row <- function(row, output_dir = "output") {
    accumulator_path <- fs::path(output_dir, "accumulator.csv")

    .ensure_directory(accumulator_path)

    file_already_exists <- fs::file_exists(accumulator_path)

    if (file_already_exists) {
        existing_header <- names(
            utils::read.csv(
                accumulator_path,
                nrows = 1L,
                colClasses = "character",
                check.names = FALSE
            )
        )

        # expected_columns is bound to a local rather than interpolated
        # directly: cli >= 3.4.0 reads a `{}` expression starting with a dot
        # as an inline style name, so `{.val {.accumulator_columns()}}` fails
        # to format. That failure would land precisely here, in the guard
        # whose job is to explain a schema mismatch, replacing a useful
        # message with a cli parse error.
        expected_columns <- .accumulator_columns()

        if (!identical(existing_header, expected_columns)) {
            cli::cli_abort(c(
                "The existing accumulator does not match the expected schema.",
                "x" = "Found {length(existing_header)} column{?s}: {.val {existing_header}}.",
                "i" = "Expected: {.val {expected_columns}}.",
                "i" = "Remove or rename {.file {accumulator_path}} and re-run."
            ))
        }
    }

    utils::write.table(
        row,
        file = accumulator_path,
        append = file_already_exists,
        sep = ",",
        row.names = FALSE,
        col.names = !file_already_exists,
        quote = TRUE,
        qmethod = "double",
        na = ""
    )

    invisible(accumulator_path)
}

#' Save an object and record it in the project accumulator
#'
#' `save_output()` writes `object` to `file_path` via
#' `.f(object, file_path, ...)`, then -- when `manifest = TRUE` (the
#' default) -- appends a row to the project-level accumulator at
#' `output_dir/accumulator.csv` recording what was saved, how, and whether
#' the write succeeded. The accumulator is the working file later consumed
#' by [generate_manifest()], which deduplicates it and reshapes it into
#' `project-manifest.json`.
#'
#' @param object The object to save.
#' @param file_path Character. A single destination path for `object`. Its
#'   parent directory is created if it does not already exist, and the
#'   creation is reported.
#' @param .f A function used to perform the save, called as
#'   `.f(object, file_path, ...)`. Supply the function itself (for example
#'   `saveRDS`, `ggplot2::ggsave`), not a call and not a string. Avoid
#'   reassignment indirection (`my_fn <- ggsave; .f = my_fn`) -- the
#'   accumulator records the name exactly as written at the call site, so
#'   this records `"my_fn"` rather than `"ggsave"`. Anonymous functions are
#'   recorded as `"anonymous function: ..."` with the body collapsed to a
#'   single truncated line.
#' @param ... Additional arguments passed to `.f`.
#' @param manifest Logical. When `TRUE` (default), append a row to the
#'   accumulator. When `FALSE`, `object` is still saved via `.f`, but
#'   nothing is recorded.
#' @param note Character or `NULL`. An optional free-text note recorded
#'   alongside this row.
#' @param output_dir Character or `NULL`. Directory containing (or to
#'   contain) the accumulator. If `NULL` (the default) and `config` is
#'   supplied, resolved from the config's `output_dir` convention; if
#'   `config` is also `NULL`, falls back to `"output"`, the family-wide
#'   convention, unchanged from earlier versions.
#' @param config Character or `NULL`. Path to a project configuration file
#'   (typically a project's own `_toolero.yml`, as written by
#'   [init_project()]). Only consulted when `output_dir` is not supplied;
#'   an explicit `output_dir` always wins. Defaults to `NULL`, which leaves
#'   pre-0.5.1 behavior unchanged.
#'
#' @return `object`, invisibly. Called for its side effects.
#'
#' @details
#' The call to `.f` is wrapped in a narrowly-scoped `tryCatch()` -- only the
#' `.f(object, file_path, ...)` call itself, not the rest of
#' `save_output()`'s body. On failure, a row is still appended recording
#' `status = "failure"` and the caught message, after which the original
#' condition is rethrown unmodified. Its class, message, and call are
#' preserved as caught, so downstream handlers behave as though `.f()` had
#' been called directly. This is the one place in the package where the
#' `cli` convention is deliberately not followed: `cli::cli_abort()` would
#' construct a new condition and discard the original class.
#'
#' `r_class` records `class(object)` as a single pipe-separated field,
#' captured before the write, since class cannot be reliably recovered from
#' the file afterward. Timestamps are recorded in UTC with millisecond
#' precision so that they sort lexicographically -- [generate_manifest()]
#' relies on this when keeping the latest row per `file_path`.
#'
#' @section Project conventions:
#' `config` is entirely opt-in. Nothing changes for a project never
#' scaffolded by [init_project()]: pass `output_dir` (or rely on the
#' `"output"` default) exactly as before. When `config` is supplied but
#' cannot be read, this aborts with the same message [init_project()] gives
#' for a bad `config`, rather than silently falling back to `"output"`.
#'
#' @seealso [generate_manifest()]
#'
#' @examples
#' output_dir <- withr::local_tempdir()
#'
#' save_output(
#'   object = mtcars,
#'   file_path = fs::path(output_dir, "mtcars.rds"),
#'   .f = saveRDS,
#'   note = "Unmodified example data.",
#'   output_dir = output_dir
#' )
#'
#' @export
save_output <- function(object,
                        file_path,
                        .f,
                        ...,
                        manifest = TRUE,
                        note = NULL,
                        output_dir = NULL,
                        config = NULL) {

    if (missing(.f)) {
        cli::cli_abort("{.arg .f} must be supplied.")
    }

    if (is.null(output_dir) && !is.null(config)) {
        resolved   <- .read_config_file(config, arg = "config")
        output_dir <- resolved$conventions$output_dir
        cli::cli_inform("Using {.field output_dir} ({.val {output_dir}}) from {.path {config}}.")
    }

    if (is.null(output_dir)) {
        output_dir <- "output"
    }

    f_expr <- deparse(substitute(.f))

    if (!is.function(.f)) {
        cli::cli_abort(c(
            "{.arg .f} must be a function.",
            "x" = "Received an object of class {.cls {class(.f)}}.",
            "i" = "Supply the function itself, such as {.fn saveRDS}, not its name as a string."
        ))
    }

    if (!is.character(file_path) || length(file_path) != 1L || is.na(file_path)) {
        cli::cli_abort(c(
            "{.arg file_path} must be a single, non-missing character string.",
            "x" = "Received {.obj_type_friendly {file_path}} of length {length(file_path)}."
        ))
    }

    if (!rlang::is_bool(manifest)) {
        cli::cli_abort("{.arg manifest} must be either {.code TRUE} or {.code FALSE}.")
    }

    if (!is.null(note) && !rlang::is_string(note)) {
        cli::cli_abort(c(
            "{.arg note} must be a single character string or {.code NULL}.",
            "x" = "Received {.obj_type_friendly {note}} of length {length(note)}."
        ))
    }

    .ensure_directory(file_path)

    function_used <- .capture_function_name(f_expr)
    r_class <- paste(class(object), collapse = "|")
    timestamp <- format(Sys.time(), "%Y-%m-%dT%H:%M:%OS3Z", tz = "UTC")

    caught_condition <- tryCatch(
        {
            .f(object, file_path, ...)
            NULL
        },
        error = function(cnd) cnd
    )

    if (isTRUE(manifest)) {
        row <- data.frame(
            file_path = file_path,
            r_class = r_class,
            timestamp = timestamp,
            function_used = function_used,
            status = if (is.null(caught_condition)) "success" else "failure",
            error_message = if (is.null(caught_condition)) {
                NA_character_
            } else {
                .flatten_field(conditionMessage(caught_condition))
            },
            note = .flatten_field(note),
            stringsAsFactors = FALSE
        )

        row <- row[, .accumulator_columns(), drop = FALSE]
        .append_accumulator_row(row, output_dir = output_dir)
    }

    if (!is.null(caught_condition)) {
        stop(caught_condition)
    }

    invisible(object)
}
