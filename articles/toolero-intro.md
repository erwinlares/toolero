# 

The vignette needs updating in three areas: the function list is stale
(still shows only two functions), the content doesn’t reflect any of the
0.3.0 additions, and some of the “what’s next” items are now shipped.
Here’s the updated version:

```` markdown
---
title: "Getting started with toolero"
author: "Erwin Lares"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{Getting started with toolero}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---



## What is toolero?

`toolero` is a small, opinionated toolkit designed to make the first steps of
an R project faster and more consistent. It targets researchers and analysts
who want to spend less time on setup and more time on the work itself.

The package currently provides the following functions:

- `init_project()` — creates a new R project with a standard folder structure,
  and optionally initializes `renv` and `git`
- `read_clean_csv()` — reads a CSV file and cleans column names in one step
- `create_qmd()` — scaffolds a new Quarto document from a reproducible
  template, including sample data, UW-Madison branded assets, and an optional
  post-render `purl` hook
- `detect_execution_context()` — identifies whether code is running
  interactively, via `quarto render`, or via `Rscript`
- `write_by_group()` — splits a data frame by a grouping column and writes
  each group to a separate CSV file
- `generate_kb_xml()` — produces a UW-Madison Knowledge Base importable XML
  file from a rendered Quarto document

All functions are designed around a simple idea: the decisions you make at the
start of a project — how it is organized, how data is read in, how dependencies
are tracked — have an outsized effect on how maintainable and reproducible that
project turns out to be. `toolero` tries to make the right defaults easy to
reach for.

---

## Installation

You can install `toolero` from CRAN:


``` r
install.packages("toolero")
```

Or install the development version from GitHub:


``` r
pak::pak("erwinlares/toolero")
```

---

## Starting a project with `init_project()`

### The problem

Starting a new R project usually means the same manual steps every time:
create a folder, set up an RStudio project, create subdirectories for data and
scripts, initialize `renv`, initialize `git`. None of these steps is hard on
its own, but skipping any of them — especially early on — tends to create
friction later. A project without `renv` is harder to share. A project without
`git` is harder to recover. A project without a consistent folder structure is
harder to hand off.

### The solution

`init_project()` handles all of this in a single call:


``` r
library(toolero)

init_project(path = "~/Documents/my-project")
```

This creates a new RStudio project at the specified path with the following
folder structure already in place:

```
my-project/
├── data/         # input data
├── data-raw/     # original, unprocessed data
├── R/            # reusable functions
├── scripts/      # analysis scripts
├── plots/        # generated visualizations
├── images/       # static images and assets
├── results/      # processed outputs and tables
└── docs/         # notes, manuscripts, Quarto documents
```

> **Why this structure?** The folder layout is opinionated but not arbitrary.
> Separating `data/` from `data-raw/` makes it clear which files are original
> and which have been processed. Keeping `R/` distinct from `scripts/`
> encourages moving reusable logic into functions over time, which is a natural
> step toward more maintainable code.

By default, `init_project()` also initializes `renv` and `git` in the new
project. This means the project is reproducible and version-controlled from
the first commit.

> **Why `renv` and `git` by default?** `renv` ensures that the packages your
> project depends on are recorded and reproducible — someone else (or your
> future self) can restore the exact same environment. `git` provides a full
> history of changes, making it possible to recover from mistakes and understand
> how the project evolved. Both are much easier to set up at the start than to
> retrofit later.

### Adding extra folders

If your project needs folders beyond the defaults, pass them as a character
vector via `extra_folders`:


``` r
init_project(
  path          = "~/Documents/my-project",
  extra_folders = c("notebooks", "presentations")
)
```

### Opting out of renv or git

If you need to skip one or both:


``` r
init_project(
  path     = "~/Documents/my-project",
  use_renv = FALSE,
  use_git  = FALSE
)
```

> **When might you skip `renv` or `git`?** Skipping them is occasionally useful
> in teaching or demonstration contexts where the overhead of a full setup is
> unnecessary. For any project you plan to share, archive, or return to later,
> the defaults are strongly recommended.

---

## Reading data with `read_clean_csv()`

### The problem

Reading a CSV file into R is straightforward — until the column names come back
with spaces, mixed capitalization, or special characters. Cleaning them up is a
small but recurring friction point.

### The solution

`read_clean_csv()` combines `readr::read_csv()` and `janitor::clean_names()`
into a single call:


``` r
data <- read_clean_csv("data/my-file.csv")
```

Column names are automatically converted to lowercase with underscores —
consistent, predictable, and tidyverse-friendly. A column called
`First Name` becomes `first_name`. `Q1 Revenue ($)` becomes `q1_revenue`.

By default, column type messages from `readr` are suppressed to keep the
output clean. If you want to see them — useful when reading an unfamiliar
dataset for the first time — set `verbose = TRUE`:


``` r
data <- read_clean_csv("data/my-file.csv", verbose = TRUE)
```

> **Why suppress messages by default?** Column type messages are helpful when
> you are first exploring a dataset. In a script or document that runs
> repeatedly, they become noise. The `verbose` argument gives you control
> without requiring you to remember the `readr` option name.

---

## Scaffolding a Quarto document with `create_qmd()`

### The problem

Setting up a new Quarto document for a research workflow involves more than
creating a blank file. You need a consistent YAML header, sample data to
develop against, branded assets, and ideally a way to extract the R code from
the document once it is rendered.

### The solution

`create_qmd()` scaffolds a complete working environment in a single call:


``` r
create_qmd(path = "~/Documents/my-project", filename = "analysis.qmd")
```

This creates:

- `analysis.qmd` — a Quarto document with a fully populated YAML header,
  three-context input resolution via `detect_execution_context()`, and a
  sample analysis using the Palmer Penguins dataset
- `data/sample.csv` — sample data to develop against
- `assets/styles.css` and `assets/header.html` — UW-Madison RCI branding files
- `_quarto.yml` — a project file with a post-render hook that runs `purl.R`
- `purl.R` — a script that extracts R code from the rendered document into a
  companion `.R` file

### The post-render purl hook

By default (`use_purl = TRUE`), every time the document is rendered a clean
`.R` script is automatically extracted from the code chunks and saved
alongside the output. This is useful for sharing the analysis as a plain
script, running it on a remote cluster, or archiving the code independently
of the document.

To opt out:


``` r
create_qmd(path = "~/Documents/my-project", filename = "analysis.qmd",
           use_purl = FALSE)
```

### Pre-populating the YAML header

If you have author metadata in a YAML file, you can pre-populate the document
header automatically:


``` r
create_qmd(
  path      = "~/Documents/my-project",
  filename  = "analysis.qmd",
  yaml_data = "~/my-metadata.yml"
)
```

---

## Detecting the execution context with `detect_execution_context()`

R code often needs to behave differently depending on where it is running —
interactively in RStudio, during a `quarto render`, or as a batch `Rscript`
job on a remote cluster. `detect_execution_context()` identifies which of
these three environments is active and returns one of `"interactive"`,
`"quarto"`, or `"rscript"`.

The canonical use case is resolving input file paths portably:


``` r
context <- detect_execution_context()

input_file <- switch(context,
  interactive = "data/sample.csv",
  quarto      = params$input_file,
  rscript     = commandArgs(trailingOnly = TRUE)[1]
)
```

This pattern is built into the template scaffolded by `create_qmd()`.

---

## Splitting data by group with `write_by_group()`

When a data frame contains multiple groups that need to be written to separate
files — for instance, one CSV per species, site, or experimental condition —
`write_by_group()` handles the split and the write in a single call:


``` r
write_by_group(
  data       = penguins,
  group_col  = "species",
  output_dir = "results/by-species"
)
```

Output filenames are derived from the group values and sanitized for use as
file names — converted to lowercase, with spaces and special characters
replaced by dashes. A group called `Chinstrap` becomes `chinstrap.csv`.
`Palmer Penguins` would become `palmer-penguins.csv`.

To also write a manifest listing the output files, group values, and row
counts:


``` r
write_by_group(
  data       = penguins,
  group_col  = "species",
  output_dir = "results/by-species",
  manifest   = TRUE
)
```

---

## Exporting to the UW-Madison Knowledge Base with `generate_kb_xml()`

If your workflow includes publishing Quarto documents to the UW-Madison
Knowledge Base (KB), `generate_kb_xml()` automates the export step. It takes
a rendered HTML file, re-renders the source `.qmd` with all assets embedded,
extracts the body, and produces an XML file ready for KB import.


``` r
generate_kb_xml(
  html_path  = "docs/analysis.html",
  output_dir = "exports"
)
```

Metadata is drawn automatically from the `.qmd` YAML header:

- `title` → `kb_title`
- `description` → `kb_summary`
- `categories` → `kb_keywords`

> **When importing into the KB**, check the
> *Decode HTML entity in body content* option.

---

## Citation

If you use `toolero` in your work, please cite it:


``` r
citation("toolero")
```
````

The main changes from the original: updated the function list at the
top, added sections for
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md),
[`detect_execution_context()`](https://erwinlares.github.io/toolero/reference/detect_execution_context.md),
[`write_by_group()`](https://erwinlares.github.io/toolero/reference/write_by_group.md),
and
[`generate_kb_xml()`](https://erwinlares.github.io/toolero/reference/generate_kb_xml.md),
updated
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
examples to use `path =` instead of positional, and removed the “what’s
next” section since those items are now shipped.
