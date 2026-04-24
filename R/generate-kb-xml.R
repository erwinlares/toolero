#' Generate a KB-importable XML file from a Quarto document
#'
#' Takes a Quarto document and produces an XML file that is directly
#' importable into a UW-Madison Knowledge Base (KB) article. The function
#' re-renders the `.qmd` with `embed-resources: true` so all visual assets
#' are self-contained, extracts the HTML body, and wraps it in the KB XML
#' structure along with metadata drawn from the document's YAML header.
#'
#' @param html_path A string. Path to the rendered HTML file. Used to infer
#'   the output filename and, if `qmd_path` is `NULL`, the location of the
#'   source `.qmd`.
#' @param qmd_path A string or `NULL`. Path to the source `.qmd` file. If
#'   `NULL` (the default), inferred by replacing the `.html` extension of
#'   `html_path` with `.qmd`.
#' @param output_dir A string or `NULL`. Directory where the `.xml` file
#'   will be written. If `NULL` (the default), written to the same directory
#'   as `html_path`.
#'
#' @return Invisibly returns the path to the written `.xml` file.
#'
#' @details
#' `generate_kb_xml()` performs the following steps:
#'
#' 1. Validates that `html_path` exists.
#' 2. Infers `qmd_path` from `html_path` if not supplied, then validates it.
#' 3. Extracts `title`, `description`, and `categories` from the `.qmd` YAML
#'    header and maps them to `kb_title`, `kb_summary`, and `kb_keywords`.
#' 4. Re-renders the `.qmd` in an isolated temporary directory with
#'    `embed-resources: true` so all CSS, images, and JS are self-contained.
#'    The `data/` and `assets/` folders are copied alongside the `.qmd` to
#'    ensure the render succeeds.
#' 5. Extracts the `<body>` from the embedded HTML.
#' 6. Escapes HTML entities in the body for XML compatibility, as required
#'    by the UW-Madison KB import format.
#' 7. Builds the XML structure with `kb_title`, `kb_keywords`, `kb_summary`,
#'    and `kb_body` nodes.
#' 8. Writes the `.xml` file to `output_dir`.
#'
#' Temporary files are managed via `withr::local_tempdir()` and are
#' automatically cleaned up when the function exits, even on error.
#'
#' When importing the resulting XML into the KB, check the
#' \emph{Decode HTML entity in body content} option.
#'
#' @export
#'
#' @examples
#' \donttest{
#' # Infer qmd_path automatically, write XML alongside the HTML
#' # generate_kb_xml(html_path = "docs/analysis.html")
#'
#' # Supply qmd_path explicitly and write to a specific output directory
#' # generate_kb_xml(
#' #   html_path  = "docs/analysis.html",
#' #   qmd_path   = "analysis.qmd",
#' #   output_dir = "exports"
#' # )
#' }
generate_kb_xml <- function(
        html_path,
        qmd_path = NULL,
        output_dir = NULL) {

    # -- 1. Validate html_path --------------------------------------------------
    if (!fs::file_exists(html_path)) {
        cli::cli_abort("HTML file {.path {html_path}} does not exist.")
    }

    # -- 2. Infer qmd_path if not provided --------------------------------------
    if (is.null(qmd_path)) {
        qmd_path <- fs::path_ext_set(html_path, "qmd")
    }

    if (!fs::file_exists(qmd_path)) {
        cli::cli_abort(
            "Could not find {.path {qmd_path}}.
       Supply the correct path via {.arg qmd_path}."
        )
    }

    # -- 3. Extract metadata from .qmd YAML -------------------------------------
    meta        <- .extract_qmd_metadata(qmd_path)
    kb_title    <- meta$kb_title
    kb_summary  <- meta$kb_summary
    kb_keywords <- meta$kb_keywords

    # -- 4. Re-render .qmd in isolated temp dir with embed-resources: true ------
    cli::cli_alert_info("Re-rendering {.path {qmd_path}} with embedded resources...")

    # withr::local_tempdir() creates an isolated temp directory that is
    # automatically deleted when the function exits, even on error
    temp_dir  <- withr::local_tempdir()
    temp_qmd  <- fs::path(temp_dir, fs::path_file(qmd_path))
    temp_html <- fs::path_ext_set(temp_qmd, "html")

    fs::file_copy(qmd_path, temp_qmd, overwrite = TRUE)

    data_src <- fs::path(fs::path_dir(qmd_path), "data")
    data_dst <- fs::path(temp_dir, "data")
    if (fs::dir_exists(data_src)) {
        fs::dir_copy(data_src, data_dst, overwrite = TRUE)
    }

    assets_src <- fs::path(fs::path_dir(qmd_path), "assets")
    assets_dst <- fs::path(temp_dir, "assets")
    if (fs::dir_exists(assets_src)) {
        fs::dir_copy(assets_src, assets_dst, overwrite = TRUE)
    }

    quarto::quarto_render(
        input       = temp_qmd,
        quarto_args = c("--embed-resources", "--standalone")
    )

    # -- 5. Extract body from embedded HTML -------------------------------------
    html_doc <- rvest::read_html(temp_html)
    kb_body  <- html_doc |>
        rvest::html_element("body") |>
        as.character()

    # -- 6. Escape HTML entities for XML compatibility --------------------------
    kb_body_escaped <- gsub("<", "&lt;", kb_body, fixed = TRUE)
    kb_body_escaped <- gsub(">", "&gt;", kb_body_escaped, fixed = TRUE)

    # -- 7. Build XML structure -------------------------------------------------
    root   <- xml2::xml_new_root("kb_documents")
    kb_doc <- xml2::xml_add_child(root, "kb_document")

    xml2::xml_add_child(kb_doc, "kb_title",    kb_title)
    xml2::xml_add_child(kb_doc, "kb_keywords", kb_keywords)
    xml2::xml_add_child(kb_doc, "kb_summary",  kb_summary)
    xml2::xml_add_child(kb_doc, "kb_body",     kb_body_escaped)

    # -- 8. Determine output path -----------------------------------------------
    if (is.null(output_dir)) {
        output_dir <- fs::path_dir(html_path)
    }

    fs::dir_create(output_dir)

    output_path <- fs::path(
        output_dir,
        paste0(fs::path_ext_remove(fs::path_file(html_path)), ".xml")
    )

    # -- 9. Write XML -----------------------------------------------------------
    xml2::write_xml(root, output_path)

    cli::cli_alert_success("KB XML written to {.path {output_path}}")
    cli::cli_alert_info(
        "When importing into the KB, check {.emph 'Decode HTML entity in body content'}."
    )

    invisible(output_path)
}


# -- Helper: extract metadata from .qmd YAML header --------------------------

.extract_qmd_metadata <- function(qmd_path) {
    raw_lines  <- readLines(qmd_path, warn = FALSE)
    yaml_end   <- which(raw_lines == "---")[2]
    yaml_block <- paste(raw_lines[2:(yaml_end - 1)], collapse = "\n")
    qmd_yaml   <- yaml::yaml.load(yaml_block)

    list(
        kb_title    = qmd_yaml$title       %||% "",
        kb_summary  = qmd_yaml$description %||% "",
        kb_keywords = if (!is.null(qmd_yaml$categories)) {
            paste(qmd_yaml$categories, collapse = ", ")
        } else {
            ""
        }
    )
}
