# toolero
<img src="man/figures/logo.png" align="right" height="139" alt="toolero package logo"/>

<!-- badges: start -->
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.19457647.svg)](https://doi.org/10.5281/zenodo.19457647)
[![R-CMD-check](https://github.com/erwinlares/toolero/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/erwinlares/toolero/actions/workflows/R-CMD-check.yaml)
[![CRAN status](https://www.r-pkg.org/badges/version/toolero)](https://CRAN.R-project.org/package=toolero)
[![CRAN downloads](https://cranlogs.r-pkg.org/badges/toolero)](https://cran.r-project.org/package=toolero)
<!-- badges: end -->

`toolero` is an R package designed to help researchers implement best practices
for their coding projects. It provides a small set of opinionated, practical
functions that reduce friction at the start of a project and during day-to-day
data work.

## Installation

You can install `toolero` from CRAN:

``` r
install.packages("toolero")
```

Or install the development version from GitHub:

``` r
# install.packages("pak")
pak::pak("erwinlares/toolero")
```

## Functions

### `init_project()`

Creates a new R project with a standard folder structure suited for research
workflows. Optionally initializes `renv` for package management and `git` for
version control.

``` r
library(toolero)

# Create a project with the standard folder structure
init_project(path = "~/Documents/my-project")

# Add extra folders
init_project(path = "~/Documents/my-project",
             extra_folders = c("notebooks", "presentations"))

# Skip renv and git
init_project(path = "~/Documents/my-project", use_renv = FALSE, use_git = FALSE)
```

The default folder structure includes: `data/`, `data-raw/`, `R/`, `scripts/`,
`plots/`, `images/`, `results/`, and `docs/`.

### `create_qmd()`

Scaffolds a new Quarto document from a reproducible template, including a
sample dataset, UW-Madison branded assets, and an optional post-render purl
hook that extracts R code from the rendered document into a companion `.R`
file. Optionally pre-populates the YAML header from a user-supplied YAML
config file.

``` r
library(toolero)

# Create a document with placeholder YAML
create_qmd(path = "~/Documents/my-project", filename = "analysis.qmd")

# Create without the purl hook
create_qmd(path = "~/Documents/my-project", filename = "report.qmd",
           use_purl = FALSE)

# Pre-populate YAML from a personal config file
create_qmd(path = "~/Documents/my-project", filename = "analysis.qmd",
           yaml_data = "~/my_config.yml")
```

### `read_clean_csv()`

Reads a CSV file and cleans the column names in one step, producing a
tidyverse-friendly tibble.

``` r
library(toolero)

data <- read_clean_csv("path/to/file.csv")

# Show column type messages
data <- read_clean_csv("path/to/file.csv", verbose = TRUE)
```

### `detect_execution_context()`

Identifies which of three execution environments the code is currently running
in: an interactive R session, a `quarto render` call, or a plain `Rscript`
invocation. Returns one of `"interactive"`, `"quarto"`, or `"rscript"`.

``` r
library(toolero)

context <- detect_execution_context()

input_file <- switch(context,
  interactive = "data/sample.csv",
  quarto      = params$input_file,
  rscript     = commandArgs(trailingOnly = TRUE)[1]
)
```

### `write_by_group()`

Splits a data frame by a single grouping column and writes each group to a
separate CSV file. Filenames are derived from sanitized group values —
converted to lowercase with spaces and special characters replaced by dashes.
Optionally writes a `manifest.csv` listing output files, group values, and
row counts.

``` r
library(toolero)

# Load the bundled sample dataset
sample_path <- system.file("templates", "sample.csv", package = "toolero")
penguins    <- read_clean_csv(sample_path)

# Split by species
write_by_group(penguins, group_col = "species", output_dir = tempdir())

# Also write a manifest
write_by_group(penguins, group_col = "species",
               output_dir = tempdir(), manifest = TRUE)
```

### `generate_kb_xml()`

Produces a UW-Madison Knowledge Base importable XML file from a rendered
Quarto document. Re-renders the source `.qmd` with all assets embedded,
extracts the HTML body, and wraps it in the KB XML structure along with
metadata drawn from the document's YAML header — `title` → `kb_title`,
`description` → `kb_summary`, `categories` → `kb_keywords`.

``` r
library(toolero)

generate_kb_xml(
  html_path  = "docs/analysis.html",
  output_dir = "exports"
)
```

When importing the resulting XML into the KB, check the
*Decode HTML entity in body content* option.

## Citation

To cite `toolero` in publications:

``` r
citation("toolero")
```

## License

MIT © Erwin Lares
