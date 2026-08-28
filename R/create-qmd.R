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
#'   to `FALSE`. Note two exceptions: `assets/logo.png` is never
#'   overwritten, since an existing logo is assumed to be deliberate
#'   branding rather than a stale copy of the placeholder; and
#'   `_quarto.yml` is never governed by `overwrite` at all -- when it
#'   is touched, it is merged rather than replaced, and in some cases
#'   (see `use_purl` below) it is left untouched entirely regardless of
#'   `overwrite`, on purpose.
#' @param use_purl Logical. Defaults to `FALSE`. When `TRUE`:
#'   - Stamps the document's own YAML header with `purl: true`.
#'   - Ensures `R/purl.R` exists in `path` (subject to `overwrite`, like
#'     any other scaffolded file).
#'   - Ensures `path/_quarto.yml` has a `project: post-render:` entry
#'     pointing at `R/purl.R` -- *unless* `_quarto.yml` already exists
#'     and declares `project: type:` as `website`, `book`, or
#'     `manuscript`, in which case the hook is deliberately **not**
#'     wired automatically. A `cli_warn()` explains why and shows the
#'     `project:` snippet needed to add it by hand. This guard exists
#'     because `R/purl.R` purls each document to a path mirroring its
#'     source location under `R/` -- safe within a single project, but
#'     the interesting failure mode it's protecting against is deciding
#'     *whether* to opt a multi-document project in at all, since a
#'     website or book renders many documents on every full build and
#'     the person scaffolding one `.qmd` may not be thinking about the
#'     other twenty. If `_quarto.yml` does not yet exist at all, the
#'     package template is copied in as usual (nothing to guard against
#'     yet -- a fresh `_quarto.yml` with no `type:` is not a multi-
#'     document project). Outside the guarded types, an existing
#'     `_quarto.yml` gets the hook merged into its existing `project:`
#'     block rather than overwritten, so `type`, `website`, and any
#'     other project options are left untouched. This merge (when it
#'     happens) is unaffected by `overwrite`, since appending one line
#'     to `post-render` is non-destructive.
#'
#'   When `use_purl = FALSE`, the document's header is still stamped,
#'   with `purl: false`, so `R/purl.R` (in a project where some other
#'   document has `use_purl = TRUE`) can positively confirm this document
#'   should be skipped rather than merely lacking an opinion.
#'
#'   `R/purl.R` itself only purls documents whose own header carries
#'   `purl: true`, so turning this on for one document inside a larger
#'   project -- a Quarto website, a book -- does not cause every other
#'   `.qmd` in that project to be purled whenever the project renders in
#'   full. Output paths under `R/` mirror each source document's path
#'   relative to the project root, so two documents that happen to share
#'   a filename in different directories (e.g. a directory-per-post
#'   convention using `index.qmd`) do not overwrite each other's output.
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
#' 5. Stamps `purl: true` or `purl: false` into the document's own YAML
#'    header, reflecting `use_purl`.
#' 6. If `yaml_data` is provided, reads the YAML file and substitutes
#'    values into the document header. This runs after style injection
#'    and the purl stamp, so `yaml_data` can override any auto-generated
#'    YAML key, including `purl` itself.
#' 7. If `use_purl = TRUE`, ensures `R/purl.R` exists. Then, unless
#'    `_quarto.yml` already exists and declares `project: type:` as
#'    `website`, `book`, or `manuscript` (in which case wiring is
#'    skipped with a warning explaining why), ensures `_quarto.yml` has
#'    the post-render hook -- creating `_quarto.yml` from the package
#'    template if absent, or merging the hook into the existing file's
#'    `project:` block if present.
#' 8. The sample dataset bundled with the template is a subset of the Palmer
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
#' # Minimal blank document -- no examples, no styling, no purl
#' create_qmd(path = tempdir(), filename = "analysis.qmd",
#'            include_examples = FALSE)
#'
#' # Full worked example with sample data and placeholder logo
#' create_qmd(path = tempdir(), filename = "analysis.qmd",
#'            overwrite = TRUE)
#'
#' # Opt this document into purl: stamps purl: true and wires up
#' # R/purl.R + the _quarto.yml post-render hook (merged if the file
#' # already exists, e.g. inside a larger Quarto website project)
#' create_qmd(path = tempdir(), filename = "analysis.qmd",
#'            overwrite = TRUE, use_purl = TRUE)
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
#'            overwrite = TRUE)
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
        use_purl = FALSE,
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

    # -- 6. Stamp purl: true/false into the document's own header ---------------
    # Always stamp explicitly, even when FALSE -- an omitted key would
    # leave R/purl.R unable to distinguish "not opted in" from "not a
    # toolero-scaffolded document at all" when it scans a project for
    # candidates.
    qmd_content <- .inject_purl_yaml(qmd_content, purl = use_purl)

    # -- 7. Substitute YAML if yaml_data is provided -----------------------------
    # Runs after style injection and the purl stamp, so a user's own
    # config can still override either -- including purl itself, if they
    # really want to hand-author that key.
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

    # -- 8. Ensure the post-render hook and R/purl.R exist if use_purl = TRUE ----
    if (use_purl) {

        # purl.R goes into R/, not the project root. Copied unconditionally
        # whenever use_purl = TRUE, regardless of whether _quarto.yml
        # wiring below is skipped by the multi-document-project guard --
        # the script being present is what lets someone wire the hook up
        # by hand after reading the warning.
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

        quarto_yml_dst <- fs::path(path, "_quarto.yml")
        multi_doc_types <- c("website", "book", "manuscript")
        project_type <- .quarto_project_type(quarto_yml_dst)

        if (!fs::file_exists(quarto_yml_dst)) {
            # No _quarto.yml yet -- copy the package template as a
            # starting point (preserves whatever other project defaults
            # it carries), then merge the hook in explicitly rather than
            # trusting the template already has it correctly wired. This
            # keeps "R/purl.R" defined in exactly one place --
            # .merge_post_render_hook()'s `hook` argument -- instead of
            # also depending on the template file's own contents staying
            # in sync with it. Not governed by overwrite: there is
            # nothing to overwrite. Nothing to guard against either -- a
            # brand-new _quarto.yml has no project: type: yet, so it
            # cannot be a multi-document project by definition.
            quarto_yml_src <- system.file(
                "templates", "_quarto.yml",
                package = "toolero",
                mustWork = TRUE
            )
            fs::file_copy(quarto_yml_src, quarto_yml_dst)
            .merge_post_render_hook(
                quarto_yml_path = quarto_yml_dst,
                hook             = "R/purl.R"
            )
            cli::cli_alert_success("Created {.path {quarto_yml_dst}}")
        } else if (!is.null(project_type) && project_type %in% multi_doc_types) {
            # A website, book, or manuscript project renders many
            # documents on every full build, and the person scaffolding
            # this one .qmd may not be thinking about the others. Skip
            # automatic wiring and explain how to add it deliberately.
            cli::cli_warn(c(
                "!" = "{.path {quarto_yml_dst}} is a {.val {project_type}} project -- skipping automatic post-render wiring.",
                "i" = "This project likely renders many documents at once,
                       and {.file R/purl.R} purls each one to a path
                       mirroring its own location under {.path R/}. Wiring
                       the hook automatically would opt the whole project
                       in without anyone deciding that on purpose.",
                "i" = "{.path R/purl.R} was still created. To enable it
                       yourself, add this to {.path {quarto_yml_dst}}:
                       project:
                         post-render: R/purl.R"
            ))
        } else {
            # Any other existing _quarto.yml -- merge the hook into its
            # project: block rather than overwriting the file. This
            # happens regardless of overwrite, since appending to
            # post-render is additive, not destructive.
            hook_added <- .merge_post_render_hook(
                quarto_yml_path = quarto_yml_dst,
                hook             = "R/purl.R"
            )
            if (hook_added) {
                cli::cli_alert_success(
                    "Added post-render hook to {.path {quarto_yml_dst}}"
                )
            } else {
                cli::cli_alert_info(
                    "{.path {quarto_yml_dst}} already has the purl hook -- nothing to add."
                )
            }
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


# -- Helper: stamp purl: true/false into a document's YAML header ------------

.inject_purl_yaml <- function(qmd_content, purl = TRUE) {

    qmd_content <- gsub("\r\n", "\n", qmd_content, fixed = TRUE)

    yaml_pattern <- "(?s)^---\\n(.+?)\\n---"
    yaml_match <- regmatches(
        qmd_content,
        regexpr(yaml_pattern, qmd_content, perl = TRUE)
    )

    if (length(yaml_match) == 0) {
        cli::cli_warn("No YAML header found in template. Skipping purl flag.")
        return(qmd_content)
    }

    template_yaml <- yaml::yaml.load(yaml_match)
    template_yaml[["purl"]] <- purl

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


# -- Helper: read project: type: from an existing _quarto.yml, if any -------

.quarto_project_type <- function(quarto_yml_path) {
    if (!fs::file_exists(quarto_yml_path)) {
        return(NULL)
    }
    existing <- yaml::read_yaml(quarto_yml_path)
    existing[["project"]][["type"]]
}


# -- Helper: merge a post-render hook into an existing _quarto.yml -----------

.merge_post_render_hook <- function(quarto_yml_path, hook = "R/purl.R") {

    existing <- yaml::read_yaml(quarto_yml_path)
    if (is.null(existing[["project"]])) {
        existing[["project"]] <- list()
    }

    # post-render may already exist as a bare string or as a YAML
    # sequence -- normalize to a character vector before checking or
    # appending, so either form already present in a hand-written
    # _quarto.yml is respected rather than clobbered.
    post_render <- existing[["project"]][["post-render"]]
    post_render <- if (is.null(post_render)) character(0) else as.character(post_render)

    if (hook %in% post_render) {
        return(invisible(FALSE))  # already wired -- nothing to do
    }

    existing[["project"]][["post-render"]] <- c(post_render, hook)
    yaml::write_yaml(existing, quarto_yml_path)
    invisible(TRUE)
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
