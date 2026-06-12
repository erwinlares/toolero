# toolero 0.4.0

### New features

* Added `run_by_group()`, the apply half of the split-apply workflow. Accepts
  either a manifest CSV produced by `write_by_group(manifest = TRUE)` or a
  named list of data frames. Applies a user-supplied function to each group
  subset and collects the results into a flat tibble (when the function returns
  a data frame) or a nested tibble with a list-column (when it returns anything
  else). Supports parallel execution via `furrr` and `future` through the
  `workers` argument, with a hard ceiling at
  `parallel::detectCores(logical = FALSE) - 1L` to reserve one core for the
  main session. A `seed` argument enables reproducible parallel execution for
  analyses involving randomness.
* Added `read_clean_csv()` for reading CSV files into a tibble with
  `janitor::clean_names()` applied automatically. Supports explicit
  missing-value codes via `na`, selective row dropping via `drop_na` (accepts
  `TRUE` or a character vector of column names), an optional ingest summary
  via `summary`, and pass-through arguments to `readr::read_csv()` via `...`.
* Added `write_clean_csv()` for writing data frames to CSV with clean column
  names. Applies `janitor::clean_names()` if column names are not already
  clean and reports affected columns via cli feedback.
* Added `check_project()` for auditing a project directory against toolero
  conventions. Checks for expected folders, an `.Rproj` file, `renv.lock`,
  a git repository, a README, a `.gitignore`, and hidden files such as
  `.RData` or `.Rhistory`. Operates in two modes: a cli report (default) or
  a tibble return for programmatic use (`error = FALSE`).
* Added `qmd_to_r()` for extracting R code chunks from any `.qmd` file into
  a standalone `.R` script via `knitr::purl()`. The output path defaults to
  the same directory as the input with the extension replaced. The
  `documentation` argument controls how much context is preserved in the
  extracted script.
* Added Palmer Penguins attribution (Horst, Hill & Gorman, 2020) to the
  template `.qmd`, the `create_qmd()` roxygen `@details` section, and a
  provenance note in `inst/extdata/`.

### Breaking changes

* `create_qmd()`: no longer copies `styles.css` and `header.html` from the
  package into the project. Custom styling is now controlled exclusively by
  the new `use_style` argument. Projects that relied on `create_qmd()`
  copying UW-branded assets should use `init_project(uw_branding = TRUE)` to
  scaffold those files, then pass `use_style = TRUE` to `create_qmd()` to
  wire them into the YAML.
* `create_qmd()`: sample data is now copied into `data-raw/` instead of
  `data/`, consistent with `init_project()`'s folder structure.

### New features (continued from above)

* `create_qmd()`: added `include_examples` argument (default `TRUE`). When
  `TRUE`, copies a sample dataset (`sample.csv`) into `data-raw/`, a
  placeholder logo (`logo.png`) into `assets/`, and uses a worked example
  template with a `params` block referencing the sample data. When `FALSE`,
  creates a blank skeleton `.qmd` with only the YAML header and a setup
  chunk -- no sample data, no logo, no example analysis block.
* `create_qmd()`: added `use_style` argument (default `FALSE`). Accepts
  `FALSE` (no custom styling), `TRUE` (scans `assets/` for `.css` and
  `.html` files), or a directory path (scans that directory instead). When
  exactly one `.css` file is found, it is added as `css:` in the YAML. When
  exactly one `.html` file is found, it is added as `include-before-body:`.
  If multiple files of either type are found, the function errors and asks
  the user to specify which one to use via `yaml_data`. This decouples
  styling from `init_project()` and supports non-UW branding workflows.
* Added `inst/templates/skeleton.qmd` -- a minimal Quarto template used when
  `include_examples = FALSE`. Contains the YAML header, a setup chunk with
  `library(toolero)`, and a single placeholder heading.
* Added `inst/templates/logo.png` -- a placeholder logo image copied into
  `assets/` when `include_examples = TRUE`. Reads "your logo goes here" so
  the user knows to replace it with their own branding.

# toolero 0.3.0

### Breaking changes

* `create_qmd()`: `filename` is now the first argument and has no default --
  it must be supplied explicitly. `path` is now the second argument and
  defaults to `"."`, allowing natural calls like `create_qmd("analysis.qmd")`.
* `write_by_group()`: sanitized output filenames now use `-` (dash) as the
  separator instead of `_` (underscore), consistent with the package
  convention that file names use dashes. Existing workflows that reference
  output paths by name will need to update accordingly.
* `init_project()`: the `file_path` argument has been renamed to `path` for
  consistency with `create_qmd()` and the broader package API. Calls using
  `file_path =` by name will error; positional calls are unaffected.

### New features

* Added `generate_kb_xml()` to produce UW-Madison KB-importable XML files
  from rendered Quarto documents. Extracts metadata from the `.qmd` YAML
  header and re-renders with embedded resources for self-contained import.
* `create_qmd()`: added `use_purl` argument (default `TRUE`) that scaffolds
  a `_quarto.yml` post-render hook and a `purl.R` script for extracting R
  code from rendered documents into `R/`.

### Bug fixes

* `init_project()`: now runs `renv::snapshot()` and creates `.renvignore`
  after `renv::init()`, ensuring the lockfile is populated and `.qmd` files
  are excluded from dependency scanning at project creation time.
* `create_qmd()`: `_quarto.yml` is now copied from `inst/templates/` rather
  than written from a hardcoded string, so changes to the template are
  reflected automatically.
* `create_qmd()`: `purl.R` is now correctly placed in `R/` instead of the
  project root, consistent with `_quarto.yml` calling `Rscript R/purl.R`.
* `create_qmd()`: fixed YAML boolean serialization when `yaml_data` is
  supplied. `yaml::as.yaml()` was converting `true`/`false` to `yes`/`no`,
  which Quarto does not recognize. A custom handler now forces unquoted
  `true`/`false` output.
* `inst/templates/purl.R`: replaced `QUARTO_DOCUMENT_PATH` environment
  variable approach with `fs::dir_ls()` glob scan, which works reliably
  regardless of how Quarto invokes the post-render script.


# toolero 0.2.0

### Breaking changes

* `create_qmd()`: `path` is now a required argument with no default. Passing
  `NULL` or omitting it raises an error. Use `tempdir()` for temporary output.
* `write_by_group()`: `output_dir` is now a required argument with no default.
  Passing `NULL` or omitting it raises an error. Use `tempdir()` for temporary
  output.
* `init_project()`: `open` now defaults to `FALSE` instead of `TRUE` to avoid
  disrupting the current RStudio session in non-interactive contexts.

### New features

* Added `detect_execution_context()` to identify whether code is running in
  an interactive R session, a `quarto render` call, or a plain `Rscript`
  invocation. Returns one of `"interactive"`, `"quarto"`, or `"rscript"`.
* Added `create_qmd()` to scaffold a new Quarto document from a reproducible
  template, including a sample dataset, UW-Madison branded assets, and
  three-context input resolution via `detect_execution_context()`. Optionally
  pre-populates the YAML header from a user-supplied YAML config file.
* Added `write_by_group()` to split a data frame by a single grouping column
  and write each group to a separate CSV file. Filenames are derived from
  sanitized group values. Optionally writes a `manifest.csv` listing output
  files, group values, and row counts.


# toolero 0.1.1

### New features

* Added `uw_branding` argument to `init_project()`. When `TRUE`, creates an
  `assets/` folder in the new project and populates it with UW-Madison RCI
  branding files (`styles.css`, `header.html`, `rci-banner.png`).


# toolero 0.1.0

* Initial CRAN submission.
