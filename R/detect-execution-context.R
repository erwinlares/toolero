# R/detect_execution_context.R

#' Detect the current execution context
#'
#' Identifies which of three execution environments the code is currently
#' running in: an interactive R session, a `quarto render` call, or a
#' plain `Rscript` invocation. This is useful for writing code that behaves
#' correctly across all three contexts, such as resolving input file paths
#' in a portable way.
#'
#' @param interactive_fn A function. Used to detect whether the session is
#'   interactive. Defaults to `base::interactive`. Override in tests to
#'   simulate different execution environments.
#'
#' @return A character string, one of `"interactive"`, `"quarto"`, or
#'   `"rscript"`.
#'
#' @details
#' Detection follows a priority order:
#'
#' 1. If `interactive()` is `TRUE`, returns `"interactive"`.
#' 2. If the environment variable `QUARTO_DOCUMENT_PATH` is set and non-empty,
#'    returns `"quarto"`.
#' 3. Otherwise, returns `"rscript"`.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' context <- detect_execution_context()
#'
#' input_file <- switch(context,
#'   interactive = "data/sample.csv",
#'   quarto      = params$input_file,
#'   rscript     = commandArgs(trailingOnly = TRUE)[1]
#' )
#' }
detect_execution_context <- function(interactive_fn = interactive) {
    if (interactive_fn()) {
        return("interactive")
    }

    if (nchar(Sys.getenv("QUARTO_DOCUMENT_PATH")) > 0) {
        return("quarto")
    }

    return("rscript")
}
