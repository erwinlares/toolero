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
impossible to rescue later, but it is genuinely hard. Collaborators
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
- writing one analysis that has to find its input data whether you are
  running chunks by hand, rendering the document, or running it as a
  script on a cluster;
- splitting data into independent pieces and applying an analysis
  function to each;
- preparing split data for parallel or high-throughput workflows;
- standardizing setup across multiple projects;
- recording what an analysis produced and whether each write succeeded;
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
toolero     organize, scaffold, split, apply, record
  └─ containr   freeze the software environment in a container
       └─ submitr    send the analysis to CHTC and retrieve results
```

The organizing idea behind the family is that good practices at each
stage make the next stage easier. A project structured with `toolero`,
with dependency tracking, a clean folder layout, and data split into
independent pieces, is already most of the way to being containerizable.
A containerized project is already most of the way to being submittable
to a high-throughput computing cluster. The family does not require you
to commit to the full arc upfront. Each package is useful on its own,
and you can adopt them one at a time as your project’s needs grow.

`toolero` does not require `containr`, and `containr` does not require
`submitr`. The dependencies run in one direction only: each package
prepares cleanly for the next, but none reaches backward.

What the later packages read, rather than guess, is recorded in the
project manifest.
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
writes `_toolero.yml` at the project root describing the folder set it
resolved and the naming conventions in force. Commit that file. It
describes the project, not the machine it was created on, and it is how
a customized project stays legible to
[`check_project()`](https://erwinlares.github.io/toolero/reference/check_project.md),
`containr`, and `submitr` without being handed the same configuration
again.

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
recorded outputs. It runs end to end against the sample data
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
copies in, and uses a temporary directory so you can try it without
writing to your Documents folder. The only extra requirement is `dplyr`,
for the analysis function in step 8.

``` r

library(toolero)

# tempfile() rather than a fixed name under tempdir(): it hands back a
# path that does not exist yet, so running this block twice in one
# session scaffolds a second project instead of colliding with the first.
project_dir <- tempfile("my-analysis-")

# 1. Create a project with sensible defaults.
#    renv and git are on by default and are what you want in a real
#    project. They are off here so the example runs quickly and without
#    prompting.
init_project(path = project_dir, use_renv = FALSE, use_git = FALSE)

# 2. Audit the project structure
check_project(path = project_dir)

# 3. Scaffold a reproducible Quarto analysis document. This also copies
#    the bundled sample data into data-raw/.
create_qmd(path = project_dir, filename = "analysis.qmd")

# 4. Extract the R code from the document into a standalone script.
#    R/ is where toolero expects derived scripts to live.
qmd_to_r(
  input  = file.path(project_dir, "analysis.qmd"),
  output = file.path(project_dir, "R", "analysis.R")
)

# 5. Read and clean the sample data
penguins <- read_clean_csv(
  file.path(project_dir, "data-raw", "sample.csv"),
  na      = c("", "NA", "N/A", "."),
  summary = TRUE
)

# 6. Write the cleaned data
write_clean_csv(penguins, file.path(project_dir, "data", "clean.csv"))

# 7. Split the data into per-group subsets, one file per species
write_by_group(
  penguins,
  group_col  = "species",
  output_dir = file.path(project_dir, "data", "jobs"),
  manifest   = TRUE
)

# 8. Define an analysis function and apply it to each subset
summarise_species <- function(data) {
  dplyr::summarise(
    data,
    n            = dplyr::n(),
    mean_mass    = mean(body_mass_g, na.rm = TRUE),
    mean_flipper = mean(flipper_length_mm, na.rm = TRUE)
  )
}

results <- run_by_group(
  manifest = file.path(project_dir, "data", "jobs", "manifest.csv"),
  .f       = summarise_species
)

# 9. Save outputs and record each write in the project accumulator.
#    output_dir is where the accumulator goes; it defaults to "output"
#    relative to the working directory, so it is given explicitly here.
save_output(
  results,
  file.path(project_dir, "output", "results.rds"),
  .f         = saveRDS,
  output_dir = file.path(project_dir, "output")
)

# 10. Write a project manifest summarizing what was produced
generate_manifest(output_dir = file.path(project_dir, "output"))
```

In a real project, replace `project_dir` with the path where you want
the project to live. The important idea is that `toolero` helps you
start with a structure that can grow: local analysis first, reproducible
execution later, and scalable computing when needed.

------------------------------------------------------------------------

## Quick reference

| Function | What it does |
|----|----|
| [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md) | Creates a new R project with a standard research-oriented folder structure and records that structure in `_toolero.yml` at the project root. Can set up `renv`, initialize `git`, customize folders via `custom_folders`, load a config file, optionally copy branding assets into `assets/` via the `branding` argument (`TRUE` for generic placeholders, `"uw-madison"` for RCI branding), create a README via `use_readme` (`README.md` by default, `"plain"` for `README.txt`, or `FALSE` to skip it), and, via `use_rprofile`, keep loading your own `~/.Rprofile` customizations in a project that renv would otherwise shadow them in. |
| [`generate_project_config()`](https://erwinlares.github.io/toolero/reference/generate_project_config.md) | Writes a skeleton YAML project configuration file pre-filled with the standard toolero folder structure and conventions. Edit to define a custom layout and pass to [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md) via `config`. Same schema, template and writer as the `_toolero.yml` a project carries. |
| [`check_project()`](https://erwinlares.github.io/toolero/reference/check_project.md) | Audits an existing project for common reproducibility scaffolding: the expected folders, an `.Rproj` file, `renv.lock` and whether it actually records anything, `.renvignore` entries that would hide your source from `renv`, git, README, `.gitignore`, the project manifest, stale purled `.R` scripts, and hidden files such as `.RData` or `.Rhistory`. Audits against the project’s own `_toolero.yml` when it has one. |
| [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md) | Scaffolds a Quarto document. Can create a full worked example or a blank skeleton, pre-populate YAML metadata via `header_defaults`, wire in custom styling from a standardized `assets/` folder, and (opt-in via `use_purl`, `FALSE` by default) stamp `purl: true`/`false` into the document’s header and set up a post-render purl hook, merged into an existing `_quarto.yml` where possible and skipped with a warning for website, book and manuscript projects. |
| [`generate_profile()`](https://erwinlares.github.io/toolero/reference/generate_profile.md) | Writes a YAML skeleton of author information and document formatting preferences, meant to be edited once and reused across projects via `create_qmd(header_defaults = )`. |
| [`qmd_to_r()`](https://erwinlares.github.io/toolero/reference/qmd_to_r.md) | Extracts R code chunks from a Quarto document into a standalone `.R` script, creating the output directory if it does not exist. Useful when the `.qmd` is the source of truth but a script is needed for batch execution or sharing. |
| [`read_clean_csv()`](https://erwinlares.github.io/toolero/reference/read_clean_csv.md) | Reads a CSV file, cleans column names, handles missing values, optionally drops incomplete rows, and can print a short ingest summary. |
| [`write_clean_csv()`](https://erwinlares.github.io/toolero/reference/write_clean_csv.md) | Writes a data frame to CSV with clean column names and command-line feedback. Reinforces the pattern of keeping raw inputs in `data-raw/` and analysis-ready outputs in `data/`. |
| [`write_by_group()`](https://erwinlares.github.io/toolero/reference/write_by_group.md) | Splits a data frame by one or more grouping columns and writes one CSV per group, optionally prefixed via `prefix`. Can also create a job manifest for parallel or high-throughput workflows. `output_dir` can be resolved from a project’s `_toolero.yml` via `config`. |
| [`run_by_group()`](https://erwinlares.github.io/toolero/reference/run_by_group.md) | Applies a function to each group subset and collects the results. Accepts a job manifest from [`write_by_group()`](https://erwinlares.github.io/toolero/reference/write_by_group.md) or a named list of data frames. Supports parallel execution and returns a flat tibble or a nested tibble depending on what the function returns. |
| [`save_output()`](https://erwinlares.github.io/toolero/reference/save_output.md) | Writes an object to disk via a user-supplied function and appends a row to the project accumulator recording the path, class, function used, and whether the write succeeded. `output_dir` can be resolved from a project’s `_toolero.yml` via `config`. |
| [`generate_manifest()`](https://erwinlares.github.io/toolero/reference/generate_manifest.md) | Reads the project accumulator, deduplicates by path, and writes `project-manifest.json` describing every artifact the analysis produced, along with the git commit checked out at the time (when available). |
| [`detect_execution_context()`](https://erwinlares.github.io/toolero/reference/detect_execution_context.md) | Returns `"interactive"`, `"quarto"`, or `"rscript"` so one codebase can adapt to local exploration, document rendering, or batch execution. |
| [`resolve_input_path()`](https://erwinlares.github.io/toolero/reference/resolve_input_path.md) | Resolves where the input data lives for the current execution context, and says what to fix when it cannot. The companion to [`detect_execution_context()`](https://erwinlares.github.io/toolero/reference/detect_execution_context.md) for the specific case of finding your data. |
| [`generate_kb_xml()`](https://erwinlares.github.io/toolero/reference/generate_kb_xml.md) | Converts a rendered Quarto HTML document into UW-Madison Knowledge Base importable XML with embedded resources and metadata derived from the source document. |
| [`generate_citation()`](https://erwinlares.github.io/toolero/reference/generate_citation.md) | Writes a `CITATION.cff` skeleton, optionally pulling author information from a profile written by [`generate_profile()`](https://erwinlares.github.io/toolero/reference/generate_profile.md). |
| [`generate_license()`](https://erwinlares.github.io/toolero/reference/generate_license.md) | Writes a plain-text `LICENSE` file from one of three common templates (`"MIT"`, `"CC0"`, `"GPL-3"`), with the copyright holder and year filled in. `"GPL-3"` links to the canonical full text rather than reproducing it. |
| [`generate_data_doc()`](https://erwinlares.github.io/toolero/reference/generate_data_doc.md) | Writes a Markdown documentation stub for a single dataset – source, date obtained, license and usage terms, collection method, a variables table, and known issues – with the dataset’s file name and today’s date pre-filled. |
| [`arborize()`](https://erwinlares.github.io/toolero/reference/arborize.md) | Renders syntactic trees as PNG images using Quarto’s Typst engine. Can also write a provenance YAML file so the tree image can be reproduced or modified later. |

------------------------------------------------------------------------

## Core workflow functions

### `init_project()`

Creates a new R project with a standard folder structure suited for
research workflows. Optionally sets up `renv` for dependency management
and `git` for version control, both on by default, because both matter.

The default structure follows conventions established by The Carpentries
and UW-Madison Libraries workshops: `data-raw/`, `data/`, `R/`,
`scripts/`, `output/figures/`, `output/tables/`, and `reports/`. `R/`
holds the `.R` script derived from your `.qmd` source, whether that
derivation comes from
[`qmd_to_r()`](https://erwinlares.github.io/toolero/reference/qmd_to_r.md)
or from the post-render hook `create_qmd(use_purl = TRUE)` scaffolds.
`scripts/` holds hand-written scripts you maintain yourself. The
distinction matters because downstream packages resolve the derived
script by convention.

The `custom_folders` argument lets you add folders or suppress defaults
without changing the standard set for other projects. A `"-"` prefix
removes a folder from the set that will be created; bare names add new
ones.

``` r

# Standard project
init_project(path = "~/Documents/my-project")

# Add a folder and suppress one from the standard set
init_project(
  path           = "~/Documents/my-project",
  custom_folders = c("models", "-output/figures")
)

# Drive the folder structure entirely from a config file
init_project(
  path   = "~/Documents/my-project",
  config = "~/linguistics-project.yml"
)
```

One folder cannot be suppressed, by a config or by `custom_folders`:
`R/`.
[`usethis::create_project()`](https://usethis.r-lib.org/reference/create_package.html)
creates it unconditionally, so it is present in every project
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
makes. A structure that leaves it out is honored everywhere else, so
`R/` is absent from `_toolero.yml`, gets no placeholder file, and is not
audited by
[`check_project()`](https://erwinlares.github.io/toolero/reference/check_project.md).
Only the directory itself is unavoidable.

For projects where the standard structure does not fit,
[`generate_project_config()`](https://erwinlares.github.io/toolero/reference/generate_project_config.md)
writes a skeleton YAML config pre-filled with the standard folders and
conventions. Edit the file to define your own layout and store it in
your home directory so it is easy to reuse across projects.

``` r

# Write a config skeleton to your home directory
generate_project_config("linguistics-project.yml", path = "~")
```

Every project
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
creates carries a `_toolero.yml` at its root recording the folder set it
resolved and the naming conventions in force. It records the *resolved*
structure, never the inputs that produced it, so a project built from a
`config`, one built with `custom_folders`, and one built from the
defaults all produce the same shape of file and nobody has to replay
anything to learn what the project looks like. Commit it.

Every folder
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
creates that is still empty when the call finishes also receives a
zero-byte `.gitkeep`. git tracks files rather than directories, so
without this a scaffolded structure survives nothing: the opening commit
carries the files at the project root and none of the layout, and a
collaborator cloning the repository gets a project with no folders in
it.

``` r

# Generic placeholder branding
init_project(path = "~/Documents/my-project", branding = TRUE)

# UW-Madison RCI branding
init_project(path = "~/Documents/my-project", branding = "uw-madison")
```

The `branding` argument controls whether an `assets/` folder is created
and populated. `branding = TRUE` copies in generic placeholder files
(`logo.png`, `favicon.png`, `header.html`, `footer.html`, `styles.css`).
`branding = "uw-madison"` copies UW-Madison RCI branding under the same
standardized names. Both modes produce identically named files, so
`create_qmd(use_style = TRUE)` works the same way regardless of which
branding mode was used. `branding = "none"` (the default) creates no
`assets/` folder.

The `use_readme` argument controls whether a README file is created at
the project root. `use_readme = TRUE` (the default) creates `README.md`
from toolero’s generalist README template, a short guide covering what a
README is, general best practices, and a recommended section structure
for documenting software, data, or both, with pointers to the Cornell
Data Services guides for further detail. `use_readme = "plain"` creates
`README.txt` with identical content; only the extension differs.
`use_readme = FALSE` skips the README entirely. If a README already
exists at the destination, in any capitalization and with any extension,
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
stops with an informative error rather than overwriting it.

``` r

# Skip the README
init_project(path = "~/Documents/my-project", use_readme = FALSE)

# Plain-text README instead of Markdown, same content, different extension
init_project(path = "~/Documents/my-project", use_readme = "plain")
```

When `use_renv = TRUE`,
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
calls
[`renv::scaffold()`](https://rstudio.github.io/renv/reference/scaffold.html)
rather than
[`renv::init()`](https://rstudio.github.io/renv/reference/init.html).
`init()` loads the newly created project into the *calling* R session,
repointing [`.libPaths()`](https://rdrr.io/r/base/libPaths.html) at a
library that is empty apart from `renv` itself, so every package you had
available disappears until you restart R. `scaffold()` builds the same
infrastructure and leaves your session alone.

Nothing is snapshotted at creation time, because a project that has just
been created has no code in it and there is nothing to discover. Take a
snapshot yourself once the analysis exists, and before containerizing:

``` r

renv::snapshot()
```

The `renv` lockfile is what `containr::generate_dockerfile()` reads to
containerize the project later. Starting with
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
means that step is already prepared, even if you never need it. If the
project uses branding assets and is later containerized, pass
`misc_file = "assets/"` to `containr::generate_dockerfile()` so the
styling files are copied into the image alongside the `.qmd`.

Setting up `renv` has a side effect worth knowing about: R reads exactly
one `.Rprofile` per session, and
[`renv::scaffold()`](https://rstudio.github.io/renv/reference/scaffold.html)’s
own `.Rprofile` (the one that activates the project) becomes that one,
so your personal `~/.Rprofile` – aliases, options, helper functions –
silently stops loading the moment a project is under `renv`.
`use_rprofile = TRUE` appends a guarded block to the project’s
`.Rprofile`, after renv’s own activation line, that sources
`~/.Rprofile` if it exists:

``` r

init_project(path = "~/Documents/my-project", use_rprofile = TRUE)
```

The check happens every time a session starts, not just once at
creation, so a `~/.Rprofile` you write or edit later is still picked up.
It defaults to `FALSE` because it works against `renv`’s own point: a
project that automatically re-sources your personal environment is no
longer fully isolated from it. The block is also written generically –
it sources whichever file is at `~/.Rprofile` for whoever opens the
project, not one person’s file baked in – so a collaborator who clones
the project gets the same behavior, for their own home directory, that
the project’s author chose.

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

Two of the checks are about `renv` specifically, and they are paired for
a reason. A lockfile that records nothing but `renv` itself is reported
only when the project also has `.R` or `.qmd` source files: a freshly
scaffolded project legitimately has an empty lockfile, but a project
with code in it and nothing in its lockfile is the state that produces a
container image which builds cleanly and then cannot run the analysis.
Separately, a `.renvignore` that excludes `.qmd` files is reported,
because in a project whose
[`library()`](https://rdrr.io/r/base/library.html) calls live in its
Quarto source, which is the arrangement this package recommends, that
entry hides the dependencies from the snapshot. Versions of
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
before v0.5.0 wrote such a file, so projects created by those versions
still carry one.

Which folders are audited depends on what the project declares.
Precedence is an explicit `config` argument first, then the project’s
own `_toolero.yml`, then the built-in standard set. A folder declared by
either of the first two and missing from disk is reported as a failure
rather than a warning: a declaration that is not met is a conformance
failure, whereas the standard set is a suggestion nobody signed up for.

Naming conventions are reported only when they differ from the defaults,
so a conventions row in the output always means something in this
project resolves differently from every other one.

[`check_project()`](https://erwinlares.github.io/toolero/reference/check_project.md)
also reports on stale purled scripts. Every `.qmd` whose header declares
`purl: true` (see
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)’s
`use_purl` argument below) gets its own row, comparing it against the
`.R` script `R/purl.R` is expected to have derived from it. A script
that is missing entirely, or older than the `.qmd` it was purled from,
is a `"warn"`: the `.qmd` is the source of truth, so an out-of-date `R/`
script means an edit was made and not yet re-rendered, and a container
or cluster job that bakes in that script would run the old analysis
without any error to say so. A document never opted into purl produces
no row.

README detection is case-insensitive and extension-agnostic: any file
whose stem matches `readme`, in any capitalization, counts regardless of
extension or the absence of one. `README.md`, `readme`, `Readme.pdf`,
and `README.tex` all pass.

``` r

# Audit the current project, against its own _toolero.yml if it has one
check_project()

# Audit against a specific config instead
check_project(config = "~/linguistics-project.yml")

# Access results programmatically
out <- check_project()
```

------------------------------------------------------------------------

### `create_qmd()`

Scaffolds a new Quarto document from a reproducible template with
optional sample data, custom styling, YAML pre-population, and, opt-in
via `use_purl`, a post-render hook that extracts R code from the
rendered document into a companion `.R` file automatically.

The function has two main motivations. First, it reduces repetitive
setup work. If you regularly create Quarto documents with the same
author information, institutional metadata, or preferred format
settings, the `header_defaults` argument lets you pre-populate the YAML
header from a personal configuration file instead of rebuilding the same
header by hand.
[`generate_profile()`](https://erwinlares.github.io/toolero/reference/generate_profile.md)
is the natural way to create that file: it scaffolds a personal
configuration template in your home directory, ready to fill in once and
reuse across every document you create.

Second, it helps reduce code drift, when you opt in. In a literate
programming workflow, the `.qmd` document can serve as the source of
truth: prose, code, results, and interpretation live together. With
`use_purl = TRUE`, the post-render hook derives the standalone `.R`
script from the document automatically, so you do not have to maintain a
separate script by hand. This pattern is discussed in more detail in the
post [From the Notebook to the Cluster. Part 1: Start with the
Document](https://connect.doit.wisc.edu/nb2cl-p1-the-document/).

Every edit
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
makes to a document’s YAML header is made line by line rather than by
parsing the header and writing it back out. Keys the edit does not touch
keep the template’s own quoting, indentation, comments and ordering, so
the document you open is the template as shipped plus the keys you asked
for.

**Arguments:**

- `filename` – name of the `.qmd` file. Must be supplied explicitly.
- `path` – directory where the document is created. Defaults to `"."`.
- `header_defaults` – path to a YAML file for pre-populating the header.
  The merge is applied key by key rather than as a wholesale
  replacement: when a top-level key holds a mapping (a nested set of
  `key: value` pairs, as `author:` typically does), the file’s mapping
  is merged into the template’s mapping one leaf at a time, so a config
  file that only sets `author: name:` does not clobber an
  `author: affiliation:` the template already supplied. A key whose
  value is a sequence (a YAML list, such as a list of keywords) is
  replaced wholesale rather than merged item by item. Keys the file does
  not mention are left exactly as the template wrote them. (This
  argument was named `yaml_data` before v0.6.0; the old name still works
  but is deprecated and will be removed in v0.7.0 – update to
  `header_defaults`.)
- `overwrite` – whether to overwrite existing files. Defaults to
  `FALSE`. Note two exceptions: `assets/logo.png` is always exempt from
  overwrite, so an existing logo is assumed to be deliberate branding
  and is never replaced by the generic placeholder; and `_quarto.yml` is
  never governed by `overwrite` at all, since when it is touched it is
  merged rather than replaced, and in some cases (see `use_purl` below)
  it is deliberately left untouched regardless of `overwrite`.
- `use_purl` – defaults to `FALSE`. When `TRUE`:
  - Stamps the document’s own YAML header with `purl: true` (or
    `purl: false` when `use_purl = FALSE`, so a document can positively
    confirm it should be skipped rather than merely lacking an opinion).
  - Ensures `R/purl.R` exists in `path`, subject to `overwrite` like any
    other scaffolded file. An existing `R/purl.R` is left in place
    unless `overwrite = TRUE`.
  - Wires `R/purl.R` into `_quarto.yml`’s `project: post-render:`,
    creating `_quarto.yml` from the package template if it does not
    exist yet, or merging the hook into an existing file’s `project:`
    block (preserving every other key) if it does, **unless** that
    existing `_quarto.yml` declares `project: type:` as `website`,
    `book`, or `manuscript`. Those three project types render many
    documents on every full build, and the person scaffolding one `.qmd`
    may not be thinking about the others, so automatic wiring is skipped
    with a warning explaining how to add it by hand. The warning also
    reports whether `R/purl.R` was created just then or was already
    present, since whoever reads it is about to point a hook at that
    script and needs to know which copy is sitting there.
  - `R/purl.R` itself only purls documents whose own header carries
    `purl: true`, and mirrors each document’s path under `R/` (so
    `posts/2026-08-04-giscus/index.qmd` purls to
    `R/posts/2026-08-04-giscus/index.R`, not a flattened `R/index.R`).
    Together, this means turning `use_purl` on for one document inside a
    larger project does not purl every other `.qmd` in it, and two
    documents that happen to share a filename in different directories,
    a directory-per-post convention for instance, do not overwrite each
    other’s output.
- `include_examples` – if `TRUE` (default), copies a sample dataset into
  `data-raw/`, a placeholder logo into `assets/` (skipped if a logo
  already exists), and uses a worked example template. If `FALSE`,
  creates a blank skeleton. The placeholder logo is also skipped,
  regardless of whether one already exists, when the project’s
  `_toolero.yml` declares a `folders` list that does not include
  `assets` – if the project was not set up to have an assets folder in
  the first place,
  [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
  does not create one just to drop a logo into it.
- `use_style` – controls custom styling. `FALSE` (default) produces
  plain Quarto output. `TRUE` scans `assets/` for `styles.css`,
  `header.html`, and `footer.html` by name and wires up whichever are
  present: `styles.css` as `css:`, `header.html` as
  `include-before-body:`, `footer.html` as `include-after-body:`. A
  directory path scans that directory instead, and the caller is
  responsible for populating it with files under those exact
  standardized names.

``` r

# Blank skeleton, no examples, no styling (use_purl = FALSE is the default)
create_qmd(path = "my-project", filename = "analysis.qmd",
           include_examples = FALSE)

# Full worked example with sample data and placeholder logo (default)
create_qmd(path = "my-project", filename = "analysis.qmd")

# Opt this document into purl: stamps purl: true, scaffolds R/purl.R, and
# wires up the _quarto.yml post-render hook (merged if the file already
# exists and is not a website, book or manuscript project)
create_qmd(path = "my-project", filename = "analysis.qmd", use_purl = TRUE)

# Blank document wired to branding assets in assets/
create_qmd(path = "my-project", filename = "report.qmd",
           include_examples = FALSE, use_style = TRUE)

# Blank document with custom branding from another directory
create_qmd(path = "my-project", filename = "report.qmd",
           include_examples = FALSE, use_style = "my-branding/")

# Pre-populate YAML from a personal config file
create_qmd(path = "my-project", filename = "analysis.qmd",
           header_defaults = "my-config.yml")
```

If `use_purl = TRUE` is used inside an existing website, book, or
manuscript project, `_quarto.yml` is left untouched and a warning names
what to add by hand: a `post-render: R/purl.R` entry under the
`project:` key. The document’s `purl: true` header stamp is written
either way, and `R/purl.R` is scaffolded either way. Only the automatic
`_quarto.yml` edit is skipped.

Both bundled templates set `embed-resources: true`. A non-self-contained
HTML depends on the `_files/` sidecar directory rendered beside it, and
nothing that moves these documents around knows about sidecars: an
archived cluster run brings back a folder, an emailed report is one
file, and a rendered document committed next to its analysis quietly
depends on a directory nobody thinks to copy. The cost of `true` is a
larger file; the cost of `false` is an artifact that works only on the
machine that made it.

------------------------------------------------------------------------

### `generate_profile()`

Scaffolds a personal configuration template – author name, affiliation,
ORCID, email, and a handful of common document format settings – meant
to be filled in once and reused as the `header_defaults` argument to
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
or the `profile` argument to
[`generate_citation()`](https://erwinlares.github.io/toolero/reference/generate_citation.md),
rather than retyping the same author block into every new document or
citation file.

``` r

generate_profile(filename = "toolero-profile.yml")
```

**Arguments:**

- `filename` – name of the file to write. Must be supplied explicitly.
- `path` – directory where the file is written. Defaults to
  [`fs::path_home()`](https://fs.r-lib.org/reference/path_expand.html)
  (the user’s home directory), not the working directory, since a
  personal profile is meant to live in one place and be reused across
  projects rather than be scoped to whichever project happens to be
  current when it is created.
- `overwrite` – whether to overwrite an existing file at the
  destination. Defaults to `FALSE`.

The written file has two sections: a personal information block
(`author:`, with `name:`, `affiliation:`, `orcid:`, and `email:`
sub-keys) and a document settings block (`format:` and related keys) for
the format defaults you find yourself setting the same way across
documents. Neither a phone number nor a mailing address placeholder is
included – those are not things
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
or
[`generate_citation()`](https://erwinlares.github.io/toolero/reference/generate_citation.md)
make use of, so the template does not ask for them.

Nothing about the filename or location is enforced beyond what you pass
in: you can keep more than one profile (a `personal.yml` and a
`work.yml`, say) and point different projects at whichever one applies.

------------------------------------------------------------------------

### `qmd_to_r()`

Extracts R code chunks from any `.qmd` file into a standalone `.R`
script. This is the direct counterpart to the purl hook in
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md),
and it works on any Quarto document regardless of how it was created.

The output path defaults to the same directory as the input with the
`.qmd` extension replaced by `.R`. Its parent directory is created if it
does not already exist, so writing into `R/` works whether or not the
project was scaffolded by
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md).
The `documentation` argument controls how much context is preserved in
the extracted script: chunk labels only (`1`, the default), full roxygen
blocks (`2`), or pure code with no comments (`0`).

``` r

# Default output: same directory, .R extension
qmd_to_r(input = "analysis.qmd")

# Explicit output path. R/ is the documented home for derived scripts.
qmd_to_r(
  input  = "analysis.qmd",
  output = "R/analysis.R"
)
```

[`qmd_to_r()`](https://erwinlares.github.io/toolero/reference/qmd_to_r.md)
needs the `knitr` package, which is a suggested rather than a required
dependency. Install it if you have not already.

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
handles the split. It partitions a data frame by one or more grouping
columns, writes one CSV per group with sanitized filenames, and
optionally produces a `manifest.csv` recording each group’s value, file
path, and row count. That job manifest is the input to
[`run_by_group()`](https://erwinlares.github.io/toolero/reference/run_by_group.md).
Rows with a missing value in any grouping column are dropped by default
(`drop_na = TRUE`), with a message reporting how many were dropped; set
`drop_na = FALSE` to instead treat missing values as their own group.

`output_dir` can be supplied explicitly, or resolved from a project’s
own `_toolero.yml` by passing its path as `config`:
[`write_by_group()`](https://erwinlares.github.io/toolero/reference/write_by_group.md)
reads the config’s `split_dir` convention (the folder
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
set aside for split-by-group output) and uses that when `output_dir` is
not supplied directly. An explicit `output_dir` always wins over
`config`; `config` only fills in what you did not already say. This is
opt-in – a project never scaffolded by
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md),
or a call that supplies `output_dir` directly, behaves exactly as it
always has.

Groups are written, and manifest rows recorded, in order of first
appearance in the data rather than in sort order. This is more than
cosmetic: `submitr` writes its `subdatasets.csv` in manifest order,
HTCondor assigns `ProcId` in that order, and log filenames are
reconstructed from position, so manifest row order is the mapping from a
job number back to a group.

[`run_by_group()`](https://erwinlares.github.io/toolero/reference/run_by_group.md)
handles the apply. It reads each subset from the manifest, calls your
function on each one, and assembles the results into a single tibble. If
your function returns a data frame, the output is automatically unnested
into a flat tibble with a group ID column prepended. If it returns
anything else, a model, a plot, a file path, the results come back as a
nested tibble with a list-column.

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

# Apply from disk via manifest, returning a flat tibble
results <- run_by_group(
  manifest = "data/jobs/manifest.csv",
  .f       = summarise_species
)

# Apply from memory via named list, same result, no disk reads
subsets <- split(penguins, penguins$species)

results <- run_by_group(
  groups = subsets,
  .f     = summarise_species
)
```

`group_col` also accepts more than one column name. Grouping by
`c("species", "sex")` writes one file per combination that actually
appears in the data, `adelie--female.csv`, `adelie--male.csv`, and so
on, rather than the full cross-product of possible values. The `--`
separator is load bearing: because sanitizing collapses any run of
non-alphanumeric characters to exactly one dash, a sanitized value can
contain a single `-` but never two consecutive ones, which is what
leaves `--` free to mark a column boundary unambiguously.

The job manifest has one schema regardless of how many grouping columns
were supplied: one column per grouping variable holding the raw value,
then `group_value` (the raw values joined with `" | "`), `n_rows`, and
`file_path`. Grouping on a single column produces the same shape, with
the grouping column’s value repeating `group_value` exactly. That
redundancy is deliberate, since one schema with a varying column count
is easier to read, validate and rely on than two schemas selected by how
many columns you happened to group on.

``` r

write_by_group(
  penguins,
  group_col  = c("species", "sex"),
  output_dir = "data/jobs",
  manifest   = TRUE
)
```

The `prefix` argument prepends a namespace to every output filename, so
`a.csv` becomes `data-a.csv` and `a--female.csv` becomes
`data-a--female.csv`. It is worth using before a high-throughput run:
`submitr::htc_gen_submit()` reduces the manifest to
[`basename()`](https://rdrr.io/r/base/basename.html), so subsets from
two datasets split on the same short column would otherwise land in one
flat directory on the access point and overwrite each other.

``` r

write_by_group(
  penguins,
  group_col  = "species",
  output_dir = "data/jobs",
  prefix     = "penguins",
  manifest   = TRUE
)
```

Anything else you pass to
[`run_by_group()`](https://erwinlares.github.io/toolero/reference/run_by_group.md)
is forwarded to your analysis function on every call. Ordinary values –
a number, a string, a logical, a file path – need nothing special. The
one case that does is a bare column name, such as
`x = flipper_length_mm`, since a symbol like that has no meaning until
it meets the data. A function accepting one has to capture it with
`{{ }}` rather than evaluate it, which is a property of how that
function is written rather than anything
[`run_by_group()`](https://erwinlares.github.io/toolero/reference/run_by_group.md)
asks for: calling it directly has the same requirement. Passing the
column name as a string instead, and indexing with `.data[[x]]` inside
the function, avoids the question entirely.

Bare column names do not survive `workers > 1`, because parallel
execution has to serialize every argument to send it to a worker session
and a symbol that only means something inside the data has nothing to
send.
[`run_by_group()`](https://erwinlares.github.io/toolero/reference/run_by_group.md)
says so directly if you try. Moving the column name inside the analysis
function, with a lambda, works in both modes.

For analyses that are slow or computationally independent across groups,
[`run_by_group()`](https://erwinlares.github.io/toolero/reference/run_by_group.md)
supports parallel execution via `furrr`. The `workers` argument controls
how many R sessions to use. The ceiling is
`max(1L, parallelly::availableCores() - 1L)`, which is environment-aware
and reserves one core for the main session. `workers = 1L` (the default)
or `workers = NULL` runs sequentially.

``` r

# Parallel execution using available cores
workers <- max(1L, parallelly::availableCores() - 1L)

results <- run_by_group(
  manifest = "data/jobs/manifest.csv",
  .f       = summarise_species,
  workers  = workers
)
```

The job manifest produced by
[`write_by_group()`](https://erwinlares.github.io/toolero/reference/write_by_group.md)
is also the input to `submitr::htc_gen_submit()` in multiple-job mode,
making this split-apply pattern the natural on-ramp to high-throughput
computing when local parallelism is not enough.

------------------------------------------------------------------------

### `save_output()` and `generate_manifest()`

These two functions form the record half of the toolero workflow. Once
an analysis has produced its results,
[`save_output()`](https://erwinlares.github.io/toolero/reference/save_output.md)
writes each object to disk and appends a row to a project-level
accumulator tracking what was saved, how, and whether the write
succeeded.
[`generate_manifest()`](https://erwinlares.github.io/toolero/reference/generate_manifest.md)
reads that accumulator at the end of the analysis and writes a
`project-manifest.json` describing every artifact the project produced.

This is the *project manifest*, a record of outputs from a computation
that has already happened. It is a different document from the *job
manifest*
[`write_by_group()`](https://erwinlares.github.io/toolero/reference/write_by_group.md)
produces, which lists inputs to a computation about to happen. The two
share a word and nothing else, which is why this one is named
`project-manifest.json` rather than `manifest.json`.

[`save_output()`](https://erwinlares.github.io/toolero/reference/save_output.md)
wraps any write function behind a narrowly-scoped
[`tryCatch()`](https://rdrr.io/r/base/conditions.html). A failed write
is recorded with `status = "failure"` and the caught error message
before the original condition is rethrown unmodified, so the manifest
captures what went wrong on an unattended run even if nothing else does.

``` r

# Save a model and record it
save_output(
  model,
  "output/model.rds",
  .f   = saveRDS,
  note = "Final model, trained on full dataset."
)

# Save a plot. ggsave() takes the filename first and the plot second,
# which is the reverse of the order save_output() passes them in, so it
# needs a wrapper. Writers that take the object first -- saveRDS(),
# write.csv(), write_clean_csv() -- can be passed directly.
save_output(
  my_plot,
  "output/figures/coefficients.png",
  .f     = \(object, file_path, ...) ggplot2::ggsave(file_path, object, ...),
  width  = 8,
  height = 5
)

# Write the project manifest at the end of the analysis
generate_manifest(output_dir = "output")
```

[`save_output()`](https://erwinlares.github.io/toolero/reference/save_output.md)
calls the writer as `.f(object, file_path, ...)`, so a writer whose own
signature puts the destination first needs a wrapper, as `ggsave()` does
above. The cost is that the accumulator records the `function_used`
column as `anonymous function: ...` rather than a clean name, which is a
small loss of provenance in exchange for the write working at all.

The accumulator at `output/accumulator.csv` is append-only and written
incrementally throughout the analysis. The manifest at
`output/project-manifest.json` is the deduplicated, end-of-run summary:
`execution_context` and `generated_at` recorded once at the top level,
followed by an `artifacts` array with one entry per output file. When an
analysis re-runs within a session and overwrites an earlier output, the
manifest keeps only the most recent write per path.

Like
[`write_by_group()`](https://erwinlares.github.io/toolero/reference/write_by_group.md),
both functions accept a `config` argument: a path to a project’s
`_toolero.yml`, from which `output_dir` is resolved (via the config’s
`output_dir` convention) when not supplied directly. An explicit
`output_dir` still wins, and a project without a config behaves exactly
as before.

[`generate_manifest()`](https://erwinlares.github.io/toolero/reference/generate_manifest.md)
also accepts a `git_root` argument (default `"."`) and records a
`commit` field in the manifest – the git commit checked out in
`git_root` at the moment the manifest was written, recorded once at the
top level alongside `execution_context` and `generated_at`. This is the
one piece of provenance package versions cannot supply: `renv.lock`
already records which package versions were in play, but nothing else
records which revision of the analysis script itself produced a given
set of outputs. `commit` is `null` when `git_root` is not a git
repository, has no commits yet, or `git` is not installed, so its
absence is informative rather than a failure.

A missing accumulator at manifest time is an error, since no
[`save_output()`](https://erwinlares.github.io/toolero/reference/save_output.md)
calls were ever recorded. An accumulator with no rows produces an empty
manifest with a warning, since that is a truthful result rather than a
setup mistake.

For unattended execution on CHTC where nobody is watching the job log in
real time, the recommended pattern is:

``` r

tryCatch(
  {
    # ... analysis code ...
    save_output(results, "output/results.rds", .f = saveRDS)
  },
  finally = try(generate_manifest(), silent = TRUE)
)
```

The [`try()`](https://rdrr.io/r/base/try.html) inside `finally` ensures
that a crash before the first
[`save_output()`](https://erwinlares.github.io/toolero/reference/save_output.md)
call, which leaves no accumulator on disk, does not replace the original
error with a manifest-not-found error in the job log.

**What holds still.** The accumulator’s column set is the contract
between these two functions and anything downstream that reads what an
analysis produced, `encapsulr::describe()` included. Those columns are
`file_path`, `r_class`, `timestamp`, `function_used`, `status`,
`error_message` and `note`, and a change to them gets a `NEWS.md` entry
and a deprecation cycle rather than a straight swap.
[`save_output()`](https://erwinlares.github.io/toolero/reference/save_output.md)
checks the header of an existing accumulator against that schema before
appending and aborts on a mismatch rather than writing misaligned rows.
The functions themselves are newer and may still move; the schema is
what to build against.

------------------------------------------------------------------------

### `detect_execution_context()` and `resolve_input_path()`

An analysis written in a `.qmd` runs in three places over its life: in
your console while you develop it, under `quarto render` when you
produce the document, and under `Rscript` when a cluster runs the
derived script. Each one finds its input data somewhere different.

[`detect_execution_context()`](https://erwinlares.github.io/toolero/reference/detect_execution_context.md)
identifies which of the three you are in and returns `"interactive"`,
`"quarto"`, or `"rscript"`. Use it directly for anything that varies by
context but is not about data.

``` r

# Progress output is useful at a console and only clutters a job log
if (detect_execution_context() == "rscript") {
  options(cli.progress_show_after = Inf)
}
```

For the data path specifically, use
[`resolve_input_path()`](https://erwinlares.github.io/toolero/reference/resolve_input_path.md).
It picks the branch, checks that the result is usable, and says what to
fix when it is not.

``` r

input_file <- resolve_input_path(
  interactive = "data-raw/sample.csv",
  quarto      = params$input_file,
  rscript     = commandArgs(trailingOnly = TRUE)[1]
)
```

Only the branch matching the current context is evaluated, so the
`params` reference is safe under `Rscript`, where `params` does not
exist at all.

The checking is the point. Each of those branches can quietly produce
something that is not a path. `commandArgs(trailingOnly = TRUE)[1]` is
`NA_character_` when no argument was passed, which is what you get from
a `submitr` single-mode job with no `data_files` set. `params` exists
only if the YAML header declares it, and `params$input_file` is `NULL`
if the block exists without that key. Without the check, all of these
surface one call later as a message about `NA` or `NULL` from whatever
tried to read the file, naming neither the context nor the fix, from a
job log on a machine you are not sitting at.

You can also leave the arguments off. The `rscript` branch defaults to
the first command line argument, and the other two fall back to the
document’s own `params$input_file`, which makes the YAML header the
single place the path is written rather than one place in the header and
another in a chunk that has to be kept in step with it.

``` r

input_file <- resolve_input_path()
```

Set `must_exist = FALSE` when the resolved value is a URL or anything
else that is not a local file.

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

### `generate_citation()`

Writes a `CITATION.cff` skeleton – the [Citation File
Format](https://citation-file-format.github.io/) GitHub and other tools
use to render a “Cite this repository” button and machine-readable
citation metadata – so a project’s citation file does not have to be
built by hand.

``` r

generate_citation(profile = "~/toolero-profile.yml")
```

**Arguments:**

- `filename` – name of the file to write. Defaults to `"CITATION.cff"`.
- `path` – directory where the file is written. Defaults to `"."`.
- `profile` – optional path to a profile written by
  [`generate_profile()`](https://erwinlares.github.io/toolero/reference/generate_profile.md)
  (or any YAML file with the same `author:` shape). When supplied, each
  author entry’s `name` is split into `given-names`/`family-names`, and
  `affiliation`, `orcid`, and `email` are carried over wherever present.
  When omitted, a single placeholder author is written instead.
- `overwrite` – whether to overwrite an existing file at the
  destination. Defaults to `FALSE`.

`title`, `version`, `repository-code`, `url`, and `license` are facts
about the project, not the person, so a profile has no way to supply
them and they are left as placeholders (some commented out) regardless
of whether `profile` is used. `date-released` is filled in with today’s
date.

The given-names/family-names split is done by breaking a profile
author’s `name` on its last space – right for the ordinary two-word
case, and wrong for some real names: multi-word family names,
single-word names, and family-name-first orderings all defeat it. Review
the generated file’s `given-names` and `family-names` fields before
relying on them, especially for names that do not follow that pattern.

If a supplied `profile` has no `author` field at all,
[`generate_citation()`](https://erwinlares.github.io/toolero/reference/generate_citation.md)
warns and falls back to the same placeholder author it would have
written with no `profile` supplied.

------------------------------------------------------------------------

### `generate_license()`

Writes a plain-text `LICENSE` file at a project’s root from one of a
small set of common license templates, with the copyright holder and
year filled in.

``` r

generate_license(license = "MIT", holder = "Jane Researcher")
```

**Arguments:**

- `license` – one of `"MIT"`, `"CC0"`, or `"GPL-3"`. Defaults to
  `"MIT"`.
- `holder` – the copyright holder, a person or an institution. Must be
  supplied explicitly; there is no default, since guessing it wrong is
  worse than asking.
- `year` – the copyright year. Defaults to the current year.
- `path` – directory in which to write the file. Defaults to `"."`.
- `overwrite` – whether to overwrite an existing `LICENSE` file at the
  same location. Defaults to `FALSE`.

`"MIT"` and `"CC0"` are both short enough to reproduce in full.
`"GPL-3"`’s full text runs to several hundred lines; rather than risk an
inaccurate transcription, `license = "GPL-3"` writes the notice the Free
Software Foundation itself recommends attaching to a program, together
with a link to the canonical full text.

This is different from how an R package normally carries a license – a
package’s `DESCRIPTION` declares `License: MIT + file LICENSE` and pairs
a two-line CRAN stub with the full text in `LICENSE.md`. The projects
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
scaffolds are research compendia, not packages, so
[`generate_license()`](https://erwinlares.github.io/toolero/reference/generate_license.md)
instead writes one self-contained file carrying the license text
directly, the way a plain GitHub repository does.

------------------------------------------------------------------------

### `generate_data_doc()`

Writes a Markdown documentation stub for a single dataset, with the
sections a data-management plan typically asks for: source, date
obtained, license and usage terms, collection method, a variables table,
and known issues. The dataset’s file name and today’s date are
pre-filled; everything else is left as a placeholder to complete by hand
– the same skeleton-you-complete-yourself approach
[`generate_citation()`](https://erwinlares.github.io/toolero/reference/generate_citation.md)
uses for `CITATION.cff`.

``` r

generate_data_doc("survey_responses.csv")
```

**Arguments:**

- `dataset` – the file name of the dataset this doc describes, e.g.
  `"survey_responses.csv"`. Used to name the output file (the extension
  is replaced with `.md`) and to fill in the doc’s title. Must be
  supplied explicitly; there is no reasonable default.
- `path` – directory in which to write the file. Defaults to `"data"`.
- `overwrite` – whether to overwrite an existing doc at the same
  location. Defaults to `FALSE`.

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

## toolero inside a container

An analysis scaffolded by
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
loads `toolero` in its setup chunk, and the script purled out of it
inherits that call. So a containerized `toolero` analysis needs
`toolero` inside the image. That is the design, and the alternative is
worse: researchers hand-rolling context detection and output recording
on an execute node. But it has two consequences worth stating rather
than discovering.

First, `toolero` has to be in `renv.lock`, which is the concrete reason
[`check_project()`](https://erwinlares.github.io/toolero/reference/check_project.md)
reports a lockfile that records nothing. Take a snapshot after the
analysis exists and before containerizing.

Second, it puts `toolero` on the critical path of every job. Four
functions run on the execute node,
[`detect_execution_context()`](https://erwinlares.github.io/toolero/reference/detect_execution_context.md),
[`resolve_input_path()`](https://erwinlares.github.io/toolero/reference/resolve_input_path.md),
[`save_output()`](https://erwinlares.github.io/toolero/reference/save_output.md)
and
[`generate_manifest()`](https://erwinlares.github.io/toolero/reference/generate_manifest.md),
and a change to their return values or file schemas changes the
behaviour of analyses inside images built against an older version. They
are treated as a stability surface accordingly.

------------------------------------------------------------------------

## Dependencies

`toolero` builds on a focused set of R packages for project setup, file
handling, data import, documentation, and workflow automation:

``` text
cli, fs, glue, janitor, jsonlite, lifecycle, parallelly, purrr, quarto,
readr, renv, rlang, rvest, tibble, tidyr, usethis, utils, withr, xml2, yaml
```

Some functions need a package that is suggested rather than required, so
that installing `toolero` does not drag in more than most users need:

``` text
knitr      required by qmd_to_r()
furrr      required by run_by_group() when workers > 1
future     required by run_by_group() when workers > 1
pdftools   required by arborize()
dplyr      used in the examples throughout this README
```

------------------------------------------------------------------------

## Related packages

`toolero` is the first step in a family of packages for reproducible
research workflows:

- **toolero** – organize and scaffold research projects
- [containr](https://github.com/erwinlares/containr) – containerize an R
  project
- [submitr](https://github.com/erwinlares/submitr) – submit
  containerized R jobs to CHTC and retrieve results

Each package can be used independently. The shared design goal is to
make good research-computing practices easier to adopt before a project
becomes difficult to change.

The folder names, path conventions, and shared vocabulary used
consistently across all three packages are collected in one place,
[CONVENTIONS.md](https://github.com/erwinlares/toolero/blob/main/CONVENTIONS.md),
which lives in this repository since `toolero` is where those
conventions are authored. `containr` and `submitr` link back to it
rather than repeating it.

------------------------------------------------------------------------

## Citation

``` r

citation("toolero")
```

## License

MIT © Erwin Lares
