# toolero

## The problem with starting from scratch

Every research coding project begins with a blank slate and a set of
early decisions: where to put the data, how to name the scripts, whether
to track dependencies, and whether to use version control. These
decisions feel low-stakes in the moment. They rarely are. The cost
usually appears later, when the project needs to be shared, reviewed,
rerun, containerized, or moved to a larger computing system.

A project that starts with a flat folder, no dependency tracking, and
scripts that mix data loading, cleaning, modeling, and reporting is not
impossible to rescue later — but it is genuinely hard. Collaborators
cannot reproduce results because the package versions are unknown. The
analysis breaks when moved to a different machine. The manuscript
references outputs that no longer exist in the file system.

These are not exotic failure modes. They are the ordinary cost of
skipping setup decisions that feel optional at the start of a project.
The *From the Notebook to the Cluster* package family exists to make
those decisions easier to get right the first time. `toolero` is the
first step in that family.

`toolero` is a small, opinionated set of tools designed to make good
research workflow decisions easier to adopt. It does not impose a rigid
framework. It provides practical defaults for common research projects
and gets out of the way when you need to customize.

If you are new to research computing, `toolero` gives you a solid
starting point without requiring you to know in advance why each piece
matters. If you are experienced, it automates the setup work you would
otherwise do by hand at the start of every project.

------------------------------------------------------------------------

## When to use toolero

Use `toolero` when you are:

- starting a new research coding project;
- teaching students or collaborators a reproducible project structure;
- preparing an analysis that may later need to run outside your laptop;
- using Quarto as the source of truth for an analysis;
- reading and cleaning tabular data files at the start of a workflow;
- splitting data into independent pieces and applying an analysis
  function to each;
- preparing split data for parallel or high-throughput workflows;
- standardizing setup across multiple projects;
- publishing technical documentation that should stay synchronized with
  its source.

`toolero` is useful on its own. You do not need to containerize your
project or submit work to a cluster to benefit from better project
structure, cleaner inputs, literate analysis documents, and repeatable
workflows. That said, starting with `toolero` means your project is
already prepared for the next step when the time comes.

------------------------------------------------------------------------

## From the Notebook to the Cluster

`toolero` is the first package in *From the Notebook to the Cluster*, a
three-package family for reproducible research workflows. The family
covers the full arc from local project setup to high-throughput
computing:

``` text
toolero     organize, scaffold, split, apply
  └─ containr   freeze the software environment in a container
       └─ submitr    send the analysis to CHTC and retrieve results
```

The organizing idea behind the family is that good practices at each
stage make the next stage easier. A project structured with `toolero` —
with dependency tracking, a clean folder layout, and data split into
independent pieces — is already most of the way to being
containerizable. A containerized project is already most of the way to
being submittable to a high-throughput computing cluster. The family
does not require you to commit to the full arc upfront. Each package is
useful on its own, and you can adopt them one at a time as your
project’s needs grow.

`toolero` does not require `containr`, and `containr` does not require
`submitr`. The dependencies run in one direction only: each package
prepares cleanly for the next, but none reaches backward.

------------------------------------------------------------------------

## Installation

Install from CRAN:

``` r

install.packages("toolero")
```

Install the development version from GitHub:

``` r

# install.packages("pak")
pak::pak("erwinlares/toolero")
```

------------------------------------------------------------------------

## A first workflow

The functions below cover a common path from project creation to
analysis-ready data. This example uses a temporary directory so you can
try the workflow without writing to your Documents folder.

``` r

library(toolero)

project_dir <- file.path(tempdir(), "my-analysis")

# 1. Create a project with sensible defaults
init_project(path = project_dir)

# 2. Audit the project structure
check_project(path = project_dir)

# 3. Scaffold a reproducible Quarto analysis document
create_qmd(path = project_dir, filename = "analysis.qmd")

# 4. Extract the R code from the document into a standalone script
qmd_to_r(
  input  = file.path(project_dir, "analysis.qmd"),
  output = file.path(project_dir, "R", "analysis.R")
)

# 5. Read and clean a CSV file
data <- read_clean_csv(
  file.path(project_dir, "data-raw", "input.csv"),
  na      = c("", "NA", "N/A", "."),
  summary = TRUE
)

# 6. Write the cleaned data
write_clean_csv(data, file.path(project_dir, "data", "clean.csv"))

# 7. Split data into per-group subsets
write_by_group(
  data,
  group_col  = "species",
  output_dir = file.path(project_dir, "data", "jobs"),
  manifest   = TRUE
)

# 8. Apply an analysis function to each subset and collect the results
results <- run_by_group(
  manifest = file.path(project_dir, "data", "jobs", "manifest.csv"),
  .f       = my_analysis
)
```

In a real project, replace `project_dir` with the path where you want
the project to live. The important idea is that `toolero` helps you
start with a structure that can grow: local analysis first, reproducible
execution later, and scalable computing when needed.

------------------------------------------------------------------------

## Quick reference

| Function | What it does |
|----|----|
| [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md) | Creates a new R project with a standard research-oriented folder structure. Can initialize `renv`, initialize `git`, add extra folders, and optionally copy UW-Madison branding assets. |
| [`check_project()`](https://erwinlares.github.io/toolero/reference/check_project.md) | Audits an existing project for common reproducibility scaffolding, including expected folders, an `.Rproj` file, `renv.lock`, git, README, `.gitignore`, and hidden files such as `.RData` or `.Rhistory`. |
| [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md) | Scaffolds a Quarto document. Can create a full worked example or a blank skeleton, pre-populate YAML metadata, wire in custom styling, and set up a purl post-render hook. |
| [`qmd_to_r()`](https://erwinlares.github.io/toolero/reference/qmd_to_r.md) | Extracts R code chunks from a Quarto document into a standalone `.R` script. Useful when the `.qmd` is the source of truth but a script is needed for batch execution or sharing. |
| [`read_clean_csv()`](https://erwinlares.github.io/toolero/reference/read_clean_csv.md) | Reads a CSV file, cleans column names, handles missing values, optionally drops incomplete rows, and can print a short ingest summary. |
| [`write_clean_csv()`](https://erwinlares.github.io/toolero/reference/write_clean_csv.md) | Writes a data frame to CSV with clean column names and command-line feedback. Reinforces the pattern of keeping raw inputs in `data-raw/` and analysis-ready outputs in `data/`. |
| [`write_by_group()`](https://erwinlares.github.io/toolero/reference/write_by_group.md) | Splits a data frame by group and writes one CSV per group. Can also create a manifest for parallel or high-throughput workflows. |
| [`run_by_group()`](https://erwinlares.github.io/toolero/reference/run_by_group.md) | Applies a function to each group subset and collects the results. Accepts a manifest from [`write_by_group()`](https://erwinlares.github.io/toolero/reference/write_by_group.md) or a named list of data frames. Supports parallel execution and returns a flat tibble or a nested tibble depending on what the function returns. |
| [`detect_execution_context()`](https://erwinlares.github.io/toolero/reference/detect_execution_context.md) | Returns `"interactive"`, `"quarto"`, or `"rscript"` so one codebase can adapt to local exploration, document rendering, or batch execution. |
| [`generate_kb_xml()`](https://erwinlares.github.io/toolero/reference/generate_kb_xml.md) | Converts a rendered Quarto HTML document into UW-Madison Knowledge Base importable XML with embedded resources and metadata derived from the source document. |
| [`arborize()`](https://erwinlares.github.io/toolero/reference/arborize.md) | Renders syntactic trees as PNG images using Quarto’s Typst engine. Can also write a provenance YAML file so the tree image can be reproduced or modified later. |

------------------------------------------------------------------------

## Core workflow functions

### `init_project()`

Creates a new R project with a standard folder structure suited for
research workflows. Optionally initializes `renv` for dependency
management and `git` for version control — both on by default, because
both matter.

The default structure includes `data/`, `data-raw/`, `R/`, `scripts/`,
`plots/`, `images/`, `results/`, and `docs/`. Extra folders can be added
without disrupting the defaults.

``` r

# Standard project
init_project(path = "~/Documents/my-project")

# With additional folders
init_project(
  path          = "~/Documents/my-project",
  extra_folders = c("notebooks", "presentations")
)
```

The `renv` lockfile that
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
creates is also what `containr::generate_dockerfile()` reads to
containerize the project later. Starting with
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
means that step is already prepared, even if you never need it.

------------------------------------------------------------------------

### `check_project()`

Audits an existing project directory and reports whether it follows
toolero conventions. Useful both for projects initialized with
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
and for any existing R project you want to evaluate.

The report checks for the expected folder structure, an `.Rproj` file,
`renv.lock`, a git repository, a README, and a `.gitignore`. It also
notes the presence of hidden files like `.RData` and `.Rhistory` that
are common sources of reproducibility problems.

``` r

# Audit the current project
check_project()

# Return results as a tibble for programmatic use
issues <- check_project(error = FALSE)
```

------------------------------------------------------------------------

### `create_qmd()`

Scaffolds a new Quarto document from a reproducible template with
optional sample data, custom styling, YAML pre-population, and a
post-render hook that automatically extracts R code from the rendered
document into a companion `.R` file.

The function has two main motivations. First, it reduces repetitive
setup work. If you regularly create Quarto documents with the same
author information, institutional metadata, or preferred format
settings, the `yaml_data` argument lets you pre-populate the YAML header
from a personal configuration file instead of rebuilding the same header
by hand.

Second, it helps reduce code drift. In a literate programming workflow,
the `.qmd` document can serve as the source of truth: prose, code,
results, and interpretation live together. The post-render hook derives
the standalone `.R` script from the document automatically, so you do
not have to maintain a separate script by hand. This pattern is
discussed in more detail in the post [From the Notebook to the Cluster.
Part 1: Start with the
Document](https://connect.doit.wisc.edu/nb2cl-p1-the-document/).

**Arguments:**

- `filename` – name of the `.qmd` file. Must be supplied explicitly.
- `path` – directory where the document is created. Defaults to `"."`.
- `yaml_data` – path to a YAML file for pre-populating the header.
- `overwrite` – whether to overwrite existing files. Defaults to
  `FALSE`.
- `use_purl` – if `TRUE` (default), scaffolds `_quarto.yml` and
  `R/purl.R`.
- `include_examples` – if `TRUE` (default), copies a sample dataset into
  `data-raw/`, a placeholder logo into `assets/`, and uses a worked
  example template. If `FALSE`, creates a blank skeleton.
- `use_style` – controls custom styling. `FALSE` (default) produces
  plain Quarto output. `TRUE` scans `assets/` for `.css` and `.html`
  files and wires them into the YAML. A directory path scans that
  directory instead.

``` r

# Blank skeleton -- no examples, no styling, no purl hook
create_qmd(path = "my-project", filename = "analysis.qmd",
           include_examples = FALSE, use_purl = FALSE)

# Full worked example with sample data and placeholder logo (default)
create_qmd(path = "my-project", filename = "analysis.qmd")

# Blank document wired to branding assets in assets/
create_qmd(path = "my-project", filename = "report.qmd",
           include_examples = FALSE, use_style = TRUE)

# Blank document with custom branding from another directory
create_qmd(path = "my-project", filename = "report.qmd",
           include_examples = FALSE, use_style = "my-branding/")

# Pre-populate YAML from a personal config file
create_qmd(path = "my-project", filename = "analysis.qmd",
           yaml_data = "my-config.yml")
```

------------------------------------------------------------------------

### `qmd_to_r()`

Extracts R code chunks from any `.qmd` file into a standalone `.R`
script. This is the direct counterpart to the purl hook in
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
— it works on any Quarto document regardless of how it was created.

The output path defaults to the same directory as the input with the
`.qmd` extension replaced by `.R`. The `documentation` argument controls
how much context is preserved in the extracted script: chunk labels only
(`1`, the default), full roxygen blocks (`2`), or pure code with no
comments (`0`).

``` r

# Default output: same directory, .R extension
qmd_to_r(input = "analysis.qmd")

# Explicit output path
qmd_to_r(
  input  = "analysis.qmd",
  output = "scripts/analysis.R"
)
```

------------------------------------------------------------------------

### `read_clean_csv()`

Reads a CSV file into a tibble and cleans the column names in one step.
Column names become lowercase, spaces become underscores, and special
characters are removed. Beyond name cleaning, the function supports
explicit missing-value handling, selective row dropping, and an optional
ingest summary that surfaces common data problems immediately.

``` r

# Basic usage
data <- read_clean_csv("data-raw/input.csv")

# Explicit missing-value codes and ingest summary
data <- read_clean_csv(
  "data-raw/input.csv",
  na      = c("", "NA", "N/A", ".", "-999", "unknown"),
  summary = TRUE
)

# Drop rows missing in specific columns
data <- read_clean_csv(
  "data-raw/input.csv",
  drop_na = c("participant_id", "response_score")
)
```

------------------------------------------------------------------------

### `write_clean_csv()`

Writes a cleaned data frame to a CSV file with cli feedback. The natural
counterpart to
[`read_clean_csv()`](https://erwinlares.github.io/toolero/reference/read_clean_csv.md),
reinforcing the convention that `data-raw/` holds original inputs and
`data/` holds analysis-ready outputs.

If the data frame’s column names are not already clean,
[`write_clean_csv()`](https://erwinlares.github.io/toolero/reference/write_clean_csv.md)
applies
[`janitor::clean_names()`](https://sfirke.github.io/janitor/reference/clean_names.html)
before writing and warns you about the affected columns, so the output
file always has consistent names regardless of what was passed in.

``` r

data <- read_clean_csv("data-raw/input.csv")

write_clean_csv(data, "data/clean.csv")

# Overwrite an existing file
write_clean_csv(data, "data/clean.csv", overwrite = TRUE)
```

------------------------------------------------------------------------

### `write_by_group()` and `run_by_group()`

These two functions form the split-apply pair at the heart of toolero’s
workflow support. The idea is simple: split the data once, then apply an
analysis function to each piece and collect the results. The split and
the apply are deliberately separate steps so you can iterate on the
analysis function without re-splitting the data each time.

[`write_by_group()`](https://erwinlares.github.io/toolero/reference/write_by_group.md)
handles the split. It partitions a data frame by a grouping column,
writes one CSV per group with sanitized filenames, and optionally
produces a `manifest.csv` that records each group’s name, file path, and
row count. That manifest is the input to
[`run_by_group()`](https://erwinlares.github.io/toolero/reference/run_by_group.md).

[`run_by_group()`](https://erwinlares.github.io/toolero/reference/run_by_group.md)
handles the apply. It reads each subset from the manifest, calls your
function on each one, and assembles the results into a single tibble. If
your function returns a data frame, the output is automatically unnested
into a flat tibble with a group ID column prepended. If it returns
anything else — a model, a plot, a file path — the results come back as
a nested tibble with a list-column.

``` r

sample_path <- system.file("templates", "sample.csv", package = "toolero")
penguins    <- read_clean_csv(sample_path)

# Split to disk
write_by_group(
  penguins,
  group_col  = "species",
  output_dir = "data/jobs",
  manifest   = TRUE
)

# Define an analysis function
summarise_species <- function(data) {
  dplyr::summarise(data,
    n            = dplyr::n(),
    mean_mass    = mean(body_mass_g, na.rm = TRUE),
    mean_flipper = mean(flipper_length_mm, na.rm = TRUE)
  )
}

# Apply from disk via manifest -- returns a flat tibble
results <- run_by_group(
  manifest = "data/jobs/manifest.csv",
  .f       = summarise_species
)

# Apply from memory via named list -- same result, no disk reads
subsets <- split(penguins, penguins$species)

results <- run_by_group(
  groups = subsets,
  .f     = summarise_species
)
```

For analyses that are slow or computationally independent across groups,
[`run_by_group()`](https://erwinlares.github.io/toolero/reference/run_by_group.md)
supports parallel execution via `furrr`. The `workers` argument controls
how many R sessions to use. The ceiling is
`parallel::detectCores(logical = FALSE) - 1L`, which reserves one core
for the main session.

``` r

# Parallel execution across 3 workers
results <- run_by_group(
  manifest = "data/jobs/manifest.csv",
  .f       = summarise_species,
  workers  = 3L
)
```

The manifest produced by
[`write_by_group()`](https://erwinlares.github.io/toolero/reference/write_by_group.md)
is also the input to `submitr::htc_gen_submit()` in multiple-job mode,
making this split-apply pattern the natural on-ramp to high-throughput
computing when local parallelism is not enough.

------------------------------------------------------------------------

### `detect_execution_context()`

Identifies which of three environments the code is currently running in
— an interactive R session, a `quarto render` call, or a plain `Rscript`
invocation — and returns `"interactive"`, `"quarto"`, or `"rscript"`.
Useful for writing code that resolves input file paths correctly across
all three contexts without maintaining separate versions.

``` r

context <- detect_execution_context()

input_file <- switch(context,
  interactive = "data/sample.csv",
  quarto      = params$input_file,
  rscript     = commandArgs(trailingOnly = TRUE)[1]
)
```

------------------------------------------------------------------------

## Documentation and communication utilities

### `generate_kb_xml()`

Produces a UW-Madison Knowledge Base importable XML file from a rendered
Quarto document. Write and maintain the guide in Quarto, then generate
the KB-ready XML from that source. The Quarto document remains the
maintained version and the XML becomes a derived artifact, reducing
documentation drift.

``` r

generate_kb_xml(
  html_path  = "docs/analysis.html",
  output_dir = "exports"
)
```

When importing the resulting XML into the KB, check the *Decode HTML
entity in body content* option.

------------------------------------------------------------------------

### `arborize()`

Renders a syntactic tree as a standalone PNG image using Quarto’s Typst
engine. Accepts bracket notation for simple trees or structured notation
for trees requiring movement arrows and per-node styling. A provenance
`.yaml` file is written alongside the PNG by default, recording the tree
string and render settings so the image can be reproduced or modified
later.

``` r

# Simple bracket notation
arborize(
  "[NP [Det the] [N cat]]",
  output    = "figures/np-tree.png",
  papersize = "a6"
)
```

The `papersize` argument controls how tightly the image is cropped
around the tree. Use `"a6"` or `"a7"` for small trees, `"a5"` (the
default) for medium trees, and `"a4"` or `"a3"` for wide or deep trees.
Requires Quarto 1.4+ with Typst support and the `pdftools` package.

------------------------------------------------------------------------

## Dependencies

`toolero` builds on a focused set of R packages for project setup, file
handling, data import, documentation, and workflow automation:

``` text
cli, fs, glue, janitor, purrr, readr, renv, tibble, tidyr, usethis,
yaml, rlang, rvest, xml2, quarto, withr, lifecycle
```

------------------------------------------------------------------------

## Related packages

`toolero` is the first step in a family of packages for reproducible
research workflows:

- **toolero** — organize and scaffold research projects
- [containr](https://github.com/erwinlares/containr) — containerize an R
  project
- [submitr](https://github.com/erwinlares/submitr) — submit
  containerized R jobs to CHTC and retrieve results

Each package can be used independently. The shared design goal is to
make good research-computing practices easier to adopt before a project
becomes difficult to change.

------------------------------------------------------------------------

## Citation

``` r

citation("toolero")
```

## License

MIT © Erwin Lares
