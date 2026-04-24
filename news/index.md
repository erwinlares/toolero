# Changelog

## toolero 0.3.0

#### New features

- Added
  [`generate_kb_xml()`](https://erwinlares.github.io/toolero/reference/generate_kb_xml.md)
  to produce UW-Madison KB-importable XML files from rendered Quarto
  documents. Extracts metadata from the `.qmd` YAML header and
  re-renders with embedded resources for self-contained import.
- [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md):
  added `use_purl` argument (default `TRUE`) that scaffolds a
  `_quarto.yml` post-render hook and a `purl.R` script for extracting R
  code from rendered documents.
- [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md):
  `filename` argument now requires explicit input rather than defaulting
  to `"analysis.qmd"`.

#### Changes

- [`write_by_group()`](https://erwinlares.github.io/toolero/reference/write_by_group.md):
  sanitized output filenames now use `-` (dash) as the separator instead
  of `_` (underscore), consistent with the package convention that file
  names use dashes. Existing workflows that reference output paths by
  name will need to update accordingly.
- [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md):
  renamed `file_path` argument to `path` for consistency with
  [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
  and the broader package API.

## toolero 0.2.0

CRAN release: 2026-04-24

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
