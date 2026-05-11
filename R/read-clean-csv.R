#' Read and clean a CSV file
#'
#' `read_clean_csv()` reads a CSV file, standardizes column names, optionally
#' handles missing values, and optionally prints an ingest summary. It combines
#' `readr::read_csv()`, `janitor::clean_names()`, and `tidyr::drop_na()` into a
#' single, reproducibility-friendly step.
#'
#' @param path A character string with the path to the CSV file.
#' @param na A character vector of strings to treat as missing values. Passed
#'   directly to `readr::read_csv()`. Defaults to `c("", "NA")`, which matches
#'   `readr`'s own default behavior.
#' @param drop_na Logical or character vector. If `FALSE` (the default), no
#'   rows are dropped. If `TRUE`, drops all rows containing any missing value.
#'   If a character vector of column names, drops only rows with missing values
#'   in those columns. Always emits a cli message reporting how many rows were
#'   dropped and how many remain.
#' @param summary Logical. If `TRUE`, prints a brief ingest summary after
#'   reading and cleaning: row and column counts, number of column names
#'   cleaned, and missing value totals. Reflects the final state of the tibble
#'   after any `drop_na` action. Defaults to `FALSE`.
#' @param verbose Logical. If `TRUE`, displays column type messages from
#'   `readr::read_csv()`. Defaults to `FALSE`.
#' @param ... Additional arguments passed to `readr::read_csv()`, such as
#'   `col_types`, `skip`, or `locale`.
#'
#' @return A tibble with cleaned column names.
#' @export
#'
#' @examples
#' \donttest{
#' sample_path <- system.file("templates", "sample.csv", package = "toolero")
#'
#' # Basic usage
#' data <- read_clean_csv(sample_path)
#'
#' # Explicit missing-value codes
#' data <- read_clean_csv(sample_path, na = c("", "NA", "N/A", ".", "-999"))
#'
#' # Drop rows missing in any column
#' data <- read_clean_csv(sample_path, drop_na = TRUE)
#'
#' # Drop rows missing in specific columns
#' data <- read_clean_csv(sample_path, drop_na = c("bill_length_mm", "sex"))
#'
#' # Print ingest summary
#' data <- read_clean_csv(sample_path, summary = TRUE)
#'
#' # Combine arguments
#' data <- read_clean_csv(
#'   sample_path,
#'   na      = c("", "NA", "N/A", "."),
#'   drop_na = TRUE,
#'   summary = TRUE
#' )
#' }
read_clean_csv <- function(
        path,
        na      = c("", "NA"),
        drop_na = FALSE,
        summary = FALSE,
        verbose = FALSE,
        ...) {

    # -- 1. Validate path -------------------------------------------------------
    if (!fs::file_exists(path)) {
        cli::cli_abort(
            "File {.path {path}} does not exist."
        )
    }

    # -- 2. Read and clean names ------------------------------------------------
    original_names <- names(readr::read_csv(
        path,
        na           = na,
        show_col_types = FALSE,
        n_max        = 0,
        ...
    ))

    data <- readr::read_csv(
        path,
        na             = na,
        show_col_types = verbose,
        ...
    ) |>
        janitor::clean_names()

    cleaned_names  <- names(data)
    n_names_changed <- sum(original_names != cleaned_names)

    # -- 3. Handle drop_na ------------------------------------------------------
    if (!isFALSE(drop_na)) {
        rows_before <- nrow(data)

        if (isTRUE(drop_na)) {
            data <- tidyr::drop_na(data)
            rows_after   <- nrow(data)
            rows_dropped <- rows_before - rows_after
            cli::cli_inform(
                "Dropped {rows_dropped} row{?s} with missing values across all \\
                columns -- {rows_after} row{?s} remaining."
            )
        } else if (is.character(drop_na)) {
            bad_cols <- setdiff(drop_na, cleaned_names)
            if (length(bad_cols) > 0) {
                cli::cli_abort(
                    "Column{?s} not found in data: {.val {bad_cols}}"
                )
            }
            data <- tidyr::drop_na(data, tidyr::all_of(drop_na))
            rows_after   <- nrow(data)
            rows_dropped <- rows_before - rows_after
            cli::cli_inform(
                "Dropped {rows_dropped} row{?s} with missing values in \\
                column{?s}: {.val {drop_na}} -- {rows_after} row{?s} remaining."
            )
        } else {
            cli::cli_abort(
                "{.arg drop_na} must be {.code TRUE}, {.code FALSE}, or a \\
                character vector of column names."
            )
        }
    }

    # -- 4. Print ingest summary ------------------------------------------------
    if (isTRUE(summary)) {
        n_rows        <- nrow(data)
        n_cols        <- ncol(data)
        n_missing     <- sum(is.na(data))
        cols_missing  <- sum(colSums(is.na(data)) > 0)

        cli::cli_inform(c(
            "v" = "Read {n_rows} row{?s} and {n_cols} column{?s}.",
            "i" = "{n_names_changed} column name{?s} cleaned.",
            "i" = "{cols_missing} column{?s} contain missing values \\
                   ({n_missing} total missing value{?s})."
        ))
    }

    data
}
