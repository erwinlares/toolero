# toolero 0.2.0

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
