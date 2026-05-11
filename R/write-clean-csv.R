#' Write a cleaned data frame to a CSV file
#'
#' `write_clean_csv()` writes a data frame to a CSV file using
#' `readr::write_csv()` and emits a cli confirmation message reporting
#' the number of rows and columns written. It is the natural counterpart
#' to `read_clean_csv()`, reinforcing the convention that `data-raw/`
#' holds original inputs and `data/` holds cleaned, analysis-ready outputs.
#'
#' If column names are not already clean, `write_clean_csv()` applies
#' `janitor::clean_names()` before writing and emits a warning listing
#' the affected columns.
#'
#' @param data A data frame or tibble to write.
#' @param path A character string with the path to the output CSV file.
#' @param overwrite Logical. If `FALSE` (the default), errors if the file
#'   already exists. Set to `TRUE` to overwrite an existing file.
#' @param ... Additional arguments passed to `readr::write_csv()`, such as
#'   `append`, `col_names`, or `quote`.
#'
#' @return Invisibly returns `path`.
#' @export
#'
#' @examples
#' \donttest{
#' sample_path <- system.file("templates", "sample.csv", package = "toolero")
#' data <- read_clean_csv(sample_path)
#'
#' # Write to a temp file
#' out <- tempfile(fileext = ".csv")
#' write_clean_csv(data, out)
#'
#' # Overwrite an existing file
#' write_clean_csv(data, out, overwrite = TRUE)
#'
#' # Dirty names are cleaned automatically with a warning
#' dirty <- data.frame("First Name" = "Jane", "Last Name" = "Doe",
#'                     check.names = FALSE)
#' write_clean_csv(dirty, tempfile(fileext = ".csv"))
#' }
write_clean_csv <- function(
        data,
        path,
        overwrite = FALSE,
        ...) {

    # -- 1. Validate data -------------------------------------------------------
    if (!is.data.frame(data)) {
        cli::cli_abort(
            "{.arg data} must be a data frame or tibble, not {.cls {class(data)}}."
        )
    }

    # -- 2. Validate path -------------------------------------------------------
    if (!is.character(path) || length(path) != 1L) {
        cli::cli_abort(
            "{.arg path} must be a single character string."
        )
    }

    # -- 3. Check for existing file ---------------------------------------------
    if (fs::file_exists(path) && !overwrite) {
        cli::cli_abort(
            "{.path {path}} already exists. Use {.code overwrite = TRUE} to replace it."
        )
    }

    # -- 4. Check and clean column names ----------------------------------------
    original_names <- names(data)
    clean_names    <- names(janitor::clean_names(data))
    dirty          <- original_names[original_names != clean_names]

    if (length(dirty) > 0) {
        cli::cli_warn(
            "Column names were not clean -- applying {.fn janitor::clean_names} \\
            before writing. Affected column{?s}: {.val {dirty}}"
        )
        data <- janitor::clean_names(data)
    }

    # -- 5. Write ---------------------------------------------------------------
    readr::write_csv(data, path, ...)

    # -- 6. Confirm -------------------------------------------------------------
    cli::cli_alert_success(
        "Wrote {nrow(data)} row{?s} and {ncol(data)} column{?s} to {.path {path}}."
    )

    invisible(path)
}
