#' Create a new Quarto document from a template
#'
#' Creates a new Quarto document in the specified directory. Optionally
#' copies a sample dataset and a worked analysis example, wires up custom
#' CSS and header styling from a directory of assets, and scaffolds a
#' post-render purl hook for extracting R code.
#'
#' @param filename A string or `NULL`. Name of the generated `.qmd` file.
#'   Must be supplied explicitly, e.g. `"analysis.qmd"`.
#' @param path A string. Path to the directory where the document will be
#'   created. Defaults to `"."` (the current working directory).
#' @param yaml_data A string or `NULL`. Path to a YAML file containing
#'   metadata to pre-populate the document header. If `NULL` (the default),
#'   the template is copied as-is with placeholder prompts intact.
#' @param overwrite A logical. Whether to overwrite existing files. Defaults
#'   to `FALSE`.
#' @param use_purl Logical. If `TRUE` (the default), creates a `_quarto.yml`
#'   file with a post-render hook and a `purl.R` script inside `R/` that
#'   extracts R code from the rendered document into a `.R` file. The target
#'   document is resolved dynamically by scanning the project root for `.qmd`
#'   files, so the same `purl.R` works regardless of the document name.
#' @param include_examples Logical. If `TRUE` (the default), copies a sample
#'   dataset (`sample.csv`) into `data-raw/`, a placeholder logo (`logo.png`)
#'   into `assets/`, and uses a template `.qmd` pre-populated with a worked
#'   analysis example. The YAML header includes a `params` block referencing
#'   the sample data. If `FALSE`, creates a blank `.qmd` with only the YAML
#'   header and no example content, and skips copying the sample dataset and
#'   logo.
#' @param use_style Logical or character. Controls whether custom CSS and
#'   header assets are wired into the YAML.
#'   - `FALSE` (the default): no custom styling. The YAML `format: html:`
#'     block contains only standard Quarto options.
#'   - `TRUE`: shorthand for `"assets/"`. Scans `path/assets/` for `.css`
#'     and `.html` files and adds them to the YAML.
#'   - A directory path (e.g. `"my-branding/"`): scans the given directory
#'     for `.css` and `.html` files and adds them to the YAML.
#'
#'   If the directory contains exactly one `.css` file, it is added as
#'   `css:` in the YAML. If exactly one `.html` file is found, it is added
#'   as `include-before-body:`. If multiple `.css` or `.html` files are
#'   found, the function errors and asks the user to specify which file
#'   to use via `yaml_data`. If neither is found, a warning is issued.
#'
#' @return Invisibly returns `path`.
#'
#' @details
#' `create_qmd()` performs the following steps:
#'
#' 1. Validates that `filename` is supplied and `path` exists.
#' 2. If `include_examples = TRUE`: creates `data-raw/` under `path` and
#'    copies `sample.csv` there. Creates `assets/` if needed and copies a
#'    placeholder `logo.png`. Uses the example template for the `.qmd`.
#' 3. If `include_examples = FALSE`: uses the skeleton template for the
#'    `.qmd`. No sample data or logo is copied.
#' 4. If `use_style` is `TRUE` or a directory path: scans the directory for
#'    `.css` and `.html` files and injects them into the YAML header.
#' 5. If `yaml_data` is provided, reads the YAML file and substitutes values
#'    into the document header. This runs after style injection, so
#'    `yaml_data` can override any auto-generated YAML keys.
#' 6. If `use_purl = TRUE`, writes `_quarto.yml` with a post-render hook
#'    and copies `purl.R` into `path/R/`.
#' 7. The sample dataset bundled with the template is a subset of the Palmer
#'    Penguins dataset. Citation: Horst AM, Hill AP, Gorman KB (2020).
#'    palmerpenguins: Palmer Archipelago (Antarctica) Penguin Data. R package
#'    version 0.1.0. \doi{10.5281/zenodo.3960218}
#'
#' Note: `filename` has no default value and must always be supplied
#' explicitly. Use `tempdir()` for temporary output during testing or
#' exploration.
#'
#' @export
#'
#' @examples
#' \donttest{
#' # Minimal blank document -- no examples, no styling
#' create_qmd(path = tempdir(), filename = "analysis.qmd",
#'            include_examples = FALSE)
#'
#' # Full worked example with sample data and placeholder logo
#' create_qmd(path = tempdir(), filename = "analysis.qmd",
#'            overwrite = TRUE)
#'
#' # Blank document wired to UW branding assets (assumes assets/ exists)
#' create_qmd(path = tempdir(), filename = "report.qmd",
#'            include_examples = FALSE, use_style = TRUE,
#'            overwrite = TRUE)
#'
#' # Blank document with custom branding from a different directory
#' create_qmd(path = tempdir(), filename = "report.qmd",
#'            include_examples = FALSE, use_style = "my-branding/",
#'            overwrite = TRUE, use_purl = FALSE)
#'
#' # Pre-populated YAML overrides
#' yaml_file <- tempfile(fileext = ".yml")
#' writeLines("author:\n  - name: 'Your Name'", yaml_file)
#' create_qmd(path = tempdir(), filename = "analysis.qmd",
#'            yaml_data = yaml_file, overwrite = TRUE)
#' }
create_qmd <- function(
        filename = NULL,
        path = ".",
        yaml_data = NULL,
        overwrite = FALSE,
        use_purl = TRUE,
        include_examples = TRUE,
        use_style = FALSE) {

    # -- 1. Validate filename ---------------------------------------------------
    if (is.null(filename)) {
        cli::cli_abort(
            "{.arg filename} must be supplied, e.g. {.code filename = \"analysis.qmd\"}."
        )
    }

    # -- 2. Validate path exists ------------------------------------------------
    if (!fs::dir_exists(path)) {
        cli::cli_abort(
            "Directory {.path {path}} does not exist.
       Create it first or choose an existing path."
        )
    }

    # -- 3. Copy sample data and placeholder logo if include_examples = TRUE ----
    if (include_examples) {

        # data-raw/ with sample.csv
        data_dir <- fs::path(path, "data-raw")
        fs::dir_create(data_dir)

        sample_src <- system.file(
            "templates", "sample.csv",
            package = "toolero",
            mustWork = TRUE
        )
        sample_dst <- fs::path(data_dir, "sample.csv")

        if (!fs::file_exists(sample_dst) || overwrite) {
            fs::file_copy(sample_src, sample_dst, overwrite = overwrite)
            cli::cli_alert_success("Created {.path {sample_dst}}")
        } else {
            cli::cli_alert_info(
                "Skipping {.path {sample_dst}} -- already exists."
            )
        }

        # assets/ with placeholder logo.png
        assets_dir <- fs::path(path, "assets")
        fs::dir_create(assets_dir)

        logo_src <- system.file(
            "templates", "logo.png",
            package = "toolero",
            mustWork = TRUE
        )
        logo_dst <- fs::path(assets_dir, "logo.png")

        if (!fs::file_exists(logo_dst) || overwrite) {
            fs::file_copy(logo_src, logo_dst, overwrite = overwrite)
            cli::cli_alert_success("Created {.path {logo_dst}}")
        } else {
            cli::cli_alert_info(
                "Skipping {.path {logo_dst}} -- already exists."
            )
        }
    }

    # -- 4. Choose and read the template ----------------------------------------
    if (include_examples) {
        template_name <- "example.qmd"
    } else {
        template_name <- "skeleton.qmd"
    }

    qmd_src <- system.file(
        "templates", template_name,
        package = "toolero",
        mustWork = TRUE
    )
    qmd_dst <- fs::path(path, filename)

    if (fs::file_exists(qmd_dst) && !overwrite) {
        cli::cli_abort(
            "{.path {qmd_dst}} already exists.
       Use {.code overwrite = TRUE} to replace it."
        )
    }

    qmd_content <- readr::read_file(qmd_src)

    # -- 5. Inject style assets into YAML if use_style is set -------------------
    if (!isFALSE(use_style)) {

        # Resolve the style directory
        if (isTRUE(use_style)) {
            style_dir <- fs::path(path, "assets")
        } else if (is.character(use_style)) {
            style_dir <- use_style
        } else {
            cli::cli_abort(
                "{.arg use_style} must be {.code FALSE}, {.code TRUE}, or a
         directory path."
            )
        }

        # Validate directory exists
        if (!fs::dir_exists(style_dir)) {
            cli::cli_warn(
                "Style directory {.path {style_dir}} does not exist.
         Skipping style injection. Create the directory and add your
         {.file .css} and/or {.file .html} assets, or set
         {.code use_style = FALSE}."
            )
        } else {

            # Scan for .css files
            css_files <- fs::dir_ls(style_dir, glob = "*.css")
            if (length(css_files) > 1) {
                cli::cli_abort(c(
                    "Found {length(css_files)} {.file .css} files in
             {.path {style_dir}}:",
                    paste0("- ", fs::path_file(css_files)),
                    "i" = "Specify which one to use via {.arg yaml_data}."
                ))
            }

            # Scan for .html files
            html_files <- fs::dir_ls(style_dir, glob = "*.html")
            if (length(html_files) > 1) {
                cli::cli_abort(c(
                    "Found {length(html_files)} {.file .html} files in
             {.path {style_dir}}:",
                    paste0("- ", fs::path_file(html_files)),
                    "i" = "Specify which one to use via {.arg yaml_data}."
                ))
            }

            # Warn if directory is empty of relevant files
            if (length(css_files) == 0 && length(html_files) == 0) {
                cli::cli_warn(
                    "No {.file .css} or {.file .html} files found in
             {.path {style_dir}}. Skipping style injection."
                )
            }

            # Inject into YAML
            if (length(css_files) == 1 || length(html_files) == 1) {
                qmd_content <- .inject_style_yaml(
                    qmd_content,
                    css_file = if (length(css_files) == 1) {
                        .relative_style_path(css_files, path)
                    },
                    html_file = if (length(html_files) == 1) {
                        .relative_style_path(html_files, path)
                    }
                )
            }
        }
    }

    # -- 6. Substitute YAML if yaml_data is provided ----------------------------
    if (!is.null(yaml_data)) {
        if (!fs::file_exists(yaml_data)) {
            cli::cli_abort(
                "yaml_data file {.path {yaml_data}} does not exist."
            )
        }

        user_yaml <- yaml::read_yaml(yaml_data)
        qmd_content <- .substitute_yaml(qmd_content, user_yaml)
    }

    readr::write_file(qmd_content, qmd_dst)
    cli::cli_alert_success("Created {.path {qmd_dst}}")

    # -- 7. Scaffold _quarto.yml and R/purl.R if use_purl = TRUE ----------------
    if (use_purl) {

        # _quarto.yml at project root, copied from inst/templates
        quarto_yml_src <- system.file(
            "templates", "_quarto.yml",
            package = "toolero",
            mustWork = TRUE
        )
        quarto_yml_dst <- fs::path(path, "_quarto.yml")
        if (!fs::file_exists(quarto_yml_dst) || overwrite) {
            fs::file_copy(quarto_yml_src, quarto_yml_dst, overwrite = overwrite)
            cli::cli_alert_success("Created {.path {quarto_yml_dst}}")
        } else {
            cli::cli_alert_info(
                "Skipping {.path {quarto_yml_dst}} -- already exists."
            )
        }

        # purl.R goes into R/, not the project root
        purl_src <- system.file(
            "templates", "purl.R",
            package = "toolero",
            mustWork = TRUE
        )
        fs::dir_create(fs::path(path, "R"))
        purl_dst <- fs::path(path, "R", "purl.R")
        if (!fs::file_exists(purl_dst) || overwrite) {
            fs::file_copy(purl_src, purl_dst, overwrite = overwrite)
            cli::cli_alert_success("Created {.path {purl_dst}}")
        } else {
            cli::cli_alert_info(
                "Skipping {.path {purl_dst}} -- already exists."
            )
        }
    }

    invisible(path)
}


# -- Helper: compute relative path from project root to style asset ----------

.relative_style_path <- function(abs_path, project_root) {
    fs::path_rel(abs_path, start = project_root)
}


# -- Helper: inject css and/or include-before-body into YAML -----------------

.inject_style_yaml <- function(qmd_content, css_file = NULL, html_file = NULL) {

    # Normalize line endings
    qmd_content <- gsub("\r\n", "\n", qmd_content, fixed = TRUE)

    yaml_pattern <- "(?s)^---\\n(.+?)\\n---"
    yaml_match <- regmatches(
        qmd_content,
        regexpr(yaml_pattern, qmd_content, perl = TRUE)
    )

    if (length(yaml_match) == 0) {
        cli::cli_warn(
            "No YAML header found in template. Skipping style injection."
        )
        return(qmd_content)
    }

    template_yaml <- yaml::yaml.load(yaml_match)

    # Ensure format$html exists
    if (is.null(template_yaml[["format"]])) {
        template_yaml[["format"]] <- list()
    }
    if (is.null(template_yaml[["format"]][["html"]])) {
        template_yaml[["format"]][["html"]] <- list()
    }

    if (!is.null(css_file)) {
        template_yaml[["format"]][["html"]][["css"]] <- as.character(css_file)
    }

    if (!is.null(html_file)) {
        template_yaml[["format"]][["html"]][["include-before-body"]] <-
            as.character(html_file)
    }

    merged_yaml_str <- yaml::as.yaml(
        template_yaml,
        handlers = list(
            logical = function(x) {
                structure(ifelse(x, "true", "false"), class = "verbatim")
            }
        )
    )
    new_header <- paste0("---\n", merged_yaml_str, "---")

    sub(yaml_pattern, new_header, qmd_content, perl = TRUE)
}


# -- Helper: substitute YAML values into template ----------------------------

.substitute_yaml <- function(qmd_content, user_yaml) {

    # Normalize line endings to \n regardless of platform
    qmd_content <- gsub("\r\n", "\n", qmd_content, fixed = TRUE)

    yaml_pattern <- "(?s)^---\\n(.+?)\\n---"
    yaml_match <- regmatches(
        qmd_content,
        regexpr(yaml_pattern, qmd_content, perl = TRUE)
    )

    if (length(yaml_match) == 0) {
        cli::cli_warn("No YAML header found in template. Skipping substitution.")
        return(qmd_content)
    }

    # Parse template YAML
    template_yaml <- yaml::yaml.load(yaml_match)

    # Directly overwrite keys present in user_yaml
    for (key in names(user_yaml)) {
        template_yaml[[key]] <- user_yaml[[key]]
    }

    # Serialize and reconstruct, forcing true/false instead of yes/no
    merged_yaml_str <- yaml::as.yaml(
        template_yaml,
        handlers = list(
            logical = function(x) {
                structure(ifelse(x, "true", "false"), class = "verbatim")
            }
        )
    )
    new_header <- paste0("---\n", merged_yaml_str, "---")

    sub(yaml_pattern, new_header, qmd_content, perl = TRUE)
}
