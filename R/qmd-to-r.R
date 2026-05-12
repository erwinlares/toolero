#' Extract R code from a Quarto document
#'
#' `qmd_to_r()` extracts R code chunks from a `.qmd` file and writes them
#' to a standalone `.R` script using `knitr::purl()`. It works on any `.qmd`
#' file regardless of whether it was created with `create_qmd()`.
#'
#' @param input A character string with the path to the `.qmd` file.
#' @param output A character string with the path to the output `.R` file.
#'   If `NULL` (the default), the output file is written to the same directory
#'   as `input` with the `.qmd` extension replaced by `.R`.
#' @param documentation An integer controlling how much documentation is
#'   included in the extracted script. Passed to `knitr::purl()`:
#'   `0` strips all documentation; `1` (the default) includes chunk labels
#'   as comments; `2` includes full roxygen blocks.
#' @param quiet Logical. If `TRUE` (the default), suppresses knitr's own
#'   output. toolero provides its own cli feedback instead.
#'
#' @return Invisibly returns the path to the output `.R` file.
#' @export
#'
#' @examples
#' \donttest{
#' # Extract R code from a qmd file
#' qmd <- tempfile(fileext = ".qmd")
#' writeLines(c(
#'   "---",
#'   "title: Analysis",
#'   "---",
#'   "",
#'   "```{r}",
#'   "x <- 1 + 1",
#'   "```"
#' ), qmd)
#'
#' # Default output path: same directory, .R extension
#' qmd_to_r(input = qmd)
#'
#' # Explicit output path
#' out <- tempfile(fileext = ".R")
#' qmd_to_r(input = qmd, output = out)
#'
#' # Strip all documentation
#' qmd_to_r(input = qmd, output = out, documentation = 0L)
#' }
qmd_to_r <- function(
        input,
        output        = NULL,
        documentation = 1L,
        quiet         = TRUE) {

    # -- 1. Check knitr is available --------------------------------------------
    if (!requireNamespace("knitr", quietly = TRUE)) {
        cli::cli_abort(
            "{.pkg knitr} is required for {.fn qmd_to_r}. \\
            Install it with {.code install.packages(\"knitr\")}."
        )
    }

    # -- 2. Validate input ------------------------------------------------------
    if (!is.character(input) || length(input) != 1L) {
        cli::cli_abort(
            "{.arg input} must be a single character string."
        )
    }

    if (!fs::file_exists(input)) {
        cli::cli_abort(
            "File {.path {input}} does not exist."
        )
    }

    if (!grepl("\\.qmd$", input, ignore.case = TRUE)) {
        cli::cli_abort(
            "{.path {input}} does not appear to be a .qmd file."
        )
    }

    # -- 3. Validate documentation ----------------------------------------------
    if (!documentation %in% c(0L, 1L, 2L)) {
        cli::cli_abort(
            "{.arg documentation} must be 0, 1, or 2."
        )
    }

    # -- 4. Resolve output path -------------------------------------------------
    if (is.null(output)) {
        output <- fs::path_ext_set(input, "R")
    }

    if (!is.character(output) || length(output) != 1L) {
        cli::cli_abort(
            "{.arg output} must be a single character string."
        )
    }

    # -- 5. Purl ----------------------------------------------------------------
    knitr::purl(
        input         = input,
        output        = output,
        documentation = documentation,
        quiet         = quiet
    )

    # -- 6. Confirm -------------------------------------------------------------
    cli::cli_alert_success(
        "Extracted R code from {.path {input}} to {.path {output}}."
    )

    invisible(output)
}
