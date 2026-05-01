# R/arborize.R


# .build_arborize_qmd() -------------------------------------------------

#' Build a throwaway Quarto document for syntactic tree rendering
#'
#' Constructs the content of a minimal `.qmd` file that imports the
#' specified Typst tree package and renders one syntactic tree. Separating
#' this builder from `arborize()` makes the QMD content testable without
#' requiring a Quarto installation.
#'
#' @param tree A character string. The syntactic tree in bracket notation.
#' @param typst_package A character string. The Typst package import string.
#' @param papersize A character string. Typst paper size.
#' @param margin A character string. Page margin.
#'
#' @return A character string containing the complete `.qmd` file content.
#'
#' @keywords internal
.build_arborize_qmd <- function(tree,
                                typst_package = "@preview/syntree:0.2.0",
                                papersize     = "a5",
                                margin        = "0.5cm") {
    sprintf(
        paste0(
            "---\n",
            "format:\n",
            "  typst:\n",
            "    papersize: %s\n",
            "    margin:\n",
            "      x: %s\n",
            "      y: %s\n",
            "---\n\n",
            "```{=typst}\n",
            "#import \"%s\": syntree\n\n",
            "#syntree(\"%s\")\n",
            "```\n"
        ),
        papersize,
        margin,
        margin,
        typst_package,
        gsub('"', '\\\\"', tree, fixed = TRUE)
    )
}


# arborize() ------------------------------------------------------------

#' Render a syntactic tree as a PNG image
#'
#' Takes a syntactic tree in bracket notation, renders it using Quarto's
#' Typst engine and the `syntree` Typst package, and exports the result as
#' a PNG image. The function is useful for producing standalone tree figures
#' that can be embedded in any document format -- LaTeX, Word, HTML, or
#' presentations -- without requiring a full LaTeX installation.
#'
#' @param tree A character string. The syntactic tree in bracket notation,
#'   e.g. `"[S [NP [Det the] [N cat]] [VP [V sat]]]"`.
#' @param output A character string. Path to the output PNG file. Defaults
#'   to `"syntree.png"` in the current working directory.
#' @param dpi A numeric value. Resolution of the output PNG in dots per inch.
#'   Defaults to `300`. Use `600` for print-quality output.
#' @param typst_package A character string. The Typst package to use for
#'   tree rendering. Defaults to `"@preview/syntree:0.2.0"`. Change this
#'   if a newer version is available or a different package is preferred.
#' @param papersize A character string. Typst paper size for the intermediate
#'   PDF. Defaults to `"a5"`. Increase to `"a4"` for very wide trees.
#' @param margin A character string. Page margin for the intermediate PDF.
#'   Defaults to `"0.5cm"`. Reduce for tighter crops around the tree.
#' @param overwrite A logical. Whether to overwrite an existing output file.
#'   Defaults to `FALSE`.
#'
#' @return Invisibly returns the path to the output PNG file.
#'
#' @details
#' `arborize()` performs the following steps:
#'
#' 1. Validates inputs.
#' 2. Builds a minimal `.qmd` document via `.build_arborize_qmd()`.
#' 3. Writes the document and renders it inside a self-cleaning temporary
#'    directory managed by `withr::with_tempdir()`.
#' 4. Calls `quarto::quarto_render()` to produce an intermediate PDF via
#'    Typst.
#' 5. Converts the PDF to PNG using `pdftools::pdf_convert()`.
#' 6. Reads the PNG bytes into memory before the temporary directory is
#'    deleted, then writes them to the specified output path.
#'
#' The bracket notation follows the convention used by the `syntree` Typst
#' package: nodes are enclosed in square brackets, the first element of
#' each bracket is the node label, and subsequent elements are daughter
#' nodes. Leaf nodes are written without brackets.
#'
#' Requires Quarto 1.4 or later with Typst support, and the `pdftools`
#' package for PDF-to-PNG conversion. Install `pdftools` with
#' `install.packages("pdftools")`.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Simple NP tree
#' arborize("[NP [Det the] [N cat]]")
#'
#' # Aspectual classes tree with print-quality output
#' arborize(
#'   paste0(
#'     "[Aspectual Classes ",
#'     "[Statives [States]] ",
#'     "[Dynamic ",
#'     "[Atelic [Activities]] ",
#'     "[Telic ",
#'     "[Instantaneous [Achievements]] ",
#'     "[Durative [Accomplishments]]]]]"
#'   ),
#'   output    = "aspectual-classes.png",
#'   dpi       = 600,
#'   papersize = "a4"
#' )
#'
#' # Save to a specific location
#' arborize(
#'   "[S [NP] [VP [V ran]]]",
#'   output = "~/Documents/my-paper/figures/tree-01.png"
#' )
#' }
arborize <- function(tree,
                     output        = "syntree.png",
                     dpi           = 300,
                     typst_package = "@preview/syntree:0.2.1",
                     papersize     = "a5",
                     margin        = "0.5cm",
                     overwrite     = FALSE) {

    # -- 0. Validate inputs -----------------------------------------------------
    # -- 0. Validate inputs -----------------------------------------------------
    if (!is.character(tree) || length(tree) != 1L ||
        is.na(tree) || !nzchar(tree)) {
        cli::cli_abort("{.arg tree} must be a non-empty character string.")
    }

    output <- fs::path_abs(output)

    if (fs::file_exists(output) && !overwrite) {
        cli::cli_abort(
            "{.path {output}} already exists.
       Use {.code overwrite = TRUE} to replace it."
        )
    }

    if (!requireNamespace("pdftools", quietly = TRUE)) {
        cli::cli_abort(
            "The {.pkg pdftools} package is required for PDF-to-PNG conversion.
       Install it with {.code install.packages('pdftools')}."
        )
    }

    # -- 1. Build the throwaway .qmd content ------------------------------------
    qmd_content <- .build_arborize_qmd(
        tree          = tree,
        typst_package = typst_package,
        papersize     = papersize,
        margin        = margin
    )

    # -- 2. Write, render, and convert inside a self-cleaning temp directory ----
    fs::dir_create(fs::path_dir(output))

    png_bytes <- withr::with_tempdir({

        qmd_path <- "arborize.qmd"
        pdf_path <- "arborize.pdf"
        png_path <- "arborize.png"

        readr::write_file(qmd_content, qmd_path)

        cli::cli_alert_info("Rendering tree with Quarto + Typst ...")

        quarto::quarto_render(
            input         = qmd_path,
            output_format = "typst",
            output_file   = pdf_path,
            quiet         = TRUE
        )

        if (!fs::file_exists(pdf_path)) {
            cli::cli_abort(
                "Quarto rendering completed but no PDF was produced.
         Check that Quarto 1.4+ with Typst support is installed."
            )
        }

        cli::cli_alert_info("Converting PDF to PNG at {dpi} dpi ...")

        suppressWarnings(
            pdftools::pdf_convert(
                pdf       = pdf_path,
                format    = "png",
                dpi       = dpi,
                filenames = png_path,
                verbose   = FALSE
            )
        )

        # Read PNG bytes into memory before the temp directory is deleted
        readBin(png_path, "raw", file.info(png_path)$size)
    })

    # -- 3. Write PNG to final output path --------------------------------------
    writeBin(png_bytes, as.character(output))

    cli::cli_alert_success("Tree rendered to {.path {output}}")

    invisible(output)
}
