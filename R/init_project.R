#' Read and clean a CSV file
#'
#' `read_clean_csv()` reads a CSV file and cleans the column names in one step.
#' It leverages `readr::read_csv()` for reading and `janitor::clean_names()` for
#' making column names tidyverse-friendly (lowercase, no spaces, no special characters).
#'
#' @param file_path A character string with the path to the CSV file.
#'
#' @return A tibble with clean column names.
#' @export
#'
#' @examples
#' \dontrun{
#' data <- read_clean_csv("path/to/file.csv")
#' }
read_clean_csv <- function(file_path) {
    readr::read_csv(file_path) |>
        janitor::clean_names()
}
