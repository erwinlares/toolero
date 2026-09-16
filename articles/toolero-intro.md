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

`toolero` is also the first package in *From the Notebook to the
Cluster*, a three-package family that covers the full arc from local
project setup to high-throughput computing: `toolero` organizes and
scaffolds, `containr` freezes the software environment into a container,
and `submitr` sends the work to CHTC and brings results back. This
vignette covers `toolero` on its own. You do not need the other two
packages to benefit from it, but a project started with `toolero` is
already most of the way to being containerizable and submittable when
that time comes.

`toolero` can optionally apply UW-Madison branding to a project’s Quarto
output – logo, header, footer, and stylesheet – but branding is opt-in
and off by default. If you are not at UW-Madison, or would rather use
your own look, the rest of the package works exactly the same way
without it.

------------------------------------------------------------------------

## Who is this for?

`toolero` is designed for researchers and analysts who:

- Work primarily in R and use RStudio as their IDE
- Write reports or analyses in Quarto
- Want consistent, reproducible project structure without having to
  think about it every time
- Split a dataset into pieces and apply the same analysis to each
- Need to record what an analysis produced, and whether each output
  write succeeded
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
    ├── data-raw/          # inputs as they arrived, never edited in place
    ├── data/              # analysis-ready data, produced from data-raw/
    ├── R/                 # code, including scripts derived from .qmd documents
    ├── scripts/           # hand-written, standalone utility scripts
    ├── output/
    │   ├── figures/       # generated visualizations
    │   └── tables/        # generated tables
    ├── reports/           # rendered .qmd/.html output meant to be shared
    └── _toolero.yml        # records the folder set and naming conventions

> **Why this structure?** The folder layout is opinionated but not
> arbitrary. Separating `data/` from `data-raw/` makes it clear which
> files are original and which have been processed. Keeping `R/`
> distinct from `scripts/` encourages moving reusable logic into
> functions over time: `R/` is where derived scripts land, whether from
> [`qmd_to_r()`](https://erwinlares.github.io/toolero/reference/qmd_to_r.md)
> or from the post-render purl hook, while `scripts/` is for utilities
> you write and maintain by hand.

Every folder
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
creates that is still empty when the call finishes also gets a zero-byte
`.gitkeep`, so the layout survives an opening git commit even before
anything has been written into it. One folder cannot be suppressed, by
`custom_folders` or by a `config` file: `R/`.
[`usethis::create_project()`](https://usethis.r-lib.org/reference/create_package.html)
creates it unconditionally, so it is present in every project regardless
of the folder set you asked for.

By default,
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
also sets up `renv` and `git`. This means the project is reproducible
and version-controlled from the first commit.

> **Why `renv` and `git` by default?** `renv` ensures that the packages
> your project depends on are recorded and reproducible. `git` provides
> a full history of changes. Both are much easier to set up at the start
> than to retrofit later.
> [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
> uses
> [`renv::scaffold()`](https://rstudio.github.io/renv/reference/scaffold.html)
> rather than
> [`renv::init()`](https://rstudio.github.io/renv/reference/init.html),
> so setting up `renv` in the new project does not disturb the R session
> you called it from. Nothing is snapshotted at creation time – a
> brand-new project has no code in it yet – so run
> [`renv::snapshot()`](https://rstudio.github.io/renv/reference/snapshot.html)
> yourself once the analysis exists and before containerizing.

If your project needs folders beyond the defaults, or you want to drop
one of them, `custom_folders` adds and removes without having to restate
the whole set. A `"-"` prefix removes a folder from the standard set:

``` r

init_project(
  path           = "~/Documents/my-project",
  custom_folders = c("notebooks", "presentations", "-output/figures")
)
```

For a layout that differs enough from the defaults that restating it on
every call gets tedious,
[`generate_project_config()`](https://erwinlares.github.io/toolero/reference/generate_project_config.md)
writes a skeleton YAML config you can edit once and reuse:

``` r

generate_project_config("linguistics-project.yml", path = "~")

init_project(
  path   = "~/Documents/my-project",
  config = "~/linguistics-project.yml"
)
```

Whichever route you take,
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
records the *resolved* folder set and naming conventions it ended up
with in `_toolero.yml` at the project root. Commit that file. It is what
lets
[`check_project()`](https://erwinlares.github.io/toolero/reference/check_project.md),
and later `containr` and `submitr`, know how your project is laid out
without being handed the same configuration again.

To apply UW-Madison branding assets to the project:

``` r

init_project(
  path     = "~/Documents/my-project",
  branding = "uw-madison"
)
```

This creates an `assets/` folder and populates it with `logo.png`,
`favicon.png`, `header.html`, `footer.html`, and `styles.css` under
UW-Madison RCI branding. Pass `branding = TRUE` instead for generic
placeholder assets under the same standardized names, or leave
`branding` at its default, `"none"`, to skip the `assets/` folder
entirely. All three modes are interchangeable from
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)’s
point of view, since it always looks for those five standardized
filenames.

### Adding a Quarto document with `create_qmd()`

Once the project exists,
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
adds a working Quarto document to it. `filename` is the one argument you
always have to supply; `path` defaults to the current directory. The
function has two modes controlled by `include_examples`, and several
optional features that can be mixed and matched.

#### With examples (the default)

When `include_examples = TRUE` (the default),
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
scaffolds a complete, runnable analysis project:

``` r

create_qmd("analysis.qmd", path = "~/Documents/my-project")
```

This creates:

- `analysis.qmd` – a Quarto document with a fully populated YAML header
  (including a `params:` block), a grouped summary, a scatterplot, and a
  results-saving section. Input resolution uses
  [`resolve_input_path()`](https://erwinlares.github.io/toolero/reference/resolve_input_path.md),
  so the document is ready to render immediately and works unchanged
  whether you run it interactively, render it with Quarto, or extract it
  to a script.
- `data-raw/sample.csv` – a subset of the Palmer Penguins dataset to
  develop against. The `params` block in the YAML header points at this
  file.
- `assets/logo.png` – a placeholder logo that reads “your logo goes
  here,” unless a logo already exists (for instance from
  `init_project(branding = )`), in which case it is left alone.

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
  "analysis.qmd",
  path             = "~/Documents/my-project",
  include_examples = FALSE
)
```

This creates a Quarto document with the YAML header (title, author,
format settings) and a setup chunk that loads
[`library(toolero)`](https://github.com/erwinlares/toolero). The body
has a single `## Introduction` heading and an HTML comment prompting you
to add your content. No `params` block, no analysis code, no references
to sample data. No `data-raw/` folder is created, and no placeholder
logo is placed in `assets/`. The document is a blank canvas with just
enough structure to render.

Use this mode when you already know what your analysis looks like and
don’t need the worked example as a starting point.

#### Custom styling

The `use_style` argument controls whether CSS and header/footer assets
are wired into the YAML. It works independently of `include_examples`:

``` r

# Blank document with UW branding (assumes init_project(branding = "uw-madison"))
create_qmd(
  "report.qmd",
  path             = "~/Documents/my-project",
  include_examples = FALSE,
  use_style        = TRUE
)

# Blank document with custom branding from a different directory
create_qmd(
  "report.qmd",
  path             = "~/Documents/my-project",
  include_examples = FALSE,
  use_style        = "my-branding/"
)
```

When `use_style = TRUE`, the function looks in `assets/` for files by
their standardized names – `styles.css`, `header.html`, `footer.html` –
and wires up whichever are present: `styles.css` as `css:`,
`header.html` as `include-before-body:`, `footer.html` as
`include-after-body:`. When `use_style` is a directory path, it looks
there instead. Any subset of the three may be present; only files that
exist are injected.

Styling assets themselves come from `init_project(branding = )`, not
from
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md).
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
only wires up what is already in `assets/`.

#### The purl hook

[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
can also scaffold a post-render hook that extracts R code from the
rendered document into a companion `.R` file on every render, kept in
step with the `.qmd` automatically. This is opt-in, via
`use_purl = TRUE`:

``` r

create_qmd(
  "analysis.qmd",
  path     = "~/Documents/my-project",
  use_purl = TRUE
)
```

Turning it on:

- Stamps the document’s own YAML header with `purl: true` (or
  `purl: false` when `use_purl = FALSE`, so a document can positively
  confirm it should be skipped rather than merely lacking an opinion).
- Scaffolds `R/purl.R`, which purls every document in the project whose
  own header carries `purl: true`.
- Wires `R/purl.R` into `_quarto.yml`’s post-render hook, creating
  `_quarto.yml` from the package template if it does not exist yet, or
  merging the hook into an existing file’s `project:` block if it does –
  unless that file already declares a `website`, `book`, or `manuscript`
  project, in which case the automatic wiring is skipped with a warning
  explaining how to add it by hand.

This is useful for sharing the analysis as a script, running it on a
remote cluster via `submitr`, or archiving the code independently of the
document. `use_purl` defaults to `FALSE`, so a call with no other
arguments creates a plain `.qmd` and nothing else.

#### Pre-populating the YAML header

The `yaml_data` argument accepts a path to a YAML file whose top-level
keys overwrite the corresponding keys in the template. Keys not present
in the file are left exactly as the template wrote them – including
their quoting, indentation, and any comments, since every header edit
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
makes is line-based rather than a parse-and-rewrite:

``` r

create_qmd(
  "analysis.qmd",
  path      = "~/Documents/my-project",
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

This works with both `include_examples = TRUE` and `FALSE`, and composes
with `use_style` and `use_purl`.

#### Summary of what gets created

| File | `include_examples = TRUE` | `include_examples = FALSE` |
|----|----|----|
| `analysis.qmd` | Full example with analysis blocks and `params` | Skeleton with YAML and empty body |
| `data-raw/sample.csv` | Yes | No |
| `assets/logo.png` | Yes, unless one already exists | No |
| `_quarto.yml` and `R/purl.R` | Only when `use_purl = TRUE` | Only when `use_purl = TRUE` |
| `purl:` stamp in the YAML header | Only when `use_purl` is supplied | Only when `use_purl` is supplied |
| CSS/header/footer in YAML | Only when `use_style` is set | Only when `use_style` is set |

## Working with data

These functions address common friction points in day-to-day data work,
and the split-apply pair scales an analysis from a single dataset to
many independent pieces. They are general-purpose utilities – useful in
any R project, not just ones set up with `toolero`.

### Reading and writing clean data: `read_clean_csv()` and `write_clean_csv()`

[`read_clean_csv()`](https://erwinlares.github.io/toolero/reference/read_clean_csv.md)
combines
[`readr::read_csv()`](https://readr.tidyverse.org/reference/read_delim.html),
[`janitor::clean_names()`](https://sfirke.github.io/janitor/reference/clean_names.html),
and optionally
[`tidyr::drop_na()`](https://tidyr.tidyverse.org/reference/drop_na.html)
into a single call. The goal is to get from a raw CSV to a clean,
analysis-ready tibble in one step.

``` r

data <- read_clean_csv(
  "data-raw/my-file.csv",
  na      = c("", "NA", "N/A", "."),
  drop_na = TRUE,
  summary = TRUE
)
```

Column names are automatically converted to lowercase with underscores.
The `na` argument lets you name additional missing-value codes beyond
the `readr` defaults. `drop_na` accepts `TRUE` (drop any incomplete
row), `FALSE` (keep everything, the default), or a character vector of
columns to check. `summary = TRUE` prints row and column counts, how
many names were cleaned, and how many values are missing.

[`write_clean_csv()`](https://erwinlares.github.io/toolero/reference/write_clean_csv.md)
is the natural counterpart, reinforcing the convention that `data-raw/`
holds original inputs and `data/` holds analysis-ready outputs. If the
data frame’s names are not already clean, it applies
[`janitor::clean_names()`](https://sfirke.github.io/janitor/reference/clean_names.html)
before writing and warns about the affected columns, so the output file
always has consistent names:

``` r

write_clean_csv(data, "data/clean.csv")
```

### Splitting and applying: `write_by_group()` and `run_by_group()`

When an analysis needs to run once per group – once per species, once
per site, once per participant –
[`write_by_group()`](https://erwinlares.github.io/toolero/reference/write_by_group.md)
and
[`run_by_group()`](https://erwinlares.github.io/toolero/reference/run_by_group.md)
form the split-apply pair at the heart of that workflow. Splitting and
applying are deliberately separate steps, so you can iterate on the
analysis function without re-splitting the data each time.

[`write_by_group()`](https://erwinlares.github.io/toolero/reference/write_by_group.md)
partitions a data frame by one or more grouping columns, writes one CSV
per group with sanitized filenames, and optionally writes a job manifest
recording each group’s value, row count, and file path:

``` r

write_by_group(
  data       = penguins,
  group_col  = "species",
  output_dir = "data/jobs",
  manifest   = TRUE
)
```

`group_col` also accepts more than one column, writing one file per
combination that actually appears in the data (`adelie--female.csv`, and
so on), and `prefix` prepends a namespace to every filename – useful
before a high-throughput run, where `submitr` reduces the manifest to
[`basename()`](https://rdrr.io/r/base/basename.html) and short group
names from two different datasets could otherwise collide in one flat
directory.

[`run_by_group()`](https://erwinlares.github.io/toolero/reference/run_by_group.md)
reads that manifest (or a named list of data frames already in memory),
applies your function to each subset, and assembles the results into a
single tibble:

``` r

summarise_species <- function(data) {
  dplyr::summarise(
    data,
    n            = dplyr::n(),
    mean_mass    = mean(body_mass_g, na.rm = TRUE),
    mean_flipper = mean(flipper_length_mm, na.rm = TRUE)
  )
}

results <- run_by_group(
  manifest = "data/jobs/manifest.csv",
  .f       = summarise_species
)
```

If `.f` returns a data frame, the results come back as one flat tibble
with a group-id column prepended; anything else – a model, a plot, a
file path – comes back as a nested tibble with a list-column. For
analyses that are slow or independent across groups, `workers` runs them
in parallel via `furrr`. A bare column name passed through `...`
(`x = flipper_length_mm`) works sequentially without any special
handling, but has to be moved inside `.f` to survive `workers > 1`,
since parallel execution has to serialize every argument to send it to a
worker session, and a symbol that only means something inside the data
has nothing to serialize.

### Recording what an analysis produced: `save_output()` and `generate_manifest()`

Once an analysis has results,
[`save_output()`](https://erwinlares.github.io/toolero/reference/save_output.md)
writes each object to disk via a function you supply, and appends a row
to a project-level accumulator recording the path, the object’s class,
the function used, and whether the write succeeded:

``` r

save_output(
  results,
  "output/results.rds",
  .f = saveRDS
)
```

At the end of the run,
[`generate_manifest()`](https://erwinlares.github.io/toolero/reference/generate_manifest.md)
reads that accumulator, collapses it to one row per output file, and
writes `output/project-manifest.json` – a record of what the analysis
actually produced, which is useful on its own and becomes essential once
a job is running unattended on a cluster.

``` r

generate_manifest(output_dir = "output")
```

### Auditing a project: `check_project()`

[`check_project()`](https://erwinlares.github.io/toolero/reference/check_project.md)
audits an existing project directory – one created by
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
or any other R project – against the expected folder structure, an
`.Rproj` file, `renv.lock`, git, a README, and a few other common
reproducibility checks. It reads the project’s own `_toolero.yml` when
one exists, so a customized project does not need to be handed the same
configuration again:

``` r

check_project()
```

------------------------------------------------------------------------

## Execution context: `detect_execution_context()` and `resolve_input_path()`

R code often needs to behave differently depending on where it is
running – interactively in RStudio, during a `quarto render`, or as a
batch `Rscript` job on a remote cluster.
[`detect_execution_context()`](https://erwinlares.github.io/toolero/reference/detect_execution_context.md)
identifies which of these three environments is active and returns one
of `"interactive"`, `"quarto"`, or `"rscript"`.

For the specific, recurring case of finding the input data file,
[`resolve_input_path()`](https://erwinlares.github.io/toolero/reference/resolve_input_path.md)
builds on it directly: it picks the branch that matches the current
context, checks that the result is usable, and explains what to fix when
it is not.

``` r

input_file <- resolve_input_path(
  interactive = "data-raw/sample.csv",
  quarto      = params$input_file,
  rscript     = commandArgs(trailingOnly = TRUE)[1]
)
```

Only the branch matching the current context is ever evaluated, so the
`params` reference above is safe even under `Rscript`, where `params`
does not exist at all. Arguments can also be omitted: the `rscript`
branch defaults to the first command line argument, and `interactive`
and `quarto` both fall back to the document’s own `params$input_file`,
so a document whose header declares `input_file` can call
[`resolve_input_path()`](https://erwinlares.github.io/toolero/reference/resolve_input_path.md)
with no arguments at all.

This pattern is built into the template scaffolded by
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md),
so you get it for free without having to write it yourself. See
[`vignette("detect-execution-context")`](https://erwinlares.github.io/toolero/articles/detect-execution-context.md)
for a more detailed treatment of the problem this solves and why it is
worth solving in one place.

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

## Syntactic trees: `arborize()`

Outside the general research workflow, `toolero` also ships
[`arborize()`](https://erwinlares.github.io/toolero/reference/arborize.md),
which renders a syntactic tree description to a standalone PNG via
Quarto’s Typst engine — useful for course handouts, papers, and slides
without a full LaTeX installation. It has its own vignette,
[`vignette("arborize")`](https://erwinlares.github.io/toolero/articles/arborize.md),
since the notation and sizing options deserve room of their own.

------------------------------------------------------------------------

## Quick reference

| Function | Brief description |
|----|----|
| [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md) | Creates a new RStudio project with a reproducible folder structure, `renv`, `git`, a README, and optional branding assets. Records the resolved structure in `_toolero.yml`. |
| [`generate_project_config()`](https://erwinlares.github.io/toolero/reference/generate_project_config.md) | Writes a skeleton YAML project configuration file, pre-filled with the standard folders and conventions, for projects whose layout should be reused or shared. |
| [`check_project()`](https://erwinlares.github.io/toolero/reference/check_project.md) | Audits an existing project against the expected folder structure and common reproducibility hygiene checks. |
| [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md) | Creates a Quarto document scaffold. Can generate a full worked example or a minimal skeleton, pre-fill YAML metadata, add styling, and opt into the purl post-render hook. |
| [`qmd_to_r()`](https://erwinlares.github.io/toolero/reference/qmd_to_r.md) | Extracts the R code from a rendered Quarto document into a standalone `.R` script. |
| [`read_clean_csv()`](https://erwinlares.github.io/toolero/reference/read_clean_csv.md) / [`write_clean_csv()`](https://erwinlares.github.io/toolero/reference/write_clean_csv.md) | Reads or writes a CSV with [`janitor::clean_names()`](https://sfirke.github.io/janitor/reference/clean_names.html) column names, optional missing-value handling, and an optional ingest summary. |
| [`write_by_group()`](https://erwinlares.github.io/toolero/reference/write_by_group.md) | Splits a data frame by one or more grouping columns and writes one CSV file per group, optionally with a job manifest. |
| [`run_by_group()`](https://erwinlares.github.io/toolero/reference/run_by_group.md) | Applies a function to each group from a job manifest or a named list, sequentially or in parallel. |
| [`save_output()`](https://erwinlares.github.io/toolero/reference/save_output.md) | Writes an object to disk via a user-supplied function and records the write in a project-level accumulator. |
| [`generate_manifest()`](https://erwinlares.github.io/toolero/reference/generate_manifest.md) | Reads the accumulator and writes a deduplicated `project-manifest.json` describing everything the analysis produced. |
| [`detect_execution_context()`](https://erwinlares.github.io/toolero/reference/detect_execution_context.md) | Detects whether code is running interactively, during `quarto render`, or as an `Rscript` job. |
| [`resolve_input_path()`](https://erwinlares.github.io/toolero/reference/resolve_input_path.md) | Resolves the input data path for the current execution context, and explains what went wrong when it cannot. |
| [`generate_kb_xml()`](https://erwinlares.github.io/toolero/reference/generate_kb_xml.md) | Converts a rendered Quarto HTML document into UW-Madison Knowledge Base-ready XML with embedded resources and metadata extracted from the source `.qmd`. |
| [`arborize()`](https://erwinlares.github.io/toolero/reference/arborize.md) | Renders a syntactic tree description as a standalone PNG image via Quarto’s Typst engine. |

------------------------------------------------------------------------

## Citation

If you use `toolero` in your work, please cite it:

``` r

citation("toolero")
```
