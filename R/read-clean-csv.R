#' Read and clean a CSV file
#'
#' `read_clean_csv()` reads a CSV file and cleans the column names in one step.
#' It leverages `readr::read_csv()` for reading and `janitor::clean_names()` for
#' making column names tidyverse-friendly (lowercase, no spaces, no special
#' characters). By default, column type messages are suppressed. Set
#' `verbose = TRUE` to display them.
#'
#' @param file_path A character string with the path to the CSV file.
#' @param verbose Logical. If `TRUE`, displays column type messages from
#'   `readr::read_csv()`. Defaults to `FALSE`.
#'
#' @return A tibble with clean column names.
#' @export
#'
#' @examples
#' \dontrun{
#' # Read and clean a CSV file silently
#' data <- read_clean_csv("path/to/file.csv")
#'
#' # Read and clean a CSV file with column type messages displayed
#' data <- read_clean_csv("path/to/file.csv", verbose = TRUE)
#' }
read_clean_csv <- function(file_path, verbose = FALSE) {
    readr::read_csv(file_path, show_col_types = verbose) |>
        janitor::clean_names()
}
