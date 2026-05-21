# Getting started with toolero

![toolero hex sticker](figures/logo.png)

## Background and motivation

`toolero` grew out of a recurring observation made while teaching and
supporting researchers at UW-Madison: the habits that make a project
reproducible, shareable, and maintainable are easiest to adopt at the
very beginning — and hardest to retrofit once a project is already
underway.

The package is heavily influenced by the workflows taught in workshops
run by [The Carpentries](https://carpentries.org/) and the [UW-Madison
Libraries](https://www.library.wisc.edu/). Those workshops emphasize
consistent project organization, version control, and reproducible data
practices as foundational skills — not advanced topics. `toolero` tries
to operationalize those principles into a small set of functions that
reduce the friction of doing the right thing from the start.

The theming and branding support in `toolero` is specifically tailored
to UW-Madison’s Research Computing and Instrumentation (RCI) unit, whose
Quarto-based reporting templates are baked into the package as defaults.
If you are not at UW-Madison, the branding files are optional — the rest
of the package works independently of them.

------------------------------------------------------------------------

## Who is this for?

`toolero` is designed for researchers and analysts who:

- Work primarily in R and use RStudio as their IDE
- Write reports or analyses in Quarto
- Want consistent, reproducible project structure without having to
  think about it every time
- May need to publish content to the UW-Madison Knowledge Base

The package is intentionally small. It does not try to be comprehensive.
It tries to make the right defaults easy to reach for from the first
line of code.

------------------------------------------------------------------------

## Installation

You can install `toolero` from CRAN:

``` r

install.packages("toolero")
```

Or install the development version from GitHub:

``` r

pak::pak("erwinlares/toolero")
```

------------------------------------------------------------------------

## Project setup: `init_project()` and `create_qmd()`

These two functions are designed to be used together, in order.
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
creates the scaffold;
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
populates it with a working Quarto document.

### Starting with `init_project()`

Starting a new R project usually means the same manual steps every time:
create a folder, set up an RStudio project, create subdirectories for
data and scripts, initialize `renv`, initialize `git`. None of these
steps is hard on its own, but skipping any of them — especially early on
— tends to create friction later.

[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
handles all of this in a single call:

``` r

library(toolero)

init_project(path = "~/Documents/my-project")
```

This creates a new RStudio project at the specified path with the
following folder structure already in place:

    my-project/
    ├── data/         # input data
    ├── data-raw/     # original, unprocessed data
    ├── R/            # reusable functions
    ├── scripts/      # analysis scripts
    ├── plots/        # generated visualizations
    ├── images/       # static images and assets
    ├── results/      # processed outputs and tables
    └── docs/         # notes, manuscripts, Quarto documents

> **Why this structure?** The folder layout is opinionated but not
> arbitrary. Separating `data/` from `data-raw/` makes it clear which
> files are original and which have been processed. Keeping `R/`
> distinct from `scripts/` encourages moving reusable logic into
> functions over time, which is a natural step toward more maintainable
> code.

By default,
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
also initializes `renv` and `git`. This means the project is
reproducible and version-controlled from the first commit.

> **Why `renv` and `git` by default?** `renv` ensures that the packages
> your project depends on are recorded and reproducible. `git` provides
> a full history of changes. Both are much easier to set up at the start
> than to retrofit later.

If your project needs folders beyond the defaults:

``` r

init_project(
  path          = "~/Documents/my-project",
  extra_folders = c("notebooks", "presentations")
)
```

To apply UW-Madison RCI branding assets to the project:

``` r

init_project(
  path        = "~/Documents/my-project",
  uw_branding = TRUE
)
```

This creates an `assets/` folder and populates it with `styles.css`,
`header.html`, and `rci-banner.png` — the same assets used in the Quarto
template scaffolded by
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md).

### Adding a Quarto document with `create_qmd()`

Once the project exists,
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
adds a working Quarto document to it. The function has two modes
controlled by `include_examples`, and several optional features that can
be mixed and matched.

#### With examples (the default)

When `include_examples = TRUE` (the default),
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
scaffolds a complete, runnable analysis project:

``` r

create_qmd(path = "~/Documents/my-project", filename = "analysis.qmd")
```

This creates:

- `analysis.qmd` – a Quarto document with a fully populated YAML header,
  three-context input resolution via
  [`detect_execution_context()`](https://erwinlares.github.io/toolero/reference/detect_execution_context.md),
  a grouped summary, a scatterplot, and a results-saving section. The
  document is ready to render immediately.
- `data-raw/sample.csv` – a subset of the Palmer Penguins dataset to
  develop against. The template references this file in the `params`
  block of the YAML header.
- `assets/logo.png` – a placeholder logo that reads “your logo goes
  here.” Replace it with your own branding when you’re ready.
- `_quarto.yml` – a project file with a post-render hook that runs
  `purl.R`
- `R/purl.R` – extracts R code from the rendered document into a
  companion `.R` file automatically on every render

The idea is that you can render the document as-is, see results, and
then progressively replace the sample analysis with your own. The sample
data, the analysis blocks, and the results-saving pattern are all
working examples you can study before modifying.

#### Without examples

When `include_examples = FALSE`,
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
creates a minimal skeleton with no sample data and no pre-filled
analysis:

``` r

create_qmd(
  path             = "~/Documents/my-project",
  filename         = "analysis.qmd",
  include_examples = FALSE
)
```

This creates:

- `analysis.qmd` – a Quarto document with the YAML header (title,
  author, format settings) and a setup chunk that loads
  [`library(toolero)`](https://github.com/erwinlares/toolero). The body
  has a single `## Introduction` heading and an HTML comment prompting
  you to add your content. No `params` block, no analysis code, no
  references to sample data.
- `_quarto.yml` and `R/purl.R` – the purl hook is included by default
  regardless of `include_examples`

No `data-raw/` folder is created. No `sample.csv` is copied. No
placeholder logo is placed in `assets/`. The document is a blank canvas
with just enough structure to render.

Use this mode when you already know what your analysis looks like and
don’t need the worked example as a starting point.

#### Custom styling

The `use_style` argument controls whether CSS and header assets are
wired into the YAML. It works independently of `include_examples`:

``` r

# Blank document with UW branding (assumes init_project(uw_branding = TRUE) was called)
create_qmd(
  path             = "~/Documents/my-project",
  filename         = "report.qmd",
  include_examples = FALSE,
  use_style        = TRUE
)

# Blank document with custom branding from a different directory
create_qmd(
  path             = "~/Documents/my-project",
  filename         = "report.qmd",
  include_examples = FALSE,
  use_style        = "my-branding/"
)
```

When `use_style = TRUE`, the function scans `assets/` for `.css` and
`.html` files and adds them to the YAML (`css:` and
`include-before-body:` respectively). When `use_style` is a directory
path, it scans that directory instead. If the directory contains
multiple `.css` or `.html` files, the function errors and asks you to
specify which one via `yaml_data`.

Styling is managed by `init_project(uw_branding = TRUE)`, which copies
the UW-Madison RCI branding files into `assets/`. The
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
function does not copy style assets itself – it only wires up what’s
already there.

#### The purl hook

By default,
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
scaffolds a post-render hook that extracts R code from the rendered
document into a companion `.R` file:

- `_quarto.yml` – contains the `post-render: ["Rscript R/purl.R"]`
  directive
- `R/purl.R` – scans the project root for `.qmd` files and runs
  [`knitr::purl()`](https://rdrr.io/pkg/knitr/man/knit.html) on each one

The hook runs automatically on every `quarto render`, so the `.R` file
always reflects the current state of the `.qmd`. This is useful for
sharing the analysis as a script, running it on a remote cluster via
`submitr`, or archiving the code independently of the document.

Set `use_purl = FALSE` to skip the hook if you don’t need the `.R`
companion:

``` r

create_qmd(
  path     = "~/Documents/my-project",
  filename = "notes.qmd",
  use_purl = FALSE,
  include_examples = FALSE
)
```

#### Pre-populating the YAML header

The `yaml_data` argument accepts a path to a YAML file whose keys
overwrite the corresponding placeholders in the template. Keys not
present in the file are left as-is:

``` r

create_qmd(
  path      = "~/Documents/my-project",
  filename  = "analysis.qmd",
  yaml_data = "~/my-metadata.yml"
)
```

Where `my-metadata.yml` might look like:

``` yaml
title: "My Analysis"
author:
  - name: "Your Name"
    affiliation: "UW-Madison"
    email: "you@wisc.edu"
```

This works with both `include_examples = TRUE` and `FALSE`. When
combined with `use_style`, the YAML substitution runs after the style
injection, so `yaml_data` can override any auto-generated keys if
needed.

#### Summary of what gets created

| File | `include_examples = TRUE` | `include_examples = FALSE` |
|----|----|----|
| `analysis.qmd` | Full example with analysis blocks and `params` | Skeleton with YAML and empty body |
| `data-raw/sample.csv` | Yes | No |
| `assets/logo.png` | Yes | No |
| `_quarto.yml` | Yes (when `use_purl = TRUE`) | Yes (when `use_purl = TRUE`) |
| `R/purl.R` | Yes (when `use_purl = TRUE`) | Yes (when `use_purl = TRUE`) |
| CSS/header in YAML | Only when `use_style` is set | Only when `use_style` is set |

## Working with data: `read_clean_csv()` and `write_by_group()`

These two functions address common friction points in day-to-day data
work. They are general-purpose utilities — useful in any R project, not
just ones set up with `toolero`.

### Reading data with `read_clean_csv()`

[`read_clean_csv()`](https://erwinlares.github.io/toolero/reference/read_clean_csv.md)
combines
[`readr::read_csv()`](https://readr.tidyverse.org/reference/read_delim.html),
[`janitor::clean_names()`](https://sfirke.github.io/janitor/reference/clean_names.html),
and optionally
[`tidyr::drop_na()`](https://tidyr.tidyverse.org/reference/drop_na.html)
into a single call. The goal is to get from a raw CSV to a clean,
analysis-ready tibble in one step.

The simplest call reads the file and standardizes column names:

``` r

data <- read_clean_csv("data/my-file.csv")
```

Column names are automatically converted to lowercase with underscores –
consistent, predictable, and tidyverse-friendly. A column called
`First Name` becomes `first_name`. `Q1 Revenue ($)` becomes
`q1_revenue`.

#### Handling missing values

By default,
[`read_clean_csv()`](https://erwinlares.github.io/toolero/reference/read_clean_csv.md)
treats empty strings and `"NA"` as missing – the same behavior as
[`readr::read_csv()`](https://readr.tidyverse.org/reference/read_delim.html).
If your data uses other conventions for missing values, pass them via
the `na` argument:

``` r

# Treat dots, dashes, and -999 as missing in addition to blanks and "NA"
data <- read_clean_csv("data/my-file.csv", na = c("", "NA", "N/A", ".", "-999"))
```

#### Dropping rows with missing values

The `drop_na` argument controls whether incomplete rows are removed
after reading. It accepts three forms:

``` r

# Keep all rows, including those with missing values (default)
data <- read_clean_csv("data/my-file.csv", drop_na = FALSE)

# Drop any row that has a missing value in any column
data <- read_clean_csv("data/my-file.csv", drop_na = TRUE)

# Drop rows only where specific columns are missing
data <- read_clean_csv("data/my-file.csv", drop_na = c("bill_length_mm", "sex"))
```

When rows are dropped, a message reports how many were removed and how
many remain. This makes the data cleaning step visible in your console
output rather than happening silently.

#### Ingest summary

Set `summary = TRUE` to print a brief report after reading: row and
column counts, how many column names were cleaned, and the total number
of missing values. The summary reflects the final state of the tibble
after any `drop_na` action:

``` r

data <- read_clean_csv("data/my-file.csv", summary = TRUE)
```

#### Seeing column type messages

By default, the column type messages from `readr` are suppressed to keep
the console clean. Set `verbose = TRUE` to see them – useful when
debugging unexpected column types:

``` r

data <- read_clean_csv("data/my-file.csv", verbose = TRUE)
```

#### Combining arguments

The arguments compose naturally. A common pattern for a first look at a
new dataset combines custom missing value codes, row dropping, and the
ingest summary:

``` r

data <- read_clean_csv(
  "data/my-file.csv",
  na      = c("", "NA", "N/A", "."),
  drop_na = TRUE,
  summary = TRUE
)
```

#### Passing arguments through to `readr`

Any additional arguments are forwarded to
[`readr::read_csv()`](https://readr.tidyverse.org/reference/read_delim.html)
via `...`. This means you can use `col_types` to force column types,
`skip` to skip header rows, or `locale` to handle non-standard decimal
separators:

``` r

# Force a column to character instead of letting readr guess
data <- read_clean_csv("data/my-file.csv", col_types = cols(zip_code = col_character()))

# Skip the first two rows (e.g. metadata rows before the header)
data <- read_clean_csv("data/my-file.csv", skip = 2)

# Handle European-style decimals (comma as decimal separator)
data <- read_clean_csv("data/my-file.csv", locale = locale(decimal_mark = ","))
```

### Splitting data by group with `write_by_group()`

When a data frame contains multiple groups that need to be written to
separate files,
[`write_by_group()`](https://erwinlares.github.io/toolero/reference/write_by_group.md)
handles the split and the write in a single call:

``` r

write_by_group(
  data       = penguins,
  group_col  = "species",
  output_dir = "results/by-species"
)
```

Output filenames are derived from the group values and sanitized for use
as file names — converted to lowercase with spaces and special
characters replaced by dashes. A group called `Chinstrap` becomes
`chinstrap.csv`. `Palmer Penguins` would become `palmer-penguins.csv`.

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

------------------------------------------------------------------------

## Execution context: `detect_execution_context()`

R code often needs to behave differently depending on where it is
running — interactively in RStudio, during a `quarto render`, or as a
batch `Rscript` job on a remote cluster.
[`detect_execution_context()`](https://erwinlares.github.io/toolero/reference/detect_execution_context.md)
identifies which of these three environments is active and returns one
of `"interactive"`, `"quarto"`, or `"rscript"`.

The canonical use case is resolving input file paths portably:

``` r

context <- detect_execution_context()

input_file <- switch(context,
  interactive = "data/sample.csv",
  quarto      = params$input_file,
  rscript     = commandArgs(trailingOnly = TRUE)[1]
)
```

This pattern is built into the template scaffolded by
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md),
so you get it for free without having to write it yourself.

------------------------------------------------------------------------

## Knowledge Base export: `generate_kb_xml()`

> **This section is relevant only if you publish content to the
> UW-Madison Knowledge Base.** If you do not, you can safely skip it.

The UW-Madison Knowledge Base requires content to be submitted as XML
with all visual assets embedded in the HTML body.
[`generate_kb_xml()`](https://erwinlares.github.io/toolero/reference/generate_kb_xml.md)
automates this process entirely.

``` r

generate_kb_xml(
  html_path  = "docs/analysis.html",
  output_dir = "exports"
)
```

The function:

1.  Infers the source `.qmd` from the HTML path (or accepts it
    explicitly via `qmd_path`)
2.  Re-renders the document with `embed-resources: true` so all CSS,
    images, and JavaScript are self-contained
3.  Extracts metadata from the `.qmd` YAML header — `title` →
    `kb_title`, `description` → `kb_summary`, `categories` →
    `kb_keywords`
4.  Produces a `.xml` file ready for direct KB import

This is why the `description` and `categories` fields in the
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
template matter — they flow through automatically into the KB article
metadata without any extra work.

> **When importing into the KB**, check the *Decode HTML entity in body
> content* option.

------------------------------------------------------------------------

## Citation

If you use `toolero` in your work, please cite it:

``` r

citation("toolero")
```
