#' Create a new Quarto document from a template
#'
#' Creates a new Quarto document in the specified directory, along with a
#' sample dataset and UW-Madison branded assets. Optionally pre-populates
#' the YAML header with user-supplied metadata.
#'
#' @param path A string. Path to the directory where the document will be
#'   created. Defaults to `"."` (the current working directory).
#' @param filename A string or `NULL`. Name of the generated `.qmd` file.
#'   Must be supplied explicitly, e.g. `"analysis.qmd"`.
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
#'
#' @return Invisibly returns `path`.
#'
#' @details
#' `create_qmd()` performs the following steps:
#'
#' 1. Validates that `path` exists.
#' 2. Validates that `filename` is supplied.
#' 3. Creates a `data/` folder under `path` and copies `sample.csv` there.
#' 4. Checks for `assets/styles.css` and `assets/header.html` - creates the
#'    `assets/` folder if needed and copies both from the package.
#' 5. Copies the template `.qmd` to `path/filename`.
#' 6. If `yaml_data` is provided, reads the YAML file and substitutes values
#'    into the document header.
#' 7. If `use_purl = TRUE`, writes a `_quarto.yml` with a post-render hook
#'    pointing to `R/purl.R`, and copies `purl.R` from the package templates
#'    into `path/R/purl.R`.
#'
#' Note: `filename` has no default value and must always be supplied
#' explicitly. Use `tempdir()` for temporary output during testing or
#' exploration.
#'
#' @export
#'
#' @examples
#' \donttest{
#' # Create a document in a temp directory
#' create_qmd(path = tempdir(), filename = "analysis.qmd")
#'
#' # Create with a custom filename, without the purl hook
#' create_qmd(path = tempdir(), filename = "report.qmd",
#'             overwrite = TRUE, use_purl = FALSE)
#'
#' # Create with pre-populated YAML
#' yaml_file <- tempfile(fileext = ".yml")
#' writeLines("author:\n  - name: 'Your Name'", yaml_file)
#' create_qmd(path = tempdir(), filename = "analysis.qmd",
#'             yaml_data = yaml_file, overwrite = TRUE)
#' }
create_qmd <- function(
        path = ".",
        filename = NULL,
        yaml_data = NULL,
        overwrite = FALSE,
        use_purl = TRUE) {

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

    # -- 3. Create data/ and copy sample.csv ------------------------------------
    data_dir <- fs::path(path, "data")
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
        cli::cli_alert_info("Skipping {.path {sample_dst}} - already exists.")
    }

    # -- 4. Create assets/ and copy styles.css and header.html -----------------
    assets_dir <- fs::path(path, "assets")
    fs::dir_create(assets_dir)

    assets <- c("styles.css", "header.html")

    for (asset in assets) {
        asset_src <- system.file(
            "assets", asset,
            package = "toolero",
            mustWork = TRUE
        )
        asset_dst <- fs::path(assets_dir, asset)

        if (!fs::file_exists(asset_dst) || overwrite) {
            fs::file_copy(asset_src, asset_dst, overwrite = overwrite)
            cli::cli_alert_success("Created {.path {asset_dst}}")
        } else {
            cli::cli_alert_info("Skipping {.path {asset_dst}} - already exists.")
        }
    }

    # -- 5. Copy template .qmd --------------------------------------------------
    qmd_src <- system.file(
        "templates", "example.qmd",
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

    # -- 6. Substitute YAML if yaml_data is provided ----------------------------
    if (!is.null(yaml_data)) {
        if (!fs::file_exists(yaml_data)) {
            cli::cli_abort(
                "yaml_data file {.path {yaml_data}} does not exist."
            )
        }

        user_yaml <- yaml::read_yaml(yaml_data)
        qmd_content <- substitute_yaml(qmd_content, user_yaml)
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
            cli::cli_alert_info("Skipping {.path {quarto_yml_dst}} - already exists.")
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
            cli::cli_alert_info("Skipping {.path {purl_dst}} - already exists.")
        }
    }

    invisible(path)
}


# -- Helper: substitute YAML values into template ----------------------------

substitute_yaml <- function(qmd_content, user_yaml) {

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
        handlers = list(logical = function(x) ifelse(x, "true", "false"))
    )
    new_header <- paste0("---\n", merged_yaml_str, "---")

    sub(yaml_pattern, new_header, qmd_content, perl = TRUE)
}
