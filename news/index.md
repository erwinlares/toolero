# Changelog

## toolero 0.4.0

#### Breaking changes

- [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md):
  no longer copies `styles.css` and `header.html` from the package into
  the project. Custom styling is now controlled exclusively by the new
  `use_style` argument. Projects that relied on
  [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
  copying UW-branded assets should use
  `init_project(uw_branding = TRUE)` to scaffold those files, then pass
  `use_style = TRUE` to
  [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
  to wire them into the YAML.
- [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md):
  sample data is now copied into `data-raw/` instead of `data/`,
  consistent with
  [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)’s
  folder structure.

#### New features

- Added
  [`arborize()`](https://erwinlares.github.io/toolero/reference/arborize.md)
  for rendering syntactic trees as standalone PNG images using Quarto’s
  Typst engine. Accepts two input formats via the `tree_notation`
  argument:
  - `"simple"` (default) – bracket notation string, uses
    `@preview/syntree:0.2.1`
  - `"structured"` – nested `tree()` call string, uses
    `@preview/lingotree:1.0.0` Output PNG files can be embedded in any
    document format without requiring a LaTeX installation. Requires
    Quarto 1.4+ with Typst support and the `pdftools` package (in
    Suggests).
- [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md):
  added `include_examples` argument (default `TRUE`). When `TRUE`,
  copies a sample dataset (`sample.csv`) into `data-raw/`, a placeholder
  logo (`logo.png`) into `assets/`, and uses a worked example template
  with a `params` block referencing the sample data. When `FALSE`,
  creates a blank skeleton `.qmd` with only the YAML header and a setup
  chunk – no sample data, no logo, no example analysis block.
- [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md):
  added `use_style` argument (default `FALSE`). Accepts `FALSE` (no
  custom styling), `TRUE` (scans `assets/` for `.css` and `.html`
  files), or a directory path (scans that directory instead). When
  exactly one `.css` file is found, it is added as `css:` in the YAML.
  When exactly one `.html` file is found, it is added as
  `include-before-body:`. If multiple files of either type are found,
  the function errors and asks the user to specify which one to use via
  `yaml_data`. This decouples styling from
  [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
  and supports non-UW branding workflows.
- Added `inst/templates/skeleton.qmd` – a minimal Quarto template used
  when `include_examples = FALSE`. Contains the YAML header, a setup
  chunk with
  [`library(toolero)`](https://github.com/erwinlares/toolero), and a
  single placeholder heading.
- Added `inst/templates/logo.png` – a placeholder logo image copied into
  `assets/` when `include_examples = TRUE`. Reads “your logo goes here”
  so the user knows to replace it with their own branding.

## toolero 0.3.0

CRAN release: 2026-04-27

#### Breaking changes

- [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md):
  `filename` is now the first argument and has no default – it must be
  supplied explicitly. `path` is now the second argument and defaults to
  `"."`, allowing natural calls like `create_qmd("analysis.qmd")`.
- [`write_by_group()`](https://erwinlares.github.io/toolero/reference/write_by_group.md):
  sanitized output filenames now use `-` (dash) as the separator instead
  of `_` (underscore), consistent with the package convention that file
  names use dashes. Existing workflows that reference output paths by
  name will need to update accordingly.
- [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md):
  the `file_path` argument has been renamed to `path` for consistency
  with
  [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
  and the broader package API. Calls using `file_path =` by name will
  error; positional calls are unaffected.

#### New features

- Added
  [`generate_kb_xml()`](https://erwinlares.github.io/toolero/reference/generate_kb_xml.md)
  to produce UW-Madison KB-importable XML files from rendered Quarto
  documents. Extracts metadata from the `.qmd` YAML header and
  re-renders with embedded resources for self-contained import.
- [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md):
  added `use_purl` argument (default `TRUE`) that scaffolds a
  `_quarto.yml` post-render hook and a `purl.R` script for extracting R
  code from rendered documents into `R/`.

#### Bug fixes

- [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md):
  now runs
  [`renv::snapshot()`](https://rstudio.github.io/renv/reference/snapshot.html)
  and creates `.renvignore` after
  [`renv::init()`](https://rstudio.github.io/renv/reference/init.html),
  ensuring the lockfile is populated and `.qmd` files are excluded from
  dependency scanning at project creation time.
- [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md):
  `_quarto.yml` is now copied from `inst/templates/` rather than written
  from a hardcoded string, so changes to the template are reflected
  automatically.
- [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md):
  `purl.R` is now correctly placed in `R/` instead of the project root,
  consistent with `_quarto.yml` calling `Rscript R/purl.R`.
- [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md):
  fixed YAML boolean serialization when `yaml_data` is supplied.
  [`yaml::as.yaml()`](https://yaml.r-lib.org/reference/as.yaml.html) was
  converting `true`/`false` to `yes`/`no`, which Quarto does not
  recognize. A custom handler now forces unquoted `true`/`false` output.
- `inst/templates/purl.R`: replaced `QUARTO_DOCUMENT_PATH` environment
  variable approach with
  [`fs::dir_ls()`](https://fs.r-lib.org/reference/dir_ls.html) glob
  scan, which works reliably regardless of how Quarto invokes the
  post-render script.

## toolero 0.2.0

CRAN release: 2026-04-24

#### Breaking changes

- [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md):
  `path` is now a required argument with no default. Passing `NULL` or
  omitting it raises an error. Use
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html) for temporary
  output.
- [`write_by_group()`](https://erwinlares.github.io/toolero/reference/write_by_group.md):
  `output_dir` is now a required argument with no default. Passing
  `NULL` or omitting it raises an error. Use
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html) for temporary
  output.
- [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md):
  `open` now defaults to `FALSE` instead of `TRUE` to avoid disrupting
  the current RStudio session in non-interactive contexts.

#### New features

- Added
  [`detect_execution_context()`](https://erwinlares.github.io/toolero/reference/detect_execution_context.md)
  to identify whether code is running in an interactive R session, a
  `quarto render` call, or a plain `Rscript` invocation. Returns one of
  `"interactive"`, `"quarto"`, or `"rscript"`.
- Added
  [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
  to scaffold a new Quarto document from a reproducible template,
  including a sample dataset, UW-Madison branded assets, and
  three-context input resolution via
  [`detect_execution_context()`](https://erwinlares.github.io/toolero/reference/detect_execution_context.md).
  Optionally pre-populates the YAML header from a user-supplied YAML
  config file.
- Added
  [`write_by_group()`](https://erwinlares.github.io/toolero/reference/write_by_group.md)
  to split a data frame by a single grouping column and write each group
  to a separate CSV file. Filenames are derived from sanitized group
  values. Optionally writes a `manifest.csv` listing output files, group
  values, and row counts.

## toolero 0.1.1

#### New features

- Added `uw_branding` argument to
  [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md).
  When `TRUE`, creates an `assets/` folder in the new project and
  populates it with UW-Madison RCI branding files (`styles.css`,
  `header.html`, `rci-banner.png`).

## toolero 0.1.0

- Initial CRAN submission.
