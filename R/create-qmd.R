#' Create a new Quarto document from a template
#'
#' Creates a new Quarto document in the specified directory. Optionally
#' copies a sample dataset and a worked analysis example, wires up custom
#' branding assets from a directory of standardized files, and scaffolds a
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
#'   to `FALSE`. Note the one exception: `assets/logo.png` is never
#'   overwritten, since an existing logo is assumed to be deliberate
#'   branding rather than a stale copy of the placeholder.
#' @param use_purl Logical. If `TRUE` (the default), creates a `_quarto.yml`
#'   file with a post-render hook and a `purl.R` script inside `R/` that
#'   extracts R code from the rendered document into a `.R` file. The target
#'   document is resolved dynamically by scanning the project root for `.qmd`
#'   files, so the same `purl.R` works regardless of the document name.
#' @param include_examples Logical. If `TRUE` (the default), copies a sample
#'   dataset (`sample.csv`) into `data-raw/`, a placeholder logo
#'   (`generic-logo.png`, copied as `logo.png`) into `assets/`, and uses a
#'   template `.qmd` pre-populated with a worked analysis example. If
#'   `assets/logo.png` already exists (e.g. from a prior [init_project()]
#'   call with `branding` set), it is always left untouched -- an existing
#'   logo takes precedence over the generic placeholder even when
#'   `overwrite = TRUE`. The YAML header includes a `params` block
#'   referencing the sample data. If `FALSE`, creates a blank `.qmd` with
#'   only the YAML header and no example content, and skips copying the
#'   sample dataset and logo.
#' @param use_style Logical or character. Controls whether custom branding
#'   assets are wired into the YAML.
#'   - `FALSE` (the default): no custom styling. The YAML `format: html:`
#'     block contains only standard Quarto options.
#'   - `TRUE`: shorthand for `"assets/"`. Looks in `path/assets/` for
#'     `styles.css`, `header.html`, and `footer.html` by name, and wires
#'     up whichever of these are present.
#'   - A directory path (e.g. `"my-branding/"`): looks in the given
#'     directory for the same three standardized filenames. The caller is
#'     responsible for ensuring the directory contains the files it needs
#'     under these exact names; `create_qmd()` does not rename or infer
#'     from other file names.
#'
#'   `styles.css` is added as `css:`, `header.html` as
#'   `include-before-body:`, and `footer.html` as `include-after-body:`.
#'   Any subset may be present; only files that exist are wired into the
#'   YAML. If none of the three are found, a warning is issued and style
#'   injection is skipped. Note that `favicon.png`, though shipped with
#'   the branding asset set, is not wired into the document YAML --
#'   favicons are a Quarto website-project option rather than an HTML
#'   format option, so set it in `_quarto.yml` if you need one.
#'
#' @return Invisibly returns `path`.
#'
#' @details
#' `create_qmd()` performs the following steps:
#'
#' 1. Validates that `filename` is supplied and `path` exists.
#' 2. If `include_examples = TRUE`: creates `data-raw/` under `path` and
#'    copies `sample.csv` there. Creates `assets/` if needed and copies
#'    the generic placeholder logo as `logo.png`, unless a logo already
#'    exists there. Uses the example template for the `.qmd`.
#' 3. If `include_examples = FALSE`: uses the skeleton template for the
#'    `.qmd`. No sample data or logo is copied.
#' 4. If `use_style` is `TRUE` or a directory path: looks for
#'    `styles.css`, `header.html`, and `footer.html` by name and injects
#'    whichever are present into the YAML header.
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
#' # Blank document wired to branding assets (assumes assets/ exists,
#' # e.g. from init_project(branding = "uw-madison"))
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

    if (fs::path_ext(filename) != "qmd") {
        filename <- fs::path_ext_set(filename, "qmd")
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

        # assets/ with placeholder logo.png -- deliberately exempt from
        # overwrite. An existing logo (e.g. from init_project(branding = ))
        # is assumed to be intentional branding, and silently replacing it
        # with the generic placeholder would be surprising.
        assets_dir <- fs::path(path, "assets")
        fs::dir_create(assets_dir)

        logo_src <- system.file(
            "assets", "generic-logo.png",
            package = "toolero",
            mustWork = TRUE
        )
        logo_dst <- fs::path(assets_dir, "logo.png")

        if (!fs::file_exists(logo_dst)) {
            fs::file_copy(logo_src, logo_dst)
            cli::cli_alert_success("Created {.path {logo_dst}}")
        } else {
            cli::cli_alert_info(
                "Skipping {.path {logo_dst}} -- existing logo left in place."
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

        # Absolutize so path_rel() below has comparable arguments even when
        # use_style is relative and path is absolute (or vice versa).
        style_dir <- fs::path_abs(style_dir)

        # Validate directory exists
        if (!fs::dir_exists(style_dir)) {
            cli::cli_warn(
                "Style directory {.path {style_dir}} does not exist.
         Skipping style injection. Create the directory and add your
         branding assets, or set {.code use_style = FALSE}."
            )
        } else {

            # Look for each standardized file by name -- both the TRUE
            # shorthand and a custom directory are expected to follow the
            # same naming convention (styles.css, header.html,
            # footer.html). Custom directories are the user's
            # responsibility to populate correctly; create_qmd() does not
            # rename or infer from other file names.
            css_file    <- fs::path(style_dir, "styles.css")
            header_file <- fs::path(style_dir, "header.html")
            footer_file <- fs::path(style_dir, "footer.html")

            has_css    <- fs::file_exists(css_file)
            has_header <- fs::file_exists(header_file)
            has_footer <- fs::file_exists(footer_file)

            if (!has_css && !has_header && !has_footer) {
                cli::cli_warn(
                    "No {.file styles.css}, {.file header.html}, or
             {.file footer.html} found in {.path {style_dir}}.
             Skipping style injection."
                )
            } else {
                qmd_content <- .inject_style_yaml(
                    qmd_content,
                    css_file    = if (has_css)    .relative_style_path(css_file, path),
                    header_file = if (has_header) .relative_style_path(header_file, path),
                    footer_file = if (has_footer) .relative_style_path(footer_file, path)
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
    fs::path_rel(abs_path, start = fs::path_abs(project_root))
}


# -- Helper: inject css and header/footer includes into YAML -----------------

.inject_style_yaml <- function(qmd_content,
                               css_file = NULL,
                               header_file = NULL,
                               footer_file = NULL) {

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

    # header.html holds visible banner markup, so it belongs before the
    # body -- include-in-header would place it inside <head>.
    if (!is.null(header_file)) {
        template_yaml[["format"]][["html"]][["include-before-body"]] <-
            as.character(header_file)
    }

    if (!is.null(footer_file)) {
        template_yaml[["format"]][["html"]][["include-after-body"]] <-
            as.character(footer_file)
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
