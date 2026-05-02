# R/arborize.R


# .build_arborize_qmd() -------------------------------------------------

#' Build a throwaway Quarto document for syntactic tree rendering
#'
#' Constructs the content of a minimal `.qmd` file that imports the
#' appropriate Typst tree package and renders one syntactic tree. The
#' generated Typst block differs depending on `tree_notation`:
#'
#' - `"simple"` uses `@preview/syntree` and bracket notation
#' - `"structured"` uses `@preview/lingotree` and nested `tree()` calls
#'
#' Separating this builder from `arborize()` makes the QMD content
#' testable without requiring a Quarto installation.
#'
#' @param tree A character string. The syntactic tree in the notation
#'   appropriate for `tree_notation`.
#' @param tree_notation A character string. One of `"simple"` or
#'   `"structured"`.
#' @param typst_package A character string. The resolved Typst package
#'   import string, derived internally from `tree_notation`.
#' @param papersize A character string. Typst paper size.
#' @param margin A character string. Page margin.
#'
#' @return A character string containing the complete `.qmd` file content.
#'
#' @keywords internal
.build_arborize_qmd <- function(tree,
                                tree_notation = c("simple", "structured"),
                                typst_package,
                                papersize     = "a5",
                                margin        = "0.5cm") {

    tree_notation <- match.arg(tree_notation)

    yaml_block <- sprintf(
        paste0(
            "---\n",
            "format:\n",
            "  typst:\n",
            "    papersize: %s\n",
            "    margin:\n",
            "      x: %s\n",
            "      y: %s\n",
            "---\n\n"
        ),
        papersize,
        margin,
        margin
    )

    typst_block <- if (tree_notation == "simple") {
        sprintf(
            paste0(
                "```{=typst}\n",
                "#import \"%s\": syntree\n\n",
                "#syntree(\"%s\")\n",
                "```\n"
            ),
            typst_package,
            gsub('"', '\\\\"', tree, fixed = TRUE)
        )
    } else {
        sprintf(
            paste0(
                "```{=typst}\n",
                "#import \"%s\": *\n\n",
                "#render(\n",
                "%s\n",
                ")\n",
                "```\n"
            ),
            typst_package,
            tree
        )
    }

    paste0(yaml_block, typst_block)
}


# .write_arborize_provenance() ------------------------------------------

#' Write a provenance YAML file alongside a rendered tree PNG
#'
#' Records the tree string and all rendering arguments that produced a
#' given PNG file. The provenance file has the same name as the PNG but
#' with a `.yaml` extension, and is written to the same directory.
#'
#' @param output A character string. Absolute path to the PNG output file.
#' @param tree A character string. The tree string passed to `arborize()`.
#' @param tree_notation A character string. One of `"simple"` or
#'   `"structured"`.
#' @param typst_package A character string. The resolved Typst package.
#' @param dpi A numeric value. DPI used for rendering.
#' @param papersize A character string. Typst paper size used.
#' @param margin A character string. Page margin used.
#'
#' @return Invisibly returns the path to the provenance file.
#'
#' @keywords internal
.write_arborize_provenance <- function(output,
                                       tree,
                                       tree_notation,
                                       typst_package,
                                       dpi,
                                       papersize,
                                       margin) {

    provenance_path <- fs::path_ext_set(output, "yaml")

    provenance <- list(
        rendered_by   = paste("toolero::arborize(), version",
                              utils::packageVersion("toolero")),
        rendered_at   = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
        output        = as.character(output),
        tree_notation = tree_notation,
        typst_package = typst_package,
        dpi           = dpi,
        papersize     = papersize,
        margin        = margin,
        tree          = tree
    )

    yaml::write_yaml(provenance, provenance_path)

    cli::cli_alert_success(
        "Provenance recorded at {.path {provenance_path}}"
    )

    invisible(provenance_path)
}


# arborize() ------------------------------------------------------------

#' Render a syntactic tree as a PNG image
#'
#' Takes a syntactic tree and renders it using Quarto's Typst engine,
#' exporting the result as a PNG image. Supports two rendering backends
#' controlled by `tree_notation`:
#'
#' - `"simple"` uses `@preview/syntree` and accepts a bracket notation
#'   string, e.g. `"[S [NP [Det the] [N cat]] [VP [V sat]]]"`. This is
#'   the most compact input format and suits basic linguistic trees.
#'
#' - `"structured"` uses `@preview/lingotree` and accepts a nested
#'   `tree()` call string. This backend supports per-node styling,
#'   movement arrows, and multi-dominant trees.
#'
#' The function is useful for producing standalone tree figures that can
#' be embedded in any document format -- LaTeX, Word, HTML, or
#' presentations -- without requiring a full LaTeX installation.
#'
#' @param tree A character string. For `tree_notation = "simple"`, a
#'   bracket notation string e.g. `"[S [NP] [VP]]"`. For
#'   `tree_notation = "structured"`, a lingotree `tree()` call string.
#' @param output A character string. Path to the output PNG file.
#'   Defaults to `"syntactic-tree.png"` in the current working directory.
#' @param dpi A numeric value. Resolution of the output PNG in dots per
#'   inch. Defaults to `300`. Use `600` for print-quality output.
#' @param tree_notation A character string. One of `"simple"` (default)
#'   or `"structured"`. Controls which Typst rendering backend is used.
#'   See Details.
#' @param papersize A character string. Typst paper size for the
#'   intermediate PDF. Defaults to `"a5"`. Increase to `"a4"` for very
#'   wide trees.
#' @param margin A character string. Page margin for the intermediate
#'   PDF. Defaults to `"0.5cm"`. Reduce for tighter crops around the
#'   tree.
#' @param provenance A logical. Whether to write a companion `.yaml` file
#'   recording the tree string and all rendering arguments alongside the
#'   PNG. Defaults to `TRUE`. The provenance file has the same name as
#'   the PNG but with a `.yaml` extension and lives in the same directory.
#'   Pass `FALSE` to suppress it.
#' @param overwrite A logical. Whether to overwrite existing output files.
#'   When `TRUE`, overwrites both the PNG and the provenance file if they
#'   exist. Defaults to `FALSE`.
#'
#' @return Invisibly returns the path to the output PNG file.
#'
#' @details
#' `arborize()` performs the following steps:
#'
#' 1. Validates inputs and resolves the Typst package from `tree_notation`.
#' 2. Builds a minimal `.qmd` document via `.build_arborize_qmd()`.
#' 3. Writes the document and renders it inside a self-cleaning temporary
#'    directory managed by `withr::with_tempdir()`.
#' 4. Calls `quarto::quarto_render()` to produce an intermediate PDF via
#'    Typst.
#' 5. Converts the PDF to PNG using `pdftools::pdf_convert()`.
#' 6. Reads the PNG bytes into memory before the temporary directory is
#'    deleted, then writes them to the specified output path.
#' 7. If `provenance = TRUE`, writes a companion `.yaml` file recording
#'    the tree string and all rendering arguments.
#'
#' On first use, Typst will download the required package from the Typst
#' package registry. This requires an internet connection. Subsequent
#' renders use the locally cached package.
#'
#' Requires Quarto 1.4 or later with Typst support, and the `pdftools`
#' package for PDF-to-PNG conversion. Install `pdftools` with
#' `install.packages("pdftools")`.
#'
#' @references
#' syntree Typst package (v0.2.1): \url{https://typst.app/universe/package/syntree}
#'
#' lingotree Typst package (v1.0.0): \url{https://typst.app/universe/package/lingotree}
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Simple bracket notation (default) -- also writes tree-1.yaml
#' arborize("[NP [Det the] [N cat]]", output = "my-trees/tree-1.png")
#'
#' # Suppress provenance file
#' arborize("[NP [Det the] [N cat]]", provenance = FALSE)
#'
#' # Wider tree with print-quality output
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
#' # Structured notation using lingotree
#' arborize(
#'   "tree(
#'     tag: [VP],
#'     tree(
#'       tag: [DP],
#'       [every],
#'       [farmer]
#'     ),
#'     [smiled]
#'   )",
#'   tree_notation = "structured",
#'   output        = "vp-tree.png"
#' )
#' }
arborize <- function(tree,
                     output        = "syntactic-tree.png",
                     dpi           = 300,
                     tree_notation = c("simple", "structured"),
                     papersize     = "a5",
                     margin        = "0.5cm",
                     provenance    = TRUE,
                     overwrite     = FALSE) {

    # -- 0. Validate inputs -----------------------------------------------------
    tree_notation <- match.arg(tree_notation)

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

    # -- 1. Resolve Typst package from tree_notation ----------------------------
    typst_package <- switch(tree_notation,
                            simple     = "@preview/syntree:0.2.1",
                            structured = "@preview/lingotree:1.0.0"
    )

    cli::cli_alert_info(
        "Using {.pkg {typst_package}} for rendering.
     On first use Typst will download this package -- requires internet access."
    )

    # -- 2. Build the throwaway .qmd content ------------------------------------
    qmd_content <- .build_arborize_qmd(
        tree          = tree,
        tree_notation = tree_notation,
        typst_package = typst_package,
        papersize     = papersize,
        margin        = margin
    )

    # -- 3. Write, render, and convert inside a self-cleaning temp directory ----
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

    # -- 4. Write PNG to final output path --------------------------------------
    writeBin(png_bytes, as.character(output))

    cli::cli_alert_success("Tree rendered to {.path {output}}")

    # -- 5. Write provenance file if requested ----------------------------------
    if (provenance) {
        .write_arborize_provenance(
            output        = output,
            tree          = tree,
            tree_notation = tree_notation,
            typst_package = typst_package,
            dpi           = dpi,
            papersize     = papersize,
            margin        = margin
        )
    }

    invisible(output)
}
