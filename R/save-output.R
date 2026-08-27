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

#' Ensure the parent directory of a file exists
#'
#' Internal helper used by [save_output()] and [.append_accumulator_row()]
#' to confirm that the directory holding a file exists before writing to
#' it. Many save functions error on a missing directory, and that error is
#' a poor description of what actually went wrong.
#'
#' @param file_path Character. The path whose parent directory is checked.
#'
#' @return The directory path, invisibly.
#'
#' @details
#' Missing directories are created rather than reported as an error, since
#' `save_output()` is expected to run unattended on a cluster where nobody
#' is available to intervene. Creation is announced through `cli` so that
#' the action leaves a trace in the job log, whether or not anyone is
#' watching at the time. A bare filename resolves to `"."`, which always
#' exists, so no message is emitted in that case.
#'
#' @keywords internal
.ensure_directory <- function(file_path) {
    target_dir <- fs::path_dir(file_path)

    if (fs::dir_exists(target_dir)) {
        return(invisible(target_dir))
    }

    fs::dir_create(target_dir, recurse = TRUE)

    cli::cli_inform(c(
        "i" = "Created the directory {.file {target_dir}} to hold {.file {fs::path_file(file_path)}}."
    ))

    invisible(target_dir)
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

        if (!identical(existing_header, .accumulator_columns())) {
            cli::cli_abort(c(
                "The existing accumulator does not match the expected schema.",
                "x" = "Found {length(existing_header)} column{?s}: {.val {existing_header}}.",
                "i" = "Expected: {.val {.accumulator_columns()}}.",
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
#' @param output_dir Character. Directory containing (or to contain) the
#'   accumulator. Defaults to `"output"`.
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
                        output_dir = "output") {

    if (missing(.f)) {
        cli::cli_abort("{.arg .f} must be supplied.")
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
