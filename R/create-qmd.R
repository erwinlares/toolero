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
#' @param header_defaults A string or `NULL`. Path to a YAML file supplying
#'   values to pre-populate the document header -- typically a profile
#'   written by [generate_profile()], but any YAML file following the same
#'   shape works. If `NULL` (the default), the template is copied as-is
#'   with placeholder prompts intact. Every key in the file, at any depth,
#'   replaces the template's key of the same name; keys the file does not
#'   mention are left exactly as the template wrote them. A key whose value
#'   is itself a mapping (`format: html: ...`) is descended into and merged
#'   key by key, so a sibling the file doesn't mention -- `css:` from
#'   `use_style`, say -- survives; a key whose value is a sequence
#'   (`author:`, `categories:`) is replaced as a whole, not merged element
#'   by element. Named `yaml_data` before v0.5.1.9000; that name still
#'   works but is deprecated (see below).
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
#'     any other scaffolded file -- an existing `R/purl.R` is left in
#'     place unless `overwrite = TRUE`).
#'   - Ensures `path/_quarto.yml` has a `project: post-render:` entry
#'     pointing at `R/purl.R` -- *unless* `_quarto.yml` already exists
#'     and declares `project: type:` as `website`, `book`, or
#'     `manuscript`, in which case the hook is deliberately **not**
#'     wired automatically. A `cli_warn()` explains why, reports whether
#'     `R/purl.R` was created or was already present, and names the
#'     `post-render:` entry to add by hand. This guard exists
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
#'
#' @param include_examples Logical. If `TRUE` (the default), copies a sample
#'   dataset (`sample.csv`) into `data-raw/` and uses a template `.qmd`
#'   pre-populated with a worked analysis example. The YAML header includes
#'   a `params` block referencing the sample data. If `FALSE`, creates a
#'   blank `.qmd` with only the YAML header and no example content, and
#'   skips copying the sample dataset.
#'
#'   A placeholder logo (`generic-logo.png`, copied as `logo.png`) is also
#'   copied into `assets/`, but only when branding is actually part of the
#'   project: if `path` carries a `_toolero.yml` (as written by
#'   [init_project()]) whose `folders:` list does not include `assets`
#'   (i.e. the project was scaffolded with `branding = "none"`), the logo
#'   is skipped along with it, so a project that declared no branding does
#'   not end up with an undeclared `assets/logo.png` anyway. A `.qmd`
#'   created outside any toolero-scaffolded project (no `_toolero.yml` at
#'   `path`) always gets the logo, since there is no project-level branding
#'   decision to defer to. If `assets/logo.png` already exists (e.g. from a
#'   prior [init_project()] call with `branding` set), it is always left
#'   untouched -- an existing logo takes precedence over the generic
#'   placeholder even when `overwrite = TRUE`.
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
#' @param yaml_data `r lifecycle::badge("deprecated")` A string or `NULL`.
#'   Renamed to `header_defaults` in v0.5.1.9000 -- the argument still
#'   works, and its value is used when `header_defaults` is not also
#'   supplied, but new code should use `header_defaults`.
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
#' 6. If `header_defaults` (or the deprecated `yaml_data`) is provided,
#'    reads the YAML file and substitutes its values into the document
#'    header, descending into nested mappings so a sibling key it doesn't
#'    mention survives. This runs after style injection and the purl
#'    stamp, so `header_defaults` can override any auto-generated YAML
#'    key, including `purl` itself.
#' 7. If `use_purl = TRUE`, ensures `R/purl.R` exists. Then, unless
#'    `_quarto.yml` already exists and declares `project: type:` as
#'    `website`, `book`, or `manuscript` (in which case wiring is
#'    skipped with a warning explaining why), ensures `_quarto.yml` has
#'    the post-render hook -- creating `_quarto.yml` from the package
#'    template if absent, or merging the hook into the existing file's
#'    `project:` block if present.
#' 8. The sample dataset bundled with the template, `data-raw/sample.csv`,
#'    is a subset of the Palmer Archipelago penguin data, taken from an
#'    earlier version of the `palmerpenguins` package than the one on CRAN
#'    today. Treat it as teaching material rather than as a citable copy of
#'    the data.
#'
#'    Since R 4.5.0 the same data ships with base R, so `?datasets::penguins`
#'    is the most convenient reference, with `datasets::penguins_raw`
#'    carrying the uncleaned form. One difference matters when reading the
#'    two side by side: base R shortened four of the column names, so
#'    `bill_length_mm`, `bill_depth_mm`, `flipper_length_mm` and
#'    `body_mass_g` here are `bill_len`, `bill_dep`, `flipper_len` and
#'    `body_mass` there. `species`, `island`, `sex` and `year` are spelled
#'    the same in both. This template keeps the longer names, which carry
#'    their units.
#'
#'    Original data: Gorman KB, Williams TD, Fraser WR (2014). Ecological
#'    sexual dimorphism and environmental variability within a community of
#'    Antarctic penguins (genus Pygoscelis). PLoS ONE 9(3): e90081.
#'    \doi{10.1371/journal.pone.0090081}. R package: Horst AM, Hill AP,
#'    Gorman KB (2020). palmerpenguins: Palmer Archipelago (Antarctica)
#'    Penguin Data. \doi{10.5281/zenodo.3960218}. Collected by Palmer
#'    Station Antarctica LTER, a member of the Long Term Ecological
#'    Research Network.
#'
#' Every edit to the document's YAML header is made line by line rather
#' than by parsing the header and writing it back out. Keys the edit does
#' not touch keep the template's own quoting, indentation, comments, and
#' ordering, so the document a reader opens is the template we shipped
#' plus the keys they asked for.
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
#' # Pre-populated YAML header, typically from generate_profile()
#' profile_file <- tempfile(fileext = ".yml")
#' writeLines("author:\n  - name: 'Your Name'", profile_file)
#' create_qmd(path = tempdir(), filename = "analysis.qmd",
#'            header_defaults = profile_file, overwrite = TRUE)
#' }
create_qmd <- function(
        filename = NULL,
        path = ".",
        header_defaults = NULL,
        overwrite = FALSE,
        use_purl = FALSE,
        include_examples = TRUE,
        use_style = FALSE,
        yaml_data = lifecycle::deprecated()) {

    # -- 0. Handle the yaml_data -> header_defaults rename -----------------------
    if (lifecycle::is_present(yaml_data)) {
        lifecycle::deprecate_warn(
            when = "0.5.1.9000",
            what = "create_qmd(yaml_data = )",
            with = "create_qmd(header_defaults = )"
        )
        if (is.null(header_defaults)) {
            header_defaults <- yaml_data
        }
    }

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

        sample_src <- .package_template("sample.csv")
        sample_dst <- fs::path(data_dir, "sample.csv")

        if (!fs::file_exists(sample_dst) || overwrite) {
            fs::file_copy(sample_src, sample_dst, overwrite = overwrite)
            cli::cli_alert_success("Created {.path {sample_dst}}")
        } else {
            cli::cli_alert_info(
                "Skipping {.path {sample_dst}} -- already exists."
            )
        }

        # assets/ with placeholder logo.png -- but only when the project's
        # own _toolero.yml (if any) actually declares assets as part of its
        # structure. A project scaffolded with branding = "none" declares
        # no assets/ folder at all, and writing a logo into it anyway would
        # leave the project with an undeclared folder containing a file
        # nothing else in the project asked for. No _toolero.yml at all
        # (a bare .qmd, not part of a toolero-scaffolded project) means
        # there's no project-level branding decision to defer to, so the
        # logo is written as before.
        project_yml  <- .read_project_yml(path)
        has_manifest <- !is.null(project_yml) && !is.null(project_yml$folders)
        branding_off <- has_manifest && !("assets" %in% unlist(project_yml$folders))

        if (branding_off) {
            config_name <- .project_yml_name()
            cli::cli_alert_info(
                "Skipping {.path {fs::path(path, 'assets', 'logo.png')}} -- {.path {config_name}}
         does not declare {.val assets} among this project's folders."
            )
        } else {
            # Deliberately exempt from overwrite. An existing logo (e.g.
            # from init_project(branding = )) is assumed to be intentional
            # branding, and silently replacing it with the generic
            # placeholder would be surprising.
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
    }

    # -- 4. Choose and read the template ----------------------------------------
    if (include_examples) {
        template_name <- "example.qmd"
    } else {
        template_name <- "skeleton.qmd"
    }

    qmd_src <- .package_template(template_name)
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

    # -- 7. Substitute YAML if header_defaults is provided -----------------------
    # Runs after style injection and the purl stamp, so header_defaults can
    # still override either -- including purl itself, if the file really
    # does set that key.
    if (!is.null(header_defaults)) {
        if (!fs::file_exists(header_defaults)) {
            cli::cli_abort(
                "header_defaults file {.path {header_defaults}} does not exist."
            )
        }

        user_yaml <- yaml::read_yaml(header_defaults)
        qmd_content <- .substitute_yaml(qmd_content, user_yaml)
    }

    readr::write_file(qmd_content, qmd_dst)
    cli::cli_alert_success("Created {.path {qmd_dst}}")

    # -- 8. Ensure the post-render hook and R/purl.R exist if use_purl = TRUE ----
    if (use_purl) {

        # purl.R goes into R/, not the project root. Scaffolded whenever
        # use_purl = TRUE and subject to overwrite like any other file, so
        # an existing copy is left in place unless overwrite = TRUE. This
        # happens regardless of whether the _quarto.yml wiring below is
        # skipped by the multi-document-project guard -- the script being
        # in place is what lets someone wire the hook up by hand after
        # reading the warning, which is why the warning reports whether
        # the copy is fresh or pre-existing.
        purl_src <- .package_template("purl.R")
        fs::dir_create(fs::path(path, "R"))
        purl_dst <- fs::path(path, "R", "purl.R")

        purl_copied <- !fs::file_exists(purl_dst) || overwrite

        if (purl_copied) {
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
            quarto_yml_src <- .package_template("_quarto.yml")
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
            #
            # The status line matters: whoever reads this warning is
            # about to point a post-render hook at R/purl.R by hand, and
            # they need to know whether the script sitting there is the
            # one this version of toolero ships or one left over from an
            # earlier run.
            # Passed to cli as a format string in its own right, not
            # interpolated into one: cli does not process inline markup
            # inside a substituted value, so {.code} written into a
            # variable and dropped in with {purl_note} would print its
            # own braces.
            purl_note <- if (purl_copied) {
                "{.path R/purl.R} was created just now."
            } else {
                "{.path R/purl.R} was already there and has been left as
                 it is. Re-run with {.code overwrite = TRUE} if you want
                 the copy this version of toolero ships."
            }

            cli::cli_warn(c(
                "!" = "{.path {quarto_yml_dst}} is a {.val {project_type}} project -- skipping automatic post-render wiring.",
                "i" = "This project likely renders many documents at once,
                       and {.file R/purl.R} purls each one to a path
                       mirroring its own location under {.path R/}. Wiring
                       the hook automatically would opt the whole project
                       in without anyone deciding that on purpose.",
                "i" = purl_note,
                "i" = "To enable it yourself, add
                       {.code post-render: R/purl.R} under the
                       {.code project:} key in {.path {quarto_yml_dst}}."
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
#
# Each asset is one key under format: html:, so each is one call to the
# line-oriented setter in R/utils-yaml.R. Nothing else in the header is
# read, rewritten, or reordered.

.inject_style_yaml <- function(qmd_content,
                               css_file = NULL,
                               header_file = NULL,
                               footer_file = NULL) {

    keys <- list()

    if (!is.null(css_file)) {
        keys <- c(keys, list(list(
            path  = c("format", "html", "css"),
            value = as.character(css_file)
        )))
    }

    # header.html holds visible banner markup, so it belongs before the
    # body -- include-in-header would place it inside <head>.
    if (!is.null(header_file)) {
        keys <- c(keys, list(list(
            path  = c("format", "html", "include-before-body"),
            value = as.character(header_file)
        )))
    }

    if (!is.null(footer_file)) {
        keys <- c(keys, list(list(
            path  = c("format", "html", "include-after-body"),
            value = as.character(footer_file)
        )))
    }

    .set_yaml_keys(qmd_content, keys, what = "style injection")
}


# -- Helper: stamp purl: true/false into a document's YAML header ------------

.inject_purl_yaml <- function(qmd_content, purl = TRUE) {
    .set_yaml_keys(
        qmd_content,
        list(list(path = "purl", value = isTRUE(purl))),
        what = "the purl flag"
    )
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


# -- Helper: flatten nested YAML into leaf-level (path, value) entries ------
#
# A YAML *mapping* (a block of `key: value` pairs -- read.yaml() gives it
# names) is a settings block whose individual keys should each be set on
# their own, leaving sibling keys the caller didn't mention untouched. A
# YAML *sequence* (a list, like `categories:` or `author:` -- read_yaml()
# gives it no names, even when its elements are themselves mappings) is a
# single value to replace wholesale: merging a list of authors element by
# element against whatever the template happened to have makes no sense,
# and neither does merging a list of category strings.
#
# `is_mapping()` is the test that tells the two apart: a list is a mapping
# only when it has names and every one of them is non-empty. An empty list
# (`list()`) has no names either way and is treated as a leaf, which is the
# conservative choice -- there is nothing to descend into.

.is_yaml_mapping <- function(x) {
    is.list(x) && length(x) > 0L && !is.null(names(x)) && all(nzchar(names(x)))
}

.flatten_yaml_keys <- function(user_yaml, prefix = character(0)) {
    entries <- list()

    for (key in names(user_yaml)) {
        value    <- user_yaml[[key]]
        this_path <- c(prefix, key)

        if (.is_yaml_mapping(value)) {
            entries <- c(entries, .flatten_yaml_keys(value, this_path))
        } else {
            entries[[length(entries) + 1L]] <- list(path = this_path, value = value)
        }
    }

    entries
}

# -- Helper: substitute YAML values into template ----------------------------
#
# Each key the user supplies replaces the template's key of the same name,
# descending into nested mappings (like `format: html: ...`) so that a
# sibling key the user did not mention -- css/include-before-body/
# include-after-body from use_style, say -- survives rather than being
# discarded along with the rest of the block it lives in. A sequence
# (`author:`, `categories:`) is still replaced wholesale, as a single unit,
# since merging a list element by element against the template's own list
# is not a meaningful operation. Keys the user does not mention at all,
# at any level, are no longer reserialized on the way past: they stay
# exactly as the template wrote them, comments, quoting and all.

.substitute_yaml <- function(qmd_content, user_yaml) {

    keys <- .flatten_yaml_keys(user_yaml)

    .set_yaml_keys(qmd_content, keys, what = "substitution")
}
