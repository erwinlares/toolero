# toolero -- Development Journal

---

## Session 1 — Pre-documentation (v0.1.0 through v0.3.0)

### What toolero is

toolero is an R package designed to help researchers implement best practices
for their coding projects. It provides a small set of opinionated, practical
functions that reduce friction at the start of a project and during day-to-day
data work. It is the foundational package in the *From the Notebook to the
Cluster* three-package suite alongside containr (Docker containerization) and
submitr (CHTC job submission).

toolero is on CRAN at v0.3.0. It was developed prior to the formal journaling
practice established during curriculr development. This journal captures the
accumulated design decisions and evolution of the package retroactively, then
continues forward in real time from v0.4.0.

### v0.1.0 — Initial release

The initial release shipped one function: `init_project()`. Its job is to
create a new R project at a given path with a standard folder structure suited
for research workflows. It optionally initializes renv for package management
and git for version control.

The default folder structure: `data/`, `data-raw/`, `R/`, `scripts/`,
`plots/`, `images/`, `results/`, `docs/`.

The philosophy behind `init_project()` is the same one that runs through all
of toolero: reduce the friction of starting a new project correctly so that
best practices become the path of least resistance rather than an extra step.

### v0.1.1 — UW branding

Added `uw_branding` argument to `init_project()`. When `TRUE`, creates an
`assets/` folder in the new project and populates it with UW-Madison RCI
branding files: `styles.css`, `header.html`, `rci-banner.png`. This reflects
toolero's origin as an internal tool for UW-Madison Research Computing
Infrastructure workshops and consultations.

### v0.2.0 — Quarto scaffolding and execution context detection

Three new functions added.

`detect_execution_context()` identifies which of three environments the code
is currently running in: an interactive R session, a `quarto render` call, or
a plain `Rscript` invocation. Returns one of `"interactive"`, `"quarto"`, or
`"rscript"`. This is useful for writing code that resolves input file paths
correctly across all three contexts -- a persistent pain point for researchers
who run the same script interactively, as part of a Quarto document, and on an
HPC cluster.

`create_qmd()` scaffolds a new Quarto document from a reproducible template.
Ships with a sample dataset (Palmer Penguins), UW-Madison branded assets, and
three-context input resolution via `detect_execution_context()`. Optionally
pre-populates the YAML header from a user-supplied YAML config file.

`write_by_group()` splits a data frame by a single grouping column and writes
each group to a separate CSV file. Filenames are derived from sanitized group
values. Optionally writes a `manifest.csv`.

Breaking changes in v0.2.0:
- `create_qmd()` path is now required, no default
- `write_by_group()` output_dir is now required, no default
- `init_project()` open now defaults to FALSE

### v0.3.0 — KB XML export, purl hook, API refinements

`generate_kb_xml()` produces UW-Madison Knowledge Base importable XML files
from rendered Quarto documents. Extracts metadata from the `.qmd` YAML header
(title, description, categories) and re-renders with embedded resources for
self-contained import. Addresses a specific operational need at UW-Madison RCI.

`create_qmd()` purl hook -- added `use_purl` argument (default `TRUE`) that
scaffolds a `_quarto.yml` post-render hook and a `purl.R` script for
extracting R code from rendered documents into `R/`. The purl script uses
`fs::dir_ls()` glob scan rather than the `QUARTO_DOCUMENT_PATH` environment
variable, which proved unreliable across different Quarto invocation methods.

Breaking changes in v0.3.0:
- `create_qmd()`: `filename` is now the first argument and has no default
- `write_by_group()`: sanitized filenames now use dash separators instead of
  underscores
- `init_project()`: `file_path` argument renamed to `path`

---

## Session 2 — 2026-04-30 (v0.4.0 development)

### What we set out to do

Add `arborize()` to toolero -- a function for rendering syntactic trees as PNG
images using Quarto's Typst engine. The function emerged from a need to migrate
linguistics documents from LaTeX + tikz/forest to Quarto + Typst without losing
the ability to produce standalone tree figures.

### Background: the LaTeX tree problem

The original workflow used LaTeX packages `gb4e`/`linguex`, `forest`/`tikz-qtree`,
and `tikz` in combination. These are mature but carry significant dependency
burden. The question was whether Typst could replace this workflow for standalone
tree figure production. Assessment: yes for PNG figures embedded in other
documents; LaTeX remains pragmatic for full linguistic papers with
cross-referenced examples.

### Decision: arborize() as a toolero function

The function fits toolero better than curriculr -- toolero is the general
research workflow toolkit and rendering a standalone figure from a string is
exactly the kind of utility it provides.

### Two rendering backends

Two Typst packages exist for linguistic trees:

`@preview/syntree:0.2.1` (simple notation) -- takes bracket notation string.
Compact, familiar to linguists, simpler interface. Version 0.2.0 was broken on
Typst 0.12+ due to the `style()` function being removed. Version 0.2.1 fixes
this.

`@preview/lingotree:1.0.0` (structured notation) -- takes nested `tree()`
function calls. More powerful: supports per-node styling, movement arrows,
multi-dominant trees. Released November 2025, compatible with current Typst.

The `tree_notation` argument controls which backend is used:
- `"simple"` -- bracket notation string, uses syntree 0.2.1
- `"structured"` -- nested tree() calls string, uses lingotree 1.0.0

The user provides the complete tree string in the appropriate format.
arborize() wraps it in the correct Typst scaffolding.

### Decision: no recursive bracket-to-lingotree parser

The lingotree backend does not require arborize() to parse bracket notation
and convert it to nested tree() calls. The user is responsible for providing
the correct string format. This keeps arborize() simple.

### The pipeline

arborize() performs six steps:
1. Validates inputs and resolves the Typst package from tree_notation
2. Builds a minimal .qmd document via .build_arborize_qmd()
3. Writes the document inside withr::with_tempdir() for automatic cleanup
4. quarto::quarto_render() produces an intermediate PDF via Typst
5. pdftools::pdf_convert() converts the PDF to PNG
6. PNG bytes are read into memory before temp dir is deleted, then written
   to the output path
7. If provenance = TRUE, .write_arborize_provenance() writes a .yaml file

### The provenance argument

`provenance = TRUE` (default) writes a companion `.yaml` file alongside the
PNG recording: tree string, tree_notation, typst_package, dpi, papersize,
margin, rendered_by, rendered_at, output path. This makes renders reproducible
and modifiable without hunting for the original tree string.

The parameter name `provenance` was chosen over `save_source`, `keep_source`,
or `write_source` because it is the most meaningful name in context -- it
records the provenance of the image, matching the DATA-PROVENANCE.md convention
established elsewhere in toolero.

A `rearborize()` function was considered and rejected for v0.4.0. The re-render
pattern (read yaml, call arborize() with recovered arguments) is only five lines
and does not justify an exported function. Deferred pending evidence of demand.

### papersize and margin: crop control

The `papersize` and `margin` arguments determine how tightly the PNG is cropped
around the tree. The key insight: `papersize` should match the tree's complexity,
not default blindly to `"a5"`. Practical guidance:
- `"a6"` or `"a7"` for simple trees (2-4 nodes)
- `"a5"` for medium trees (default)
- `"a4"` for wide or deep trees
- `"a3"` for very wide trees

`margin` provides buffer around the tree. Default `"0.5cm"` works for most
cases. This guidance is documented in both the arborize() @details and the
vignette.

### The builder/printer split

`.build_arborize_qmd()` returns a character string (testable without Quarto).
`.write_arborize_provenance()` writes the YAML file (testable without Quarto).
`arborize()` is the renderer that calls both and produces the file.

This mirrors the pattern established in curriculr for `cv_render_section()`.

### Character escaping findings

Simple notation (syntree): tree string goes inside a Typst string literal
delimited by double quotes. Double quotes inside the string must be escaped.
The gsub() call: `gsub('"', '\\\\"', tree, fixed = TRUE)`.

To match the escaped result in tests: `grepl('\\\\"cat\\\\"', result, fixed = TRUE)`.
Four backslashes in the R pattern = two literal backslashes in the string.

Structured notation (lingotree): tree string goes directly into Typst code,
not inside a string literal. No escaping needed. User bears syntax responsibility.

General principle: when user data crosses into a quoted string literal in
another language, escaping is required. When inserted as raw code, no escaping
but user bears syntax responsibility.

### Typst package version fix

Initial implementation used `@preview/syntree:0.2.0` which fails on current
Typst with `error: unknown variable: style`. The `style()` function was removed
in Typst 0.12. Version 0.2.1 (released February 19, 2025) fixes this.

### Function naming history

- create_syntree() -- original name, wrong verb (create implies persistence)
- render_syntree() -- accurate but pipeline-y
- arborize() -- final choice

arborize() was chosen because it is unexpected, precise, and memorable. To
arborize means to form a tree-like structure. The mild discoverability concern
is addressed by strong roxygen documentation.

### Test suite

- .build_arborize_qmd() tests: covers both backends and shared behavior,
  no Quarto required, runs everywhere
- .write_arborize_provenance() tests: file creation, field contents,
  filename matching, invisible return -- no Quarto required
- arborize() input validation: type errors, empty string, length > 1, NA,
  existing file, invalid notation, missing pdftools, invalid tree_notation
- arborize() provenance: provenance = FALSE suppresses yaml,
  provenance = TRUE writes yaml with correct fields
- arborize() full pipeline: 4 tests (3 simple, 1 structured) --
  all skip_on_ci() and skip_on_cran()

Path normalization fix in pipeline tests: withr::local_tempfile() produces
paths with // while fs::path_abs() normalizes to /. Use normalizePath() on
both sides before comparing.

### Vignette: arborize.Rmd

A full vignette was written covering:
- Motivation: the LaTeX tree problem and why a PNG-based solution helps
- Two backends: syntree vs lingotree, when to use each
- Crop control: papersize and margin guidance with an ISO paper size table
- Examples: simple NP, clausal tree, aspectual classes, print-quality,
  lingotree structured notation, suppressing provenance
- Provenance file structure and the manual re-render pattern
- Embedding in documents
- Argument reference table
- References to Typst packages

The vignette uses eval = FALSE globally (arborize() calls never execute during
build), with individual knitr::include_graphics() chunks using eval = TRUE and
out.width for display control. PNGs are pre-rendered and committed to
vignettes/figures/.

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

```
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
```

DESCRIPTION changes: Version bumped to 0.4.0, pdftools in Suggests,
lifecycle in Imports, VignetteBuilder confirmed.

### Vignette image path debugging

The vignette took several iterations to pass R CMD check due to a path
resolution problem with knitr::include_graphics(). The root cause was a
single line in .Rbuildignore:

    vignettes/figures/

This excluded the pre-rendered PNGs from the package tarball entirely,
causing every path approach to fail regardless of how it was constructed.
Approaches tried before the root cause was identified: fig_path() helper,
knitr::current_input(dir = TRUE), system.file("doc", ...), system.file("vignettes", ...).

The fix: remove vignettes/figures/ from .Rbuildignore. With the PNGs
included in the tarball, plain relative paths work correctly:

    knitr::include_graphics("figures/np-tree.png")

Lesson: when include_graphics() fails during R CMD check, verify the
files are actually in the tarball before debugging paths.
    pkgbuild::build()
    tar -tzf toolero_0.4.0.tar.gz | grep figures

---

## Session 3 -- 2026-05-11 (v0.4.0 housekeeping and new functions)

### What we set out to do

Complete v0.4.0 housekeeping before the July 2026 CRAN submission and add
new functions identified as v0.5.0 roadmap items that were pulled forward
since v0.4.0 had not yet been submitted to CRAN. The rationale: version
numbers communicate change to CRAN and to users; bumping one prematurely
just creates noise.

### DESCRIPTION updates

Updated the Description field to reflect the full function inventory,
including arborize() and generate_kb_xml() which were missing from the
v0.3.0-era prose. Added SystemRequirements: Quarto CLI (>= 1.4) as a hard
system dependency -- the package is genuinely Quarto-dependent by design,
not incidentally, so keeping quarto in Imports and declaring it explicitly
is the honest approach.

Confirmed that Config/roxygen2/version is roxygen2 8.0.0's replacement for
the older RoxygenNote field -- nothing broken, just a version-specific
change in how roxygen2 records itself in DESCRIPTION.

Confirmed withr belongs in Imports after verifying it appears in arborize.R,
generate_kb_xml.R, and init_project.R function bodies, not only in tests.

tidyr added to Imports via usethis::use_package("tidyr") for the drop_na
argument in read_clean_csv().

### cran-comments.md

Drafted a skeleton cran-comments.md with placeholder markers for progressive
updates as work continues before the July submission. Includes resubmission
note explaining the gap since v0.3.0, test environments, system requirements
note for Quarto CLI, and downstream dependencies section.

### .substitute_yaml() naming fix

Renamed substitute_yaml() to .substitute_yaml() in create-qmd.R to follow
the internal helper naming convention established elsewhere in the package.
Two changes: the function definition and the single internal call site inside
create_qmd(). Clean check confirmed.

### read_clean_csv() improvements

Extended read_clean_csv() with three new arguments:

na -- passes through to readr::read_csv()'s own na argument, making
missing-value handling explicit. Default c("", "NA") matches readr's
behavior so existing code is not broken.

drop_na -- accepts FALSE (default, no rows dropped), TRUE (drop any row
with a missing value), or a character vector of column names (drop rows
missing in those specific columns). Uses tidyr::drop_na() internally.
Always emits a cli message reporting rows dropped and rows remaining,
independent of the summary argument. drop_na and summary are deliberately
decoupled: each reports its own action without coupling to the other.

summary -- when TRUE, prints a brief ingest report after reading: row and
column counts, number of column names cleaned, missing value counts. Reflects
the final state after any drop_na action.

The ... argument passes additional arguments through to readr::read_csv()
for flexibility without wrapper bloat. Tradeoff: ... arguments don't appear
in autocomplete and aren't documented unless listed explicitly in roxygen.
Accepted as standard practice given the tidyverse orientation of the package.

The function reads the file twice: once with n_max = 0 to capture original
column names before cleaning, then again for the actual data. Small overhead
justified by accurate name-change reporting in the summary.

Argument renamed from file_path to path for consistency with the rest of
the package API. Breaking change noted for NEWS.md.

Double hyphens used in cli messages rather than em dashes. Em dashes
(Unicode \u2014) caused encoding errors in earlier versions and are avoided
going forward.

verbose argument retained but narrowly scoped: it only passes show_col_types
through to readr. The summary argument handles ingest narration. Keeping
them separate preserves a clear separation of concerns.

### write_clean_csv()

New exported function. Writes a data frame to CSV using readr::write_csv()
with cli feedback. Key design decisions:

overwrite = FALSE default -- consistent with create_qmd() and init_project()
conservative defaults. Errors clearly if the file exists and overwrite is
not set.

Name validation -- checks whether column names are already clean by comparing
to janitor::clean_names() output. If names are dirty, emits a cli warning
listing affected columns, applies janitor::clean_names(), then writes. This
makes the function self-contained and honest rather than silently accepting
dirty names or silently cleaning them without telling the user.

janitor::clean_names() is called twice when dirty names are detected: once
to check, once to apply. Consistent with the double-read pattern in
read_clean_csv(). Overhead negligible for typical research CSV sizes.

Returns path invisibly -- consistent with the rest of the package.

... passes through to readr::write_csv() for flexibility.

The function reinforces the project convention that data-raw/ holds original
inputs and data/ holds cleaned, analysis-ready outputs.

### check_project()

New exported function. Audits a project directory and reports whether it
follows toolero conventions. Two modes:

error = TRUE (default) -- prints a formatted cli report using cli_alert_*
symbols and returns the results invisibly.

error = FALSE -- returns a tibble with columns check, status, and message
without printing. Suitable for programmatic use or CI.

path argument defaults to "." for auditing the current project.

Checks performed and their severity:
- .Rproj file: fail if missing
- renv.lock: fail if missing
- git repository (.git/): fail if missing
- .gitignore: warn if missing
- data-raw/: warn if missing
- data/: warn if missing
- docs/: warn if missing
- R/ or scripts/: warn if missing (either satisfies the check)
- README.md, README.Rmd, or README.qmd: warn if missing

Hidden files reported only when present (conditional checks):
- .RData: warn -- stale session data risk
- .Rhistory: warn -- consider adding to .gitignore
- .Rprofile: info -- ensure customizations are documented
- .Renviron: info -- ensure it is in .gitignore to avoid leaking credentials

Internal helpers: .check_result() builds a named list for each check;
.print_check_project() handles the cli rendering. glue::glue() was removed
from .check_result() after discovering it tried to evaluate cli inline
markup like {.fn usethis::create_project} as R expressions and failed.
Messages are stored as plain strings; cli interprets the markup at print
time in .print_check_project(). The one call site that needs R variable
interpolation (the .Rproj pass message) uses paste0() directly before
passing to .check_result().

The tibble is assembled with unname(vapply(...)) to strip list names from
the resulting vectors. Named vectors caused expect_equal() failures in tests
because the names on actual and expected didn't match.

### Test suite notes

231 passing at session end, up from 172 at session start.

check_project() tests use a shared project created once at the top of the
test file with a custom make_project() helper. The helper uses plain fs and
base R calls rather than init_project() because usethis::create_project()
proved environment-sensitive under R CMD check -- the shared project
directory disappeared before tests ran.

The withr::local_tempdir() scoping problem: calling it inside a helper
function scopes the temp directory to the function's call frame, not the
test file's lifetime. The fix is to create the root temp directory at the
top level of the test file and pass it into make_project() as an argument.
This was a recurring issue across multiple iterations before the root cause
was identified.

withr::defer() used for mutating tests -- those that add or remove files
from the shared project. Each mutating test registers cleanup before its
assertion, restoring the project to its baseline state when the test exits.
Read-only tests use the shared project directly without cleanup.

expect_no_error() does not accept an info argument -- use expect_error(..., NA)
instead when a label is needed. This pattern was established earlier in the
session and applied consistently.

### Files added this session

```
R/write-clean-csv.R
R/check-project.R
tests/testthat/test-write-clean-csv.R
tests/testthat/test-check-project.R
cran-comments.md
```

DESCRIPTION changes: SystemRequirements added, Description prose updated,
tidyr added to Imports, withr confirmed in Imports.

### qmd_to_r()

New exported function. Extracts R code chunks from any .qmd file into a
standalone .R script using knitr::purl() under the hood. Works on any .qmd
regardless of whether it was created with create_qmd(), which is the key
motivation -- the existing purl hook only works for documents scaffolded
through toolero.

knitr kept in Suggests and gated with requireNamespace() rather than
promoted to Imports. The function errors clearly if knitr is not installed.

The documentation argument (0, 1, 2) maps directly to knitr::purl()'s own
documentation argument. Default 1 preserves chunk labels as comments without
the full roxygen overhead. The ... argument was considered and rejected --
no knitr::purl() arguments are realistically needed by toolero users beyond
what the signature exposes.

output defaults to the same directory as input with the .qmd extension
replaced by .R. Explicit path overrides this.

Files added: R/qmd-to-r.R, tests/testthat/test-qmd-to-r.R.

---

## Session 4 -- 2026-06-12 (run_by_group() and README revision)

### What we set out to do

Add `run_by_group()` -- the apply half of the split-apply workflow that
`write_by_group()` has been waiting for since v0.2.0. Update the README and
NEWS.md to reflect the full v0.4.0 function inventory. Revise the opening
sections of the README to situate toolero within the *From the Notebook to
the Cluster* family.

### run_by_group() design

The function is the apply counterpart to `write_by_group()`. The split is
done once; the apply step can be run many times as the analysis function
evolves. Two data sources are supported:

manifest path -- reads subset CSVs listed in a manifest produced by
write_by_group(manifest = TRUE). The manifest is a CSV with `group_value`
and `file_path` columns.

groups path -- accepts a named list of data frames already in memory,
bypassing disk reads entirely. All elements must have identical column names
and types, consistent with subsets from a single source dataset.

Output shape is determined by what .f returns. If .f returns a data frame,
results are automatically unnested into a flat tibble with a group ID column
prepended. If .f returns anything else (a model, a plot, a file path), results
come back as a nested tibble with a list-column named `results`.

Parallel execution is supported via furrr and future through the `workers`
argument. The hard ceiling is `parallel::detectCores(logical = FALSE) - 1L`
to reserve one core for the main session -- this is enforced with a cli_abort()
rather than left to the user to discover by experience.

### Code review and seven fixes applied

After drafting the initial implementation, a code review identified seven
issues that were corrected before the function was finalized.

1. `.read_fn` validation -- the initial version validated `.f` but not
   `.read_fn`. Added the same is.function() check immediately after the .f
   check.

2. `workers` validation -- no input validation existed on the workers argument.
   Added: coerce to integer defensively (so bare doubles like workers = 2
   behave correctly), check for < 1L, check against
   parallel::detectCores(logical = FALSE) - 1L ceiling with a clear error
   message reporting what was requested and what the maximum is.

3. `seed` readability -- the conditional `seed = if (!is.null(seed)) seed else NULL`
   simplified to `seed = seed` since furrr_options(seed = NULL) is valid and
   already means no seed management.

4. `renv` autoloader envvar -- the original used Sys.setenv() with
   on.exit(Sys.unsetenv()), which deletes the variable entirely rather than
   restoring its prior value. Replaced with withr::local_envvar() which
   captures and restores the prior state correctly.

5. Missing files error message -- the original used paste0("- ", missing_files)
   as an unnamed vector in cli_abort(), which rendered without cli's path
   styling. Replaced with cli's vectorized {.path {missing_files}} inline
   markup for proper rendering and pluralization.

6. Manifest data_list naming -- the manifest path produced an unnamed
   data_list while the groups path produced a named one. Fixed by assigning
   names(data_list) <- group_names immediately after reading the files, so
   both paths produce a named list before the apply step. Added a comment
   explaining the intentional symmetry.

7. `.read_fn` validation -- see item 1 above (listed separately in the
   original review; consolidated here).

### cli pluralization bug in groups element type check

After the function was implemented and tests were written, one test failed
with a cli internal error: `length(object) == 1 is not TRUE` from
cli:::make_quantity(). The error was in the production code, not the test.

The offending message:
    "i" = "Element{?s} {bad} {?is/are} not a data frame."

The problem: {?is/are} requires a single scalar quantity to count against.
{bad} is a vector, so cli cannot resolve the pluralization.

Fix: restructure the message so cli counts length(bad) explicitly:
    "i" = "{length(bad)} element{?s} {?is/are} not a data frame: position{?s} {.val {bad}}."

### @importFrom rlang := placement

The := operator (used in `!!.id := group_names`) must be imported from rlang.
The @importFrom tag was placed in the roxygen block but failed to appear in
NAMESPACE after devtools::document(). Investigation revealed the cause: a
blank line between the closing #' } of the @examples block and the
run_by_group <- function(...) definition. Roxygen requires the block to be
immediately adjacent to the function with no blank lines. Removing the blank
line caused @importFrom(rlang, ":=") to appear in NAMESPACE correctly.

Lesson: if an @importFrom tag appears correct but does not show up in NAMESPACE
after devtools::document(), a stray blank line before the function signature
is the first thing to check.

### utils::globalVariables("results")

R CMD check emitted a NOTE: `run_by_group: no visible binding for global
variable 'results'`. This arises from `tidyr::unnest(output, results)` where
`results` is a bare column name rather than a variable. Suppressed by adding
`utils::globalVariables("results")` to toolero-package.R at the top level,
alongside the package sentinel. This is the correct location for package-wide
suppression declarations -- not in the individual function file.

### dplyr dependency

The examples block uses dplyr::summarise(), dplyr::n(), and dplyr::group_split().
The test file uses dplyr::arrange(). Adding dplyr to Imports produced a NOTE
("Namespace in Imports field not imported from: 'dplyr'") because no package
function uses @importFrom dplyr -- all calls are namespace-qualified with ::.
Resolution: move dplyr to Suggests in DESCRIPTION, since all calls are already
qualified and the package body itself has no unqualified dplyr imports.

### Test suite for run_by_group()

Tests organized into five groups: input validation, data source dispatch,
output shape, parallel execution, and verbose messaging.

The make_manifest() helper follows the same pattern as make_project() in
test-check-project.R -- plain fs and readr calls, no toolero functions, root
temp directory created at file level with withr::local_tempdir() and passed
in as an argument to avoid the call-frame scoping problem.

Parallel tests all guarded with skip_on_cran() and skip_on_ci() following
the arborize() precedent. The "different seeds produce different results"
test uses four groups and a 1:1e6 sample space to make a false negative
astronomically unlikely.

Notable test: the ... passthrough test. Verifies that extra arguments passed
to run_by_group() reach .f on every call. Worth having explicitly because
refactoring worker_fn without carrying dots along is an easy mistake.

### README revision

Two updates made to the README:

run_by_group() added to the quick reference table immediately after
write_by_group(). A combined `write_by_group() and run_by_group()` section
replaced the standalone write_by_group() section, framing the split-apply
pattern as a whole. The section closes with a forward link to
submitr::htc_gen_submit() -- the manifest from write_by_group() is the
direct input to submitr's multiple-job mode, and this is the first place
in the README where that connection is made explicit.

The first three README sections were rewritten to name the
*From the Notebook to the Cluster* family explicitly. The "The problem with
starting from scratch" section gained a new paragraph introducing the family
name as the response to the problem. "When to use toolero" gained a closing
sentence pointing forward to the next step. "The toolero family" was renamed
to "From the Notebook to the Cluster" with prose foregrounding the organizing
idea: good practices at each stage make the next stage easier.

### Decision: hold version bump to 0.5.0

run_by_group() is a substantial addition that could justify a version bump to
0.5.0. The decision was to hold the bump until read_clean_tsv() and
read_clean_parquet() are also complete, so the version history reflects a
coherent feature set rather than a single function. The read_clean_*() family
becomes the first priority for v0.5.0.

### Files added this session

```
R/run-by-group.R
tests/testthat/test-run-by-group.R
```

DESCRIPTION changes: furrr and future added to Suggests, dplyr moved from
Imports to Suggests, rlang := importFrom added to NAMESPACE via roxygen.

toolero-package.R changes: utils::globalVariables("results") added.

---

## Session 5 -- 2026-07-09 (write_by_group() multi-column grouping)

### What we set out to do

Extend `write_by_group()` to accept more than one grouping column, closing
the gap it's had since v0.2.0 -- the function has only ever supported a
single grouping column, splitting on `split(data, data[[group_col]])`
directly. The manifest it produces is a real integration point (input to
`run_by_group()`'s manifest-path mode, and eventually to
`submitr::htc_gen_submit()`), so the shape of any change here mattered
beyond this one function.

### Decision: single exported function, not write_by_group2()

Considered and rejected keeping the original function untouched and adding
a parallel `write_by_group2()` for the multi-column case. Rejected for three
reasons: `run_by_group()` already established the precedent of dispatching
on input shape *inside* one function rather than forking into a second one;
a numeric-suffix name has no precedent anywhere in the *From the Notebook to
the Cluster* family; and validation logic (column existence, list-column
rejection, duplicate detection) would have to be either duplicated across
two functions or factored into a shared internal helper anyway, so the
maintenance cost doesn't actually go away, it just becomes less visible.
`group_col` is now treated as a character vector of length >= 1 uniformly
throughout the function; only the final manifest shape branches on length.

### Filename separator

`group_col` values are still sanitized independently by the existing
`sanitize_filename()` helper, unchanged. For multiple columns, sanitized
values are joined with `--` in the order supplied (`c("species", "sex")` on
an Adelie male -> `adelie--male.csv`). `--` was chosen because
`sanitize_filename()`'s own logic guarantees a single sanitized value can
never itself contain two consecutive dashes -- the first `gsub()` collapses
any run of non-alphanumeric characters to one dash -- so `--` is an
unambiguous marker of a column boundary, never a byproduct of sanitizing one
value. `" / "` was considered and rejected for the *manifest's* raw
composite field specifically (a separate design question from the filename
separator) because it reads as a directory path; `" | "` was used there
instead.

### Splitting strategy: composite key via paste(), not interaction()

Rows are split on a manually constructed composite key
(`do.call(paste, c(sanitized_cols, sep = "--"))`) rather than
`interaction()`. This was a deliberate choice to avoid two separate
problems at once. First, `interaction()` without `drop = TRUE` materializes
the full cross-product of factor levels, which would produce empty output
files for grouping-column combinations that don't exist in the data.
Second, and more subtly, `split()`'s default behavior when given a raw
vector (not already a factor) coerces via `as.factor()`, and `as.factor()`
does not create an `NA` level by default -- rows with `NA` in the grouping
column silently vanish from every resulting group, with no warning. This
turned out to be true of the *original* single-column implementation too,
not just a risk introduced by this change (see `drop_na` below). Building
the composite key as a plain character vector before ever calling `split()`
sidesteps both problems: only observed combinations appear as keys, and by
the time `split()` runs, no key is ever actually `NA`, because `drop_na`
handling has already resolved every row's grouping values to real strings.

### The drop_na argument

Discovered while designing the NA-handling behavior for multiple columns:
the *existing* single-column implementation already silently drops rows
with `NA` in the grouping column, via the `as.factor()` mechanism described
above. This was undocumented, untested, and had never been surfaced to the
user. Rather than just carrying that behavior forward silently into the
multi-column case, added `drop_na` as an explicit argument (default `TRUE`,
matching naming convention from `read_clean_csv()`'s own `drop_na`).
`TRUE` preserves the original silent-drop behavior but now emits a
`cli_alert_info` reporting the row count and affected column(s) -- no
longer silent, just the same net effect. `FALSE` is new capability: rows
with missing grouping values are coerced to the literal string `"NA"`
before sanitization, so they form their own group (e.g.
`adelie--na.csv`) rather than disappearing.

### Manifest shape

For a single grouping column, the manifest schema is byte-for-byte
unchanged from previous versions: `group_value`, `n_rows`, `file_path`.
Confirmed by test coverage and against real output from `data.csv` before
any code changed. For multiple grouping columns, the manifest is extended
additively: one column per grouping variable (named for the actual column,
holding the raw unsanitized value) inserted before `group_value`, which
becomes a human-readable composite of the raw values joined by `" | "`
(e.g. `"Adelie | male"`). `run_by_group()`'s manifest reader only looks for
`group_value` and `file_path` by name, so this extension doesn't require
any change there.

### New validation added

`group_col` validation was rewritten rather than extended, since the
original `if (!group_col %in% names(data))` pattern breaks outright once
`group_col` can have length > 1 (`if` on a vector of length > 1 errors in
current R). New checks, in order: `group_col` must be a non-`NA` character
vector; no duplicated column names; every element must exist in
`names(data)`, with *all* missing names reported together via
`setdiff()` rather than failing on the first one found; no list-columns
among the selected grouping columns (they don't sanitize into a filename
fragment meaningfully); and no grouping column may be named `group_value`,
`n_rows`, or `file_path`, which would silently collide with the manifest's
own reserved columns. That last check was originally unconditional, but
scoped to only fire when `manifest = TRUE` after review -- the collision
only actually matters when a manifest gets built, so rejecting a valid call
that never requests one was an unforced regression.

### cli pluralization bug: the same failure mode as run_by_group(), different trigger

`R CMD check`/`devtools::test()` surfaced a `post_process_plurals`: "Multiple
quantities for pluralization" error identical in kind to the one documented
in Session 4 for `run_by_group()`, but with a different root cause worth
distinguishing. The broken message:

    "Column{?s} {.val {missing_cols}} not found in {.arg data}.
     Available columns: {.val {names(data)}}."

Here `{?s}` appears *before* any quantity is established, and two different
vector interpolations (`missing_cols`, `names(data)`) appear later in the
string -- cli has to search forward for a quantity and finds two competing
candidates with no way to prefer one. This broke even the single-missing-
column case, since the ambiguity is structural (two candidate vectors
present), not dependent on runtime length.

By contrast, the `drop_na` message, which also has two separate `{?s}`
markers, did *not* trigger the bug:

    "Dropped {sum(na_mask)} row{?s} with missing values in grouping
     column{?s} {.val {group_col}}."

Each marker here sits immediately adjacent to its own single quantity
source with nothing else competing nearby -- `row{?s}` binds to the
preceding `sum(na_mask)`, `column{?s}` binds to the immediately-following
`{.val {group_col}}`. No other vector appears near either marker, so there's
no ambiguity to resolve.

Refined lesson (extending the Session 4 finding): a `{?s}`/`{?is/are}`
marker needs an unambiguous nearby quantity -- either a preceding explicit
`{length(x)}` scalar, or being adjacent to the one vector that determines
it with no second vector competing nearby. Fix applied: added an explicit
`{length(missing_cols)}` token before the marker. The reserved-column-name
message was also preemptively hardened the same way, even though it wasn't
confirmed broken (only one underlying vector referenced twice), since the
fix is cheap and consistent with the established pattern.

### Known limitation: group iteration order

Splitting on the sanitized, character-coerced composite key means iteration
order now follows that key's sort order rather than the original column's
native type. For single-column grouping this can differ from previous
versions specifically when `group_col` is numeric with values of differing
digit length (`9, 10, 11` sorts numerically pre-refactor, lexicographically
as `10, 11, 9` post-refactor) or when case affects locale-specific sorting.
File contents and manifest row counts are unaffected -- only the order in
which groups are written and reported. Documented in the `@details` roxygen
section rather than fixed; not surfaced in `NEWS.md`, on the judgment that
it's implementation detail rather than user-facing behavior change worth
flagging in a changelog.

### Manual verification against real data

Before writing tests, the implementation was run manually against the
Palmer Penguins dataset across one, two, and three grouping columns
(`species`; `species, sex`; `species, sex, island`), with both `drop_na`
values, with and without `manifest = TRUE`. Row-count arithmetic was
checked by hand against the known single-column manifest (152/68/124 for
Adelie/Chinstrap/Gentoo, 344 total) at every step, including confirming
that written-plus-dropped always summed to 344. This surfaced the real
`island` distribution as a useful edge case: Chinstrap only co-occurs with
`island = Dream` in this dataset, which confirmed the composite-key
splitting approach produces files only for observed combinations rather
than the full cross-product, on real data rather than a constructed
example.

### Test suite

Extended `test-write_by_group.R` in place rather than creating a separate
file, following the existing flat `test_that()` structure (no `describe()`
blocks, one `make_*()` data helper per fixture shape, individual
`withr::local_tempdir()` per test rather than a shared one). Added a second
helper, `make_multi_group_data()`, with one `NA` baked into the grouping
column specifically to exercise both `drop_na` branches. New coverage:
multi-column split correctness (one CSV per observed combination, correct
`--` filenames, correct row subsets, exactly the observed combinations and
not the cross-product), multi-column manifest shape and composite
`group_value` content, `group_col` order determining both filename and
manifest column order (tested by reversing column order and checking the
reversed output), both `drop_na` branches with row-count reconciliation,
the reserved-name collision (and its absence when `manifest = FALSE`),
duplicate `group_col` entries, list-column rejection, and an explicit test
that a multi-column missing-column error names every missing column, not
just the first.

Final state: `devtools::test()` -- 404 passing, 0 failures, 1 pre-existing
skip (`pdftools` installed). `devtools::check()` -- 0 errors, 0 warnings,
1 NOTE (`spelling.R`, four false-positive words: `Adelie`, `dplyr`,
`lexicographically`, `unsanitized`; resolved via
`spelling::update_wordlist()`, not yet re-verified in this session).

### NEWS.md

Two new bullets added to the existing "New features (continued from above)"
section for v0.4.0, alongside the `init_project()` `config` and
`create_qmd()` `include_examples`/`use_style` entries -- judged the better
fit over the top-level "New features" section, since that section is
reserved for functions added from scratch and this is an enhancement to an
already-existing one. The `drop_na` bullet explicitly names the previous
behavior as "previously silent, undocumented behavior inherited from
split()" rather than describing the new argument neutrally, a deliberate
choice to be forthcoming about a real gap rather than let the changelog
read as if the argument were part of the original design.

### Backward compatibility assessment

Reviewed explicitly before finalizing. No breaking changes to the exported
API surface, but three points flagged as things a single-column caller
could plausibly notice: the group iteration order caveat above; the new
`is.character(group_col)` type check is stricter than the original
`%in%`-based comparison, which coerced more permissively; and the reserved-
name check is new validation that could reject a call that previously
succeeded, if a user's data happens to have a column literally named
`group_value`, `n_rows`, or `file_path` -- mitigated by scoping that check
to `manifest = TRUE` only, but not eliminated entirely for that specific
edge case.

### Files changed this session

```
R/write-by-group.R              # group_col vector support, drop_na,
                                 #   reserved-name validation, cli fixes
tests/testthat/test-write_by_group.R
NEWS.md                         # two new bullets under v0.4.0
```

No DESCRIPTION changes -- no new dependencies introduced.

---

## Session 6 — 2026-08-27 (save_output(), generate_manifest(), check_project() overhaul)

### What we set out to do

Three things in one session. First, implement `save_output()` and
`generate_manifest()` — the output-recording pair that closes the loop between
a finished analysis and a durable, auditable record of what it produced. Second,
fix two open issues against `check_project()`: a broken README detection
(issue #11) and a request for config-driven folder auditing (issue #12). Third,
deprecate the `error` argument in `check_project()`, which had never been well
named and was quietly becoming misleading.

### save_output() and generate_manifest() — design rationale

The core design is straightforward: `save_output()` is a thin wrapper around
any user-supplied write function, and the wrapping buys two things — a
narrowly-scoped `tryCatch()` that records failures before rethrowing, and an
append-only CSV accumulator that builds up a per-session record of every write
attempt. `generate_manifest()` reads that accumulator at the end of the
analysis, deduplicates it by `file_path` (keeping the latest timestamp per
path, since re-runs within a session leave superseded rows behind), and writes
`project-manifest.json`.

Several deliberate exclusions are worth recording. Field names in the manifest
are toolero-native rather than RO-Crate vocabulary (`@id`, `dateCreated`, and
so on) — that translation belongs in `encapsulr::describe()` as a thin mapping
layer rather than baked into toolero's public interface. Checksums are excluded
for the same reason: `rocrateR::bag_rocrate()` computes `manifest-sha512.txt`
automatically at bagging time, and duplicating that here creates a second record
to keep in sync. And `r_class` is captured before the write call rather than
recovered afterward, since class cannot be reliably determined from a file on
disk.

### save_output() — key decisions

The `.f` argument is captured via `deparse(substitute(.f))` before the write
call, so the accumulator records the name exactly as written at the call site.
This means reassignment indirection (`my_fn <- ggsave; .f = my_fn`) records
`"my_fn"` rather than `"ggsave"` — an honest record, but potentially
surprising. The documentation warns against this pattern. Anonymous functions
fall back to a `"anonymous function: <deparsed body>"` label rather than a bare
multi-line dump, with the body collapsed and truncated at 200 characters.

The `tryCatch()` wraps only the `.f(object, file_path, ...)` call, not the
rest of `save_output()`'s body. On failure, a row is appended with
`status = "failure"` and the caught message, then the original condition is
rethrown via `stop(caught_condition)`. This is the one place in the package
where the `cli` convention is deliberately not followed: `cli::cli_abort()`
would construct a new condition and discard the original class, which is
exactly what the design is trying to avoid.

The rethrow does introduce one new frame on the call stack (the `tryCatch`
handler), which is unavoidable. The condition object — class, message, and call
— is preserved exactly as caught.

`r_class` collapses `class(object)` with `"|"` rather than commas. Commas work
fine through a real CSV parser (the field is quoted), but `"|"` is unambiguous
on sight and survives naive line-splitting in a job log. A comma separator would
be invisible inside quotes on a quick grep; a pipe separator is not.

Timestamps are formatted in UTC with millisecond precision
(`%Y-%m-%dT%H:%M:%OS3Z`) so they sort lexicographically. This matters because
`generate_manifest()` deduplicates by keeping the latest timestamp per path,
and a timestamp that silently records local time would sort wrong when mixed
with UTC rows.

Missing destination directories are created automatically and reported via
`cli::cli_inform()`. The same behavior applies to `output_dir` for the
accumulator. The asymmetry with the old `check_project()` prompt (which asked
before creating) was resolved in favor of silent creation with a message, on
the grounds that `save_output()` is primarily used in unattended contexts where
no one is available to respond to a prompt.

### generate_manifest() — key decisions

A missing accumulator is an error, not an empty result. The file is created by
the first `save_output()` call, so its absence means no save was ever recorded
— most often a misconfigured `output_dir`, a `manifest = FALSE` call, or a
script that crashed before reaching `save_output()`. Returning an empty
manifest in that case would present a setup mistake as a finished record. An
accumulator that exists but holds no rows is different — the machinery was
wired up, the analysis just produced nothing — and produces an empty manifest
with a warning.

`overwrite = FALSE` (the default) errors when a manifest already exists. This
is consistent with the package's conservative-defaults pattern across
`create_qmd()`, `init_project()`, and `write_clean_csv()`.

The `artifacts` array in the manifest carries all seven accumulator fields —
`file_path`, `r_class`, `timestamp`, `function_used`, `status`,
`error_message`, `note` — per deduplicated row. The order is chronological by
`timestamp`, since reading a failed run top-to-bottom is the most natural
diagnostic pattern.

### The rscript/CHTC convention

PLAN.md originally described wrapping the rscript execution branch in
`tryCatch(..., finally = generate_manifest())`. After reviewing
`detect_execution_context()` — which is purely a classifier, not a control-flow
wrapper — it became clear there is no existing "rscript execution branch" in the
codebase. The intent was describing future behavior, not pointing at existing
code.

The decision was to document this as a manual convention rather than a
provided wrapper function. The recommended pattern for unattended CHTC
execution:

```r
tryCatch(
  { ... analysis code ... },
  finally = try(generate_manifest(), silent = TRUE)
)
```

The `try()` inside `finally` is essential. A crash before the first
`save_output()` call leaves no accumulator; a bare `generate_manifest()` inside
`finally` would then throw a manifest-not-found error that replaces the
original error in the job log. `try(..., silent = TRUE)` lets `generate_manifest()`
fail quietly in that case, so the original error propagates. This convention is
documented in the README and filed as a future lower-priority task in PLAN.md.

### File placement for the new helpers

Following the convention established in `check-project.R` and `run-by-group.R`
(helpers live alongside the primary function that calls them), the new code
lands in two files:

`R/save-output.R` holds `save_output()` and its helpers: `.capture_function_name()`,
`.flatten_field()`, `.accumulator_columns()`, `.ensure_directory()`, and
`.append_accumulator_row()`.

`R/generate-manifest.R` holds `generate_manifest()` and its helpers:
`.read_accumulator()` and `.dedupe_accumulator()`.

`.accumulator_columns()` is the single source of truth for the CSV schema,
shared by both files. Schema drift between the write end (`save_output()`) and
the read end (`generate_manifest()`) was identified as the highest-risk silent
bug, since both ends append or read the same file format. The fix is
centralizing the column list in one function rather than maintaining parallel
vectors in two files — `.append_accumulator_row()` validates the existing header
against `.accumulator_columns()` before appending, and `.read_accumulator()`
does the same check after reading.

### accumulator.csv and project-manifest.json — naming distinction

Both are referred to as the "project manifest" in documentation and vignettes,
to distinguish them from the job manifest produced by
`write_by_group(manifest = TRUE)` and consumed by `submitr::htc_gen_submit()`.
Same word, two structurally different documents: the job manifest lists inputs
to a computation about to happen; the project manifest records outputs from one
that already happened. The default filename `project-manifest.json` rather than
`manifest.json` preserves this distinction even outside the documentation.

### check_project() — README detection fix (issue #11)

The original implementation checked for exactly `README.md`, `README.Rmd`, and
`README.qmd` via `fs::file_exists()`. On a case-sensitive filesystem (Linux,
including CHTC nodes), `readme.md` or `Readme.md` would fail silently. The
root cause: exact name matching rather than pattern matching.

The fix uses `fs::dir_ls(type = "file")` combined with `grepl()` on the
`path_file()` of each result, with `ignore.case = TRUE` and the regex
`^readme(\\.[^.]*)?$`. This matches any file whose stem is `readme` in any
capitalization, with any single extension or no extension at all. Double
extensions like `readme.tar.gz` are deliberately excluded by the `[^.]*`
pattern — the single-extension limitation is documented in the test suite as a
known design decision rather than a bug.

The message now reports which specific file was found, which is a small but
useful improvement for projects with unusual README filenames.

### check_project() — config argument (issue #12)

The `config` argument accepts a path to a YAML file produced by
`generate_project_config()`. When supplied, the `folders:` list in the YAML
replaces the hardcoded standard folder set for the folder checks. Non-folder
hygiene checks — `.Rproj`, `renv.lock`, git, `.gitignore`, README, and hidden
files — always run regardless of the config. This is a deliberate line: folder
structure is the thing that varies by project type, but the hygiene checks are
universal reproducibility requirements that should not be suppressible via
config.

Missing config-declared folders are reported as `"fail"` rather than `"warn"`.
The reasoning: a hardcoded folder check saying "you might want a `data-raw/`
folder" is advice; a config-driven check saying "you declared you want a
`models/` folder and it's missing" is a conformance failure. The severity
distinction reflects the difference between a suggestion and a declared
expectation.

Config validation checks for: file existence, single-string path, presence of
a `folders:` key, a flat (non-nested) YAML structure, no empty or blank entries,
and duplicates (which are deduplicated with a message rather than an error).

### cli markup injection — .cli_escape()

Both the README filename and config folder names flow through `cli` template
strings via `.print_check_project()`. A folder literally named `output/{draft}`
would cause `cli` to evaluate `draft` as an R expression and abort. This is the
same class of bug the JOURNAL records for `glue()` inside `.check_result()` in
Session 3, and for `.check_result()` more broadly.

The fix is a new internal helper `.cli_escape()` that doubles braces in any
string derived from user or filesystem data before it reaches a cli template.
Static messages containing intentional markup like `{.fn usethis::create_project}`
are not escaped — they must reach cli with their markup intact. The discipline
is: escape at construction time for data-derived strings, leave static strings
alone.

A regression test (`check_project() survives a config folder containing braces`)
pins this behavior so it cannot quietly regress.

### check_project(error) — deprecation

The `error` argument's name was a poor fit for its actual behavior from the
start. `error = TRUE` did not cause the function to error; it caused the cli
report to print. `error = FALSE` returned the tibble visibly without printing.
The only thing `error = FALSE` bought over assigning the result of
`error = TRUE` was a visible return rather than an invisible one — a thin
distinction for a public argument name that implied something completely
different.

The deprecation collapses the two branches: the cli report now always prints
and the tibble always returns invisibly, matching `error = TRUE`'s former
behavior. Passing `error = FALSE` triggers `lifecycle::deprecate_warn()` and
continues to work for one more version. Removal is planned for v0.6.0.

One consequence worth recording: `check_project(error = FALSE)` in v0.4.0.9000
now both prints the deprecation warning *and* prints the cli report, since the
two-branch logic has collapsed to one. Any existing caller using `error = FALSE`
specifically to suppress the printed output will notice this. The change is
documented in NEWS.md and the README example updated from
`issues <- check_project(error = FALSE)` to `out <- check_project()`.

### Test suite

577 passing, 0 failures, 0 warnings, 1 pre-existing skip (pdftools installed)
at session end.

`test-check-project.R` was rewritten rather than extended in place, for two
reasons. First, every existing test called `check_project(error = FALSE)`, which
now emits a deprecation warning — roughly thirty tests would have started
failing on the warning alone under testthat edition 3. Second, the shared
`root`/`project` created once at the file level (rather than per-test) violated
the per-test isolation convention established in later sessions. The rewrite
moves to individual `withr::local_tempdir()` per test, drops `withr::defer()`
cleanup from mutating tests (no longer needed when each test has its own
directory), and adds `make_config()` as a second helper alongside `make_project()`.

New test coverage added: all fifteen README variants in a single parametrized
loop (with `info = variant` so failures name which variant broke), config folder
pass/fail/replace, config validation error cases, the cli injection regression,
the deprecation warning via `class = "lifecycle_warning_deprecated"`, and the
`.cli_escape()` and `.standard_folder_message()` helpers tested directly.

`test-save-output.R` and `test-generate-manifest.R` are new files. Key
decisions: `.capture_function_name()` takes a deparsed `f_expr` rather than
`.f` directly, making it testable without `substitute()` gymnastics.
`.dedupe_accumulator()` is a pure function on a data frame, tested exhaustively
against controlled timestamps rather than real clock values. The
rethrow test uses a custom `rlang::abort()` class and asserts the class
survives the round trip — asserting "an error occurred" would pass even a
broken rethrow. The end-to-end tests compose `save_output()` and
`generate_manifest()` across success and failure paths.

The `jsonlite` empty-array assumption — that `write_json()` emits `"artifacts": []`
for a zero-row data frame rather than `{}` — is tested explicitly, since this
was an assumption rather than verified behavior.

### DESCRIPTION changes

- `jsonlite` added to Imports (for `generate_manifest()`)
- `utils` added to Imports (for `read.csv()` and `write.table()` in the
  accumulator helpers)
- `withr` removed from Suggests — it was already in Imports (confirmed in
  Session 3); the duplicate was causing an R CMD check NOTE

### check examples fix

`R CMD check --run-donttest` failed on the `check_project()` examples because
the second example used a literal placeholder path `"path/to/project"` that
does not exist, triggering `cli_abort()`. Fixed by replacing the placeholder
with `withr::local_tempdir()`. All examples now use real paths.

### Files added this session

```
R/save-output.R
R/generate-manifest.R
tests/testthat/test-save-output.R
tests/testthat/test-generate-manifest.R
```

### Files changed this session

```
R/check-project.R               # README fix, config argument, error
                                 #   deprecation, folder set update,
                                 #   .cli_escape(), .standard_folder_message()
tests/testthat/test-check-project.R  # full rewrite
README.md                       # save_output()/generate_manifest() sections,
                                 #   check_project() update, first workflow,
                                 #   quick reference, dependencies
NEWS.md                         # v0.4.0.9000 entry drafted
PLAN.md                         # v0.5.0 completed items, roadmap advanced,
                                 #   source file inventory updated,
                                 #   function table updated
JOURNAL.md                      # this entry
DESCRIPTION                     # jsonlite and utils added to Imports,
                                 #   withr removed from Suggests
```
