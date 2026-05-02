# toolero
<img src="man/figures/logo.png" align="right" height="139" alt="toolero package logo"/>

<!-- badges: start -->
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.19457647.svg)](https://doi.org/10.5281/zenodo.19457647)
[![R-CMD-check](https://github.com/erwinlares/toolero/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/erwinlares/toolero/actions/workflows/R-CMD-check.yaml)
[![CRAN status](https://www.r-pkg.org/badges/version/toolero)](https://CRAN.R-project.org/package=toolero)
[![CRAN downloads](https://cranlogs.r-pkg.org/badges/toolero)](https://cran.r-project.org/package=toolero)
[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![Codecov test coverage](https://codecov.io/gh/erwinlares/toolero/graph/badge.svg)](https://app.codecov.io/gh/erwinlares/toolero)
<!-- badges: end -->

`toolero` is an R package designed to help researchers implement best practices
for their coding projects. It provides a small set of opinionated, practical
functions that reduce friction at the start of a project and during day-to-day
data work.

## Installation

You can install `toolero` from CRAN:

```r
install.packages("toolero")
```

Or install the development version from GitHub:

```r
# install.packages("pak")
pak::pak("erwinlares/toolero")
```

## Functions

### `init_project()`

Creates a new R project with a standard folder structure suited for research
workflows. Optionally initializes `renv` for package management and `git` for
version control.

```r
library(toolero)

# Create a project with the standard folder structure
init_project(path = "~/Documents/my-project")

# Add extra folders
init_project(path = "~/Documents/my-project",
             extra_folders = c("notebooks", "presentations"))

# Skip renv and git
init_project(path = "~/Documents/my-project",
             use_renv = FALSE, use_git = FALSE)
```

The default folder structure includes: `data/`, `data-raw/`, `R/`, `scripts/`,
`plots/`, `images/`, `results/`, and `docs/`.

### `create_qmd()`

Scaffolds a new Quarto document from a reproducible template, including a
sample dataset, UW-Madison branded assets, and an optional post-render purl
hook that extracts R code from the rendered document into a companion `.R`
file. Optionally pre-populates the YAML header from a user-supplied YAML
config file.

```r
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

```r
library(toolero)

data <- read_clean_csv("path/to/file.csv")

# Show column type messages
data <- read_clean_csv("path/to/file.csv", verbose = TRUE)
```

### `detect_execution_context()`

Identifies which of three execution environments the code is currently running
in: an interactive R session, a `quarto render` call, or a plain `Rscript`
invocation. Returns one of `"interactive"`, `"quarto"`, or `"rscript"`.

```r
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
separate CSV file. Filenames are derived from sanitized group values --
converted to lowercase with spaces and special characters replaced by dashes.
Optionally writes a `manifest.csv` listing output files, group values, and
row counts.

```r
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
metadata drawn from the document's YAML header -- `title` to `kb_title`,
`description` to `kb_summary`, `categories` to `kb_keywords`.

```r
library(toolero)

generate_kb_xml(
  html_path  = "docs/analysis.html",
  output_dir = "exports"
)
```

When importing the resulting XML into the KB, check the
*Decode HTML entity in body content* option.

### `arborize()`

Renders a syntactic tree as a standalone PNG image using Quarto's Typst
engine. Accepts two input formats controlled by the `tree_notation` argument:

- `"simple"` (default) -- bracket notation string, e.g.
  `"[S [NP [Det the] [N cat]] [VP [V sat]]]"`. Uses the
  `@preview/syntree` Typst package.
- `"structured"` -- nested `tree()` call string for the
  `@preview/lingotree` Typst package. Supports per-node styling,
  movement arrows, and multi-dominant trees.

The `papersize` and `margin` arguments control how tightly the PNG is cropped
around the tree. Start with `papersize = "a6"` for simple trees and increase
to `"a5"` or `"a4"` for wider or deeper structures.

By default, a companion `.yaml` provenance file is written alongside the PNG
recording the tree string and all rendering arguments, making it easy to
reproduce or modify the render later.

```r
library(toolero)

# Simple bracket notation -- also writes np-tree.yaml
arborize(
  "[NP [Det the] [N cat]]",
  output    = "figures/np-tree.png",
  papersize = "a6"
)

# Wider tree
arborize(
  paste0(
    "[Aspectual Classes ",
    "[Statives [States]] ",
    "[Dynamic [Atelic [Activities]] ",
    "[Telic [Instantaneous [Achievements]] ",
    "[Durative [Accomplishments]]]]]"
  ),
  output    = "figures/aspectual-classes.png",
  papersize = "a4",
  dpi       = 600
)

# Structured notation using lingotree
arborize(
  "tree(
    tag: [VP],
    tree(tag: [DP], [every], [farmer]),
    [smiled]
  )",
  tree_notation = "structured",
  output        = "figures/vp-tree.png",
  papersize     = "a6"
)
```

Requires Quarto 1.4+ with Typst support and the `pdftools` package.
On first use, Typst will download the required package -- an internet
connection is needed.

## Related packages

toolero is one of three sibling packages:

- **toolero** -- research workflow toolkit (this package)
- [containr](https://github.com/erwinlares/containr) -- Docker containerization
- [curriculr](https://github.com/erwinlares/curriculr) -- data-driven CV generation

## Citation

To cite `toolero` in publications:

```r
citation("toolero")
```

## License

MIT (c) Erwin Lares
