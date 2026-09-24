#' Generate a data documentation stub
#'
#' Writes a Markdown file documenting a single dataset, with the standard
#' sections a data-management plan asks for -- source, date obtained,
#' license and usage terms, collection method, variables, and known issues
#' -- pre-filled where they can be, and left as placeholders where they
#' can't.
#'
#' Recall that a research compendium's `data/` and `data-raw/` folders hold
#' the data itself, but not where it came from or what its columns mean.
#' `generate_data_doc()` fills that gap the same way [generate_citation()]
#' fills in for a missing `CITATION.cff`: a skeleton with a few fields
#' already filled in, ready for you to complete by hand.
#'
#' @param dataset A character string. The file name of the dataset this
#'   doc describes, e.g. `"survey_responses.csv"`. Used to name the output
#'   file (the extension is replaced with `.md`) and to fill in the doc's
#'   title; must be supplied, since there is no reasonable default.
#' @param path A character string. Directory in which to write the file.
#'   Defaults to `"data"`.
#' @param overwrite Logical. If `TRUE`, overwrites an existing doc at the
#'   same location. Defaults to `FALSE`.
#'
#' @return Invisibly returns the full path to the written file.
#' @seealso [init_project()], [generate_license()], [generate_citation()]
#' @export
#'
#' @examples
#' \dontrun{
#' generate_data_doc("survey_responses.csv")
#'
#' generate_data_doc("weather_2024.csv", path = "data-raw")
#' }
generate_data_doc <- function(dataset,
                              path      = "data",
                              overwrite = FALSE) {

    # -- 1. Validate dataset --------------------------------------------------
    if (missing(dataset) || !is.character(dataset) ||
        length(dataset) != 1L || !nzchar(dataset)) {
        cli::cli_abort(
            "{.arg dataset} must be supplied, e.g. {.code dataset = \"survey_responses.csv\"}."
        )
    }

    # -- 2. Validate path -------------------------------------------------
    if (!fs::dir_exists(path)) {
        cli::cli_abort(c(
            "{.path {path}} does not exist.",
            "i" = "Create the project first, e.g. with {.fn init_project}."
        ))
    }

    # -- 3. Resolve destination ---------------------------------------------
    doc_name <- paste0(fs::path_ext_remove(fs::path_file(dataset)), ".md")
    dest     <- fs::path_abs(fs::path(path, doc_name))

    # -- 4. Guard against overwriting ----------------------------------------
    if (fs::file_exists(dest) && !overwrite) {
        cli::cli_abort(c(
            "{.path {dest}} already exists.",
            "i" = "Use {.code overwrite = TRUE} to replace it."
        ))
    }

    # -- 5. Fill in the template and write -----------------------------------
    template <- readLines(.package_template("data-doc-template.md"))
    filled   <- gsub("{{DATASET}}", fs::path_file(dataset), template, fixed = TRUE)
    filled   <- gsub("{{DATE}}", format(Sys.Date()), filled, fixed = TRUE)
    writeLines(filled, dest)

    cli::cli_alert_success("Created {.path {dest}}")
    cli::cli_inform(c(
        "i" = "Fill in the source, license, collection method, variables, and
               known issues sections by hand -- {.fn generate_data_doc} only
               drafts the skeleton."
    ))

    invisible(dest)
}
