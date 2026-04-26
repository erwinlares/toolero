# toolero 0.3.0

### Breaking changes

* `create_qmd()`: `filename` no longer defaults to `"analysis.qmd"` — it
  must now be supplied explicitly. Code that relied on the default will error.
* `write_by_group()`: sanitized output filenames now use `-` (dash) as the
  separator instead of `_` (underscore), consistent with the package
  convention that file names use dashes. Existing workflows that reference
  output paths by name will need to update accordingly.
* `init_project()`: the `file_path` argument has been renamed to `path` for
  consistency with `create_qmd()` and the broader package API. Calls using
  `file_path =` by name will error; positional calls are unaffected.

### Bug fixes

* `create_qmd()`: `_quarto.yml` is now copied from `inst/templates/` rather
  than written from a hardcoded string, so changes to the template are
  reflected automatically.
* `create_qmd()`: `purl.R` is now correctly placed in `R/` instead of the
  project root, consistent with `_quarto.yml` calling `Rscript R/purl.R`.
* `inst/templates/purl.R`: replaced `QUARTO_DOCUMENT_PATH` environment
  variable approach with `fs::dir_ls()` glob scan, which works reliably
  regardless of how Quarto invokes the post-render script.

### New features

* Added `generate_kb_xml()` to produce UW-Madison KB-importable XML files
  from rendered Quarto documents. Extracts metadata from the `.qmd` YAML
  header and re-renders with embedded resources for self-contained import.
* `create_qmd()`: added `use_purl` argument (default `TRUE`) that scaffolds
  a `_quarto.yml` post-render hook and a `purl.R` script for extracting R
  code from rendered documents.


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
