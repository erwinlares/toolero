# toolero

<img src="man/figures/logo.png" align="right" height="139"/>

<!-- badges: start -->
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.19457647.svg)](https://doi.org/10.5281/zenodo.19457647)
[![R-CMD-check](https://github.com/erwinlares/toolero/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/erwinlares/toolero/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

`toolero` is an R package designed to help researchers implement best practices
for their coding projects. It provides a small set of opinionated, practical
functions that reduce friction at the start of a project and during day-to-day
data work.

## Installation

You can install `toolero` from [GitHub](https://github.com/erwinlares/toolero) with:
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
init_project("~/Documents/my-project")

# Add extra folders
init_project("~/Documents/my-project", extra_folders = c("notebooks", "presentations"))

# Skip renv and git
init_project("~/Documents/my-project", use_renv = FALSE, use_git = FALSE)
```

The default folder structure includes: `data/`, `data-raw/`, `R/`, `scripts/`,
`plots/`, `images/`, `results/`, and `docs/`.

### `read_clean_csv()`

Reads a CSV file and cleans the column names in one step, producing a
tidyverse-friendly tibble.
``` r
library(toolero)

data <- read_clean_csv("path/to/file.csv")

# Show column type messages
data <- read_clean_csv("path/to/file.csv", verbose = TRUE)
```

## Citation

To cite `toolero` in publications:
``` r
citation("toolero")
```

## License

MIT © Erwin Lares
