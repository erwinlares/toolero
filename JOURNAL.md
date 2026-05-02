# toolero – Development Journal

------------------------------------------------------------------------

## Session 1 — Pre-documentation (v0.1.0 through v0.3.0)

### What toolero is

toolero is an R package designed to help researchers implement best
practices for their coding projects. It provides a small set of
opinionated, practical functions that reduce friction at the start of a
project and during day-to-day data work. It is the foundational package
in a three-package suite alongside containr (Docker containerization)
and curriculr (data-driven CV generation).

toolero is on CRAN at v0.3.0. It was developed prior to the formal
journaling practice established during curriculr development. This
journal captures the accumulated design decisions and evolution of the
package retroactively, then continues forward in real time from v0.4.0.

### v0.1.0 — Initial release

The initial release shipped one function:
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md).
Its job is to create a new R project at a given path with a standard
folder structure suited for research workflows. It optionally
initializes renv for package management and git for version control.

The default folder structure: `data/`, `data-raw/`, `R/`, `scripts/`,
`plots/`, `images/`, `results/`, `docs/`.

The philosophy behind
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
is the same one that runs through all of toolero: reduce the friction of
starting a new project correctly so that best practices become the path
of least resistance rather than an extra step.

### v0.1.1 — UW branding

Added `uw_branding` argument to
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md).
When `TRUE`, creates an `assets/` folder in the new project and
populates it with UW-Madison RCI branding files: `styles.css`,
`header.html`, `rci-banner.png`. This reflects toolero’s origin as an
internal tool for UW-Madison Research Computing Infrastructure workshops
and consultations.

### v0.2.0 — Quarto scaffolding and execution context detection

Three new functions added.

[`detect_execution_context()`](https://erwinlares.github.io/toolero/reference/detect_execution_context.md)
identifies which of three environments the code is currently running in:
an interactive R session, a `quarto render` call, or a plain `Rscript`
invocation. Returns one of `"interactive"`, `"quarto"`, or `"rscript"`.
This is useful for writing code that resolves input file paths correctly
across all three contexts – a persistent pain point for researchers who
run the same script interactively, as part of a Quarto document, and on
an HPC cluster.

[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
scaffolds a new Quarto document from a reproducible template. Ships with
a sample dataset (Palmer Penguins), UW-Madison branded assets, and
three-context input resolution via
[`detect_execution_context()`](https://erwinlares.github.io/toolero/reference/detect_execution_context.md).
Optionally pre-populates the YAML header from a user-supplied YAML
config file.

[`write_by_group()`](https://erwinlares.github.io/toolero/reference/write_by_group.md)
splits a data frame by a single grouping column and writes each group to
a separate CSV file. Filenames are derived from sanitized group values.
Optionally writes a `manifest.csv`.

Breaking changes in v0.2.0: -
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
path is now required, no default -
[`write_by_group()`](https://erwinlares.github.io/toolero/reference/write_by_group.md)
output_dir is now required, no default -
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
open now defaults to FALSE

### v0.3.0 — KB XML export, purl hook, API refinements

[`generate_kb_xml()`](https://erwinlares.github.io/toolero/reference/generate_kb_xml.md)
produces UW-Madison Knowledge Base importable XML files from rendered
Quarto documents. Extracts metadata from the `.qmd` YAML header (title,
description, categories) and re-renders with embedded resources for
self-contained import. Addresses a specific operational need at
UW-Madison RCI.

[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
purl hook – added `use_purl` argument (default `TRUE`) that scaffolds a
`_quarto.yml` post-render hook and a `purl.R` script for extracting R
code from rendered documents into `R/`. The purl script uses
[`fs::dir_ls()`](https://fs.r-lib.org/reference/dir_ls.html) glob scan
rather than the `QUARTO_DOCUMENT_PATH` environment variable, which
proved unreliable across different Quarto invocation methods.

Breaking changes in v0.3.0: -
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md):
`filename` is now the first argument and has no default -
[`write_by_group()`](https://erwinlares.github.io/toolero/reference/write_by_group.md):
sanitized filenames now use dash separators instead of underscores -
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md):
`file_path` argument renamed to `path`

------------------------------------------------------------------------

## Session 2 — 2026-04-30 (v0.4.0 development)

### What we set out to do

Add
[`arborize()`](https://erwinlares.github.io/toolero/reference/arborize.md)
to toolero – a function for rendering syntactic trees as PNG images
using Quarto’s Typst engine. The function emerged from a need to migrate
linguistics documents from LaTeX + tikz/forest to Quarto + Typst without
losing the ability to produce standalone tree figures.

### Background: the LaTeX tree problem

The original workflow used LaTeX packages `gb4e`/`linguex`,
`forest`/`tikz-qtree`, and `tikz` in combination. These are mature but
carry significant dependency burden. The question was whether Typst
could replace this workflow for standalone tree figure production.
Assessment: yes for PNG figures embedded in other documents; LaTeX
remains pragmatic for full linguistic papers with cross-referenced
examples.

### Decision: arborize() as a toolero function

The function fits toolero better than curriculr – toolero is the general
research workflow toolkit and rendering a standalone figure from a
string is exactly the kind of utility it provides.

### Two rendering backends

Two Typst packages exist for linguistic trees:

`@preview/syntree:0.2.1` (simple notation) – takes bracket notation
string. Compact, familiar to linguists, simpler interface. Version 0.2.0
was broken on Typst 0.12+ due to the `style()` function being removed.
Version 0.2.1 fixes this.

`@preview/lingotree:1.0.0` (structured notation) – takes nested `tree()`
function calls. More powerful: supports per-node styling, movement
arrows, multi-dominant trees. Released November 2025, compatible with
current Typst.

The `tree_notation` argument controls which backend is used: -
`"simple"` – bracket notation string, uses syntree 0.2.1 -
`"structured"` – nested tree() calls string, uses lingotree 1.0.0

The user provides the complete tree string in the appropriate format.
arborize() wraps it in the correct Typst scaffolding.

### Decision: no recursive bracket-to-lingotree parser

The lingotree backend does not require arborize() to parse bracket
notation and convert it to nested tree() calls. The user is responsible
for providing the correct string format. This keeps arborize() simple.

### The pipeline

arborize() performs six steps: 1. Validates inputs and resolves the
Typst package from tree_notation 2. Builds a minimal .qmd document via
.build_arborize_qmd() 3. Writes the document inside
withr::with_tempdir() for automatic cleanup 4. quarto::quarto_render()
produces an intermediate PDF via Typst 5. pdftools::pdf_convert()
converts the PDF to PNG 6. PNG bytes are read into memory before temp
dir is deleted, then written to the output path 7. If provenance = TRUE,
.write_arborize_provenance() writes a .yaml file

### The provenance argument

`provenance = TRUE` (default) writes a companion `.yaml` file alongside
the PNG recording: tree string, tree_notation, typst_package, dpi,
papersize, margin, rendered_by, rendered_at, output path. This makes
renders reproducible and modifiable without hunting for the original
tree string.

The parameter name `provenance` was chosen over `save_source`,
`keep_source`, or `write_source` because it is the most meaningful name
in context – it records the provenance of the image, matching the
DATA-PROVENANCE.md convention established elsewhere in toolero.

A `rearborize()` function was considered and rejected for v0.4.0. The
re-render pattern (read yaml, call arborize() with recovered arguments)
is only five lines and does not justify an exported function. Deferred
pending evidence of demand.

### papersize and margin: crop control

The `papersize` and `margin` arguments determine how tightly the PNG is
cropped around the tree. The key insight: `papersize` should match the
tree’s complexity, not default blindly to `"a5"`. Practical guidance: -
`"a6"` or `"a7"` for simple trees (2-4 nodes) - `"a5"` for medium trees
(default) - `"a4"` for wide or deep trees - `"a3"` for very wide trees

`margin` provides buffer around the tree. Default `"0.5cm"` works for
most cases. This guidance is documented in both the arborize() @details
and the vignette.

### The builder/printer split

[`.build_arborize_qmd()`](https://erwinlares.github.io/toolero/reference/dot-build_arborize_qmd.md)
returns a character string (testable without Quarto).
[`.write_arborize_provenance()`](https://erwinlares.github.io/toolero/reference/dot-write_arborize_provenance.md)
writes the YAML file (testable without Quarto).
[`arborize()`](https://erwinlares.github.io/toolero/reference/arborize.md)
is the renderer that calls both and produces the file.

This mirrors the pattern established in curriculr for
`cv_render_section()`.

### Character escaping findings

Simple notation (syntree): tree string goes inside a Typst string
literal delimited by double quotes. Double quotes inside the string must
be escaped. The gsub() call: `gsub('"', '\\\\"', tree, fixed = TRUE)`.

To match the escaped result in tests:
`grepl('\\\\"cat\\\\"', result, fixed = TRUE)`. Four backslashes in the
R pattern = two literal backslashes in the string.

Structured notation (lingotree): tree string goes directly into Typst
code, not inside a string literal. No escaping needed. User bears syntax
responsibility.

General principle: when user data crosses into a quoted string literal
in another language, escaping is required. When inserted as raw code, no
escaping but user bears syntax responsibility.

### Typst package version fix

Initial implementation used `@preview/syntree:0.2.0` which fails on
current Typst with `error: unknown variable: style`. The `style()`
function was removed in Typst 0.12. Version 0.2.1 (released February 19,
2025) fixes this.

### Function naming history

- create_syntree() – original name, wrong verb (create implies
  persistence)
- render_syntree() – accurate but pipeline-y
- arborize() – final choice

arborize() was chosen because it is unexpected, precise, and memorable.
To arborize means to form a tree-like structure. The mild
discoverability concern is addressed by strong roxygen documentation.

### Test suite

- .build_arborize_qmd() tests: covers both backends and shared behavior,
  no Quarto required, runs everywhere
- .write_arborize_provenance() tests: file creation, field contents,
  filename matching, invisible return – no Quarto required
- arborize() input validation: type errors, empty string, length \> 1,
  NA, existing file, invalid notation, missing pdftools, invalid
  tree_notation
- arborize() provenance: provenance = FALSE suppresses yaml, provenance
  = TRUE writes yaml with correct fields
- arborize() full pipeline: 4 tests (3 simple, 1 structured) – all
  skip_on_ci() and skip_on_cran()

Path normalization fix in pipeline tests: withr::local_tempfile()
produces paths with // while fs::path_abs() normalizes to /. Use
normalizePath() on both sides before comparing.

### Vignette: arborize.Rmd

A full vignette was written covering: - Motivation: the LaTeX tree
problem and why a PNG-based solution helps - Two backends: syntree vs
lingotree, when to use each - Crop control: papersize and margin
guidance with an ISO paper size table - Examples: simple NP, clausal
tree, aspectual classes, print-quality, lingotree structured notation,
suppressing provenance - Provenance file structure and the manual
re-render pattern - Embedding in documents - Argument reference table -
References to Typst packages

The vignette uses eval = FALSE globally (arborize() calls never execute
during build), with individual knitr::include_graphics() chunks using
eval = TRUE and out.width for display control. PNGs are pre-rendered and
committed to vignettes/figures/.

### Other v0.4.0 changes

- Palmer Penguins credit: @details in create_qmd.R, comment in
  inst/templates/example.qmd, inst/extdata/DATA-PROVENANCE.md
- R/toolero-package.R added (required by usethis::use_lifecycle())
- Lifecycle badge: stable (toolero is on CRAN, API stable)
- Codecov badge and test-coverage GitHub Action added
- JOURNAL.md and PLAN.md added to project root, in .Rbuildignore
- README.md updated with arborize() section including papersize guidance
  and Related packages section
- NEWS.md v0.4.0 entry added
- pdftools added to Suggests
- renv/library/ and renv/staging/ added to .gitignore
- .Rprofile removed from .gitignore so renv activates for collaborators

### Files added in v0.4.0

    R/arborize.R
    R/toolero-package.R
    tests/testthat/test-arborize.R
    vignettes/arborize.Rmd
    vignettes/figures/          (pre-rendered tree PNGs)
    inst/extdata/data-provenance.md
    .github/workflows/test-coverage.yaml
    codecov.yml
    man/arborize.Rd
    man/dot-build_arborize_qmd.Rd
    man/dot-write_arborize_provenance.Rd
    man/toolero-package.Rd
    man/figures/lifecycle-*.svg (4 files)
    JOURNAL.md
    PLAN.md

DESCRIPTION changes: Version bumped to 0.4.0, pdftools in Suggests,
lifecycle in Imports, VignetteBuilder confirmed.

### Vignette image path debugging

The vignette took several iterations to pass R CMD check due to a path
resolution problem with knitr::include_graphics(). The root cause was a
single line in .Rbuildignore:

``` R
vignettes/figures/
```

This excluded the pre-rendered PNGs from the package tarball entirely,
causing every path approach to fail regardless of how it was
constructed. Approaches tried before the root cause was identified:
fig_path() helper, knitr::current_input(dir = TRUE), system.file(“doc”,
…), system.file(“vignettes”, …).

The fix: remove vignettes/figures/ from .Rbuildignore. With the PNGs
included in the tarball, plain relative paths work correctly:

``` R
knitr::include_graphics("figures/np-tree.png")
```

Lesson: when include_graphics() fails during R CMD check, verify the
files are actually in the tarball before debugging paths.
pkgbuild::build() tar -tzf toolero_0.4.0.tar.gz \| grep figures
