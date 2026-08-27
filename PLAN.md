# toolero – Package Development Plan

## What is toolero?

toolero is an R package designed to help researchers implement best
practices for their coding projects. It provides a small set of
opinionated, practical functions that reduce friction at the start of a
project and during day-to-day data work.

toolero is the foundational package in the *From the Notebook to the
Cluster* three-package suite:

    toolero     -- research workflow toolkit (CRAN v0.4.0, v0.4.0.9000 in development)
    containr    -- Docker containerization toolkit (CRAN pending)
    submitr     -- CHTC job submission toolkit (CRAN pending)

------------------------------------------------------------------------

## Package identity

- Name: toolero
- On CRAN at v0.4.0; v0.4.0.9000 in development on GitHub
- CRAN submission planned for July 2026 (CRAN resubmission policy gap)
- MIT license
- Influenced by The Carpentries and UW-Madison Libraries workshop
  practices
- UW-Madison RCI branding available via `branding = "uw-madison"`

------------------------------------------------------------------------

## Completed: v0.1.0

- init_project() – standard folder structure, optional renv and git

## Completed: v0.1.1

- init_project() uw_branding argument – copies RCI assets into assets/

## Completed: v0.2.0

- detect_execution_context() – identifies interactive, quarto, rscript
- create_qmd() – Quarto document scaffolding with UW branding and
  template
- write_by_group() – splits data frame by group, writes CSVs

## Completed: v0.3.0

- generate_kb_xml() – produces UW-Madison KB importable XML from Quarto
  docs
- create_qmd() use_purl argument – post-render R code extraction hook
- Breaking changes: filename first in create_qmd(), dash separators in
  write_by_group(), file_path renamed to path in init_project()

## Completed: v0.4.0

- arborize() – syntactic tree renderer with simple and structured
  notation
- .build_arborize_qmd() – internal builder, fully tested without Quarto
- .write_arborize_provenance() – writes companion .yaml provenance file
- Palmer Penguins credit in create_qmd() roxygen, template,
  DATA-PROVENANCE.md
- Lifecycle badge (stable) and Codecov coverage badge
- test-coverage GitHub Action
- arborize vignette with papersize/margin crop guidance
- JOURNAL.md and PLAN.md added, in .Rbuildignore
- .substitute_yaml() naming fix – internal helper renamed from
  substitute_yaml()
- read_clean_csv() extended – na, drop_na, summary, … arguments added
- write_clean_csv() – new exported function
- check_project() – new exported function
- qmd_to_r() – extracts R code from any .qmd into a standalone .R script
- run_by_group() – applies a function to each group subset, collects
  results; supports manifest or named-list input, parallel execution via
  furrr/future, tabular and non-tabular output routing
- DESCRIPTION updated – furrr and future added to Suggests, dplyr moved
  to Suggests, rlang := imported
- README updated – run_by_group() added to quick reference and core
  workflow sections; first three sections rewritten to reflect From the
  Notebook to the Cluster family name
- NEWS.md updated – full v0.4.0 entry drafted
- cran-comments.md drafted – skeleton with progressive update markers

## Completed: v0.4.0.9000 (in development)

- save_output() – dispatching output verb; writes object via
  user-supplied .f and appends a row to output_dir/accumulator.csv
  recording file_path, r_class, timestamp, function_used, status,
  error_message, note; rethrows original condition on failure; creates
  missing destination directories with a cli message
- generate_manifest() – reads and deduplicates accumulator.csv, writes
  project-manifest.json with execution_context, generated_at, and
  artifacts array; errors on missing accumulator, warns and writes empty
  manifest on zero-row accumulator
- check_project() README detection fix (issue \#11) – case-insensitive,
  extension-agnostic detection via regex on the file stem; any file
  named readme (any capitalization, any extension or none) passes
- check_project() config argument (issue \#12) – config YAML replaces
  the standard folder set; missing config-declared folders are fail not
  warn; hygiene checks always run regardless of config
- check_project() standard folder set updated to match init_project()
  v0.4.0: data-raw/, data/, scripts/, output/figures/, output/tables/,
  reports/
- check_project(error) deprecated – cli report now always prints, tibble
  always returned invisibly; deprecation warning fires when error =
  FALSE; removal planned for v0.6.0
- DESCRIPTION updated – jsonlite added to Imports, utils added to
  Imports, withr removed from Suggests (already in Imports)
- README updated – save_output() and generate_manifest() added to quick
  reference, core workflow sections, and first workflow example;
  check_project() section updated for config argument, new README
  detection behavior, and deprecated error argument; dependencies list
  updated
- NEWS.md updated – full v0.5.0 entry drafted
- PLAN.md updated – v0.5.0 completed items moved here; roadmap advanced
- JOURNAL.md updated – Session 6 added
- init_project() branding refactor – uw_branding deprecated via
  lifecycle::deprecate_warn(); new branding argument accepts TRUE
  (generic placeholders), “uw-madison” (RCI branding), “none”/FALSE (no
  assets). Explicit deprecation mapping: old TRUE -\> “uw-madison”, not
  TRUE (generic). Validation uses identical() per element over a list,
  not %in%, to avoid logical/character coercion issues. inst/assets/ now
  holds ten files under uw-\* and generic-\* prefix convention; copy
  step strips prefix and writes standardized destination names
  (logo.png, favicon.png, header.html, footer.html, styles.css). Old
  inst/extdata/ branding files removed; inst/templates/logo.png removed.
- create_qmd() branding updates – use_style detection now name-based
  (looks for styles.css, header.html, footer.html by exact name) rather
  than scanning for any .css/.html file and erroring on ambiguity.
  footer.html wired as include-after-body:. header.html confirmed as
  include-before-body: (not include-in-header:, which injects into ).
  logo.png exempt from overwrite – existing logo always preserved.
  favicon.png ships in asset set but not wired into per-document YAML
  (website-project option only). style_dir absolutized via
  fs::path_abs() before detection to fix path comparison edge case.
  .inject_style_yaml() updated: html_file -\> header_file
  - footer_file, favicon_file dropped.
- test-init-project.R rewritten – section 4 (branding) fully replaced:
  tests for TRUE/FALSE/“none”/“uw-madison” modes, standardized five-file
  inventory, identical filenames across modes, invalid branding error,
  deprecation warning, explicit uw_branding=TRUE-\>uw-madison mapping
  (br-11 reads first bytes of logo.png to confirm UW vs generic
  content).
- test-create-qmd.R updated – make_style_dir() helper gains footer.html;
  two multi-file-error tests removed (old contract gone); new tests for
  footer injection, partial asset sets, non-standardized file ignore,
  logo overwrite exemption; .inject_style_yaml() helper tests updated
  from html_file to header_file/footer_file.

------------------------------------------------------------------------

## Source file organization

    R/
    +-- init-project.R              # init_project(), .resolve_custom_folders(),
                                    #   generate_project_config()
    +-- create-qmd.R                # create_qmd(), .substitute_yaml(),
                                    #   .inject_style_yaml(), .relative_style_path()
    +-- read-clean-csv.R            # read_clean_csv()
    +-- write-clean-csv.R           # write_clean_csv()
    +-- detect-execution-context.R  # detect_execution_context()
    +-- write-by-group.R            # write_by_group()
    +-- run-by-group.R              # run_by_group()
    +-- generate-kb-xml.R           # generate_kb_xml()
    +-- check-project.R             # check_project(), .check_result(),
                                    #   .print_check_project(),
                                    #   .cli_escape(),
                                    #   .standard_folder_message()
    +-- save-output.R               # save_output(), .capture_function_name(),
                                    #   .flatten_field(), .accumulator_columns(),
                                    #   .ensure_directory(),
                                    #   .append_accumulator_row()
    +-- generate-manifest.R         # generate_manifest(), .read_accumulator(),
                                    #   .dedupe_accumulator()
    +-- arborize.R                  # arborize(), .build_arborize_qmd(),
                                    #   .write_arborize_provenance()
    +-- qmd-to-r.R                  # qmd_to_r()
    +-- toolero-package.R           # package sentinel,
                                    #   utils::globalVariables("results")

    inst/assets/
    +-- generic-logo.png            # placeholder logo for branding = TRUE
    +-- generic-favicon.png
    +-- generic-header.html
    +-- generic-footer.html
    +-- generic-styles.css
    +-- uw-logo.png                 # UW-Madison RCI branding for branding = "uw-madison"
    +-- uw-favicon.png
    +-- uw-header.html
    +-- uw-footer.html
    +-- uw-styles.css

    inst/extdata/
    +-- data-provenance.md          # Palmer Penguins provenance note

    inst/templates/
    +-- _quarto.yml
    +-- example.qmd
    +-- purl.R
    +-- sample.csv
    +-- skeleton.qmd

### Naming conventions

- Exported functions: snake_case
- Internal helpers: .dot_prefix()
- File names: kebab-case.R

------------------------------------------------------------------------

## v0.5.0 roadmap (remaining)

### High priority

- read_clean_tsv() and read_clean_parquet() – the two most immediately
  useful members of the read_clean\_\*() family. Both are flat
  rectangular formats that work cleanly with janitor::clean_names().
  Same argument signature as read_clean_csv(): na, drop_na, summary, …,
  returning tibbles. read_clean_json() and read_clean_sqlite() are
  deferred pending design decisions about nested structures and table
  selection.

- template argument for create_qmd(). Currently create_qmd() always uses
  the internal toolero template. Adding a template argument would allow
  curriculr’s create_cv() to delegate to create_qmd() for Quarto
  scaffolding instead of handling it independently. This is the primary
  blocker for restoring the intended delegation model across the package
  suite.

- read_clean_excel() – companion to read_clean_csv() via readxl. Same
  conventions: janitor::clean_names() as core, na, drop_na, summary,
  verbose, … arguments, returning tibbles.

- init_build_and_push() – scaffolds containr’s GitHub Actions
  build-and-push workflow into the user’s project. Signature:
  init_build_and_push(path = “.”, overwrite = FALSE, runner = “github”).
  Copies inst/templates/build-and-push.yaml (sourced from containr) into
  .github/workflows/, creating the directory if absent. Errors if file
  already exists and overwrite = FALSE. Prints cli-formatted next steps
  covering REGISTRY_USERNAME/REGISTRY_PASSWORD secrets, the committed
  Dockerfile assumption, and how to confirm success via the Actions tab.

### Medium priority

- arborize() v2 – R list input for structured notation. Currently the
  structured backend passes the user’s tree() string verbatim into
  \#render(). A future version could accept an R list structure and
  generate the nested tree() calls programmatically, removing the need
  for the user to know Typst syntax at all.

- arborize() node styling arguments. Expose lingotree’s layer-spacing,
  child-spacing, branch-stroke, and color parameters as R arguments so
  users can control appearance without writing Typst.

- arborize() SVG output option. Typst can produce SVG directly – offer
  it as an alternative to PNG for web embedding.

- rearborize() – re-render from a provenance .yaml file. Currently the
  manual pattern (read yaml, call arborize() with recovered fields) is
  only five lines and does not justify an exported function. Implement
  if user demand materializes via GitHub issues.

- toolero delegation from curriculr – once template argument is added to
  create_qmd(), restore create_cv() in curriculr to delegate to
  toolero::create_qmd() rather than handling scaffolding independently.

- split-apply vignette – document write_by_group() and run_by_group() as
  a paired workflow. Narrative arc: split once, iterate the analysis
  function, connect to submitr for scale.

- \_brand.yml support – future branding = “brand-yml” mode. Quarto’s
  \_brand.yml spec can absorb logo and favicon cleanly and propagates
  color palette and typography across formats (HTML, revealjs, Typst,
  Shiny). header.html/footer.html are outside its scope (raw HTML
  includes) and styles.css becomes a supplementary SCSS layer rather
  than a direct equivalent. Implementation requires encoding actual
  brand data (colors, fonts) rather than just copying files – set aside
  pending design work on what a sensible generic and UW-madison
  \_brand.yml default would contain.

### Lower priority

- generate_kb_xml() improvements – better handling of edge cases in HTML
  body extraction, support for documents with complex asset structures.

- lifecycle::badge() calls in exported function documentation – mark
  individual functions with appropriate lifecycle stages in their
  roxygen blocks.

- Snapshot testing for create_qmd() and generate_kb_xml() – verify
  output files match expected structure.

- glossify() – Typst interlinear gloss blocks per Leipzig Glossing
  Rules; arguments target, explicit, morph, reading, label; backend
  package choice (eggs vs. leipzig-glossing) still open. Returns Typst
  string for inline use, not disk write. Implementation deferred.

- save_output() / generate_manifest() convention for unattended rscript
  execution: document the manual tryCatch({ … }, finally =
  try(generate_manifest(), silent = TRUE)) pattern for CHTC jobs where
  nobody is watching in real time. The try() is essential – a crash
  before the first save_output() call leaves no accumulator, so a bare
  generate_manifest() inside finally would replace the original error
  with a manifest-not-found error in the job log. Documentation guidance
  only, not a function toolero provides.

- check_project(error): remove the deprecated argument entirely in
  v0.6.0.

- uw_branding: remove the deprecated argument entirely in v0.6.0.

------------------------------------------------------------------------

## Function inventory (current, v0.4.0.9000)

| Function | Description |
|----|----|
| init_project() | Creates R project with standard folder structure |
| generate_project_config() | Writes a skeleton YAML project config file |
| create_qmd() | Scaffolds Quarto document from reproducible template |
| read_clean_csv() | Reads CSV, cleans names, handles missing values |
| write_clean_csv() | Writes cleaned data frame to CSV with cli feedback |
| detect_execution_context() | Identifies interactive/quarto/rscript environment |
| write_by_group() | Splits data frame by group, writes CSVs, optional manifest |
| run_by_group() | Applies a function to each group subset, collects results |
| save_output() | Writes object via user-supplied function, records in accumulator |
| generate_manifest() | Reads accumulator, writes project-manifest.json |
| generate_kb_xml() | Produces UW-Madison KB importable XML |
| check_project() | Audits project structure against toolero conventions |
| arborize() | Renders syntactic tree as PNG via Quarto + Typst |
| qmd_to_r() | Extracts R code from a Quarto document into a .R script |

------------------------------------------------------------------------

## Relationship to containr and submitr

    toolero v0.4.0.9000
      +-- branding refactor -- init_project(branding = ) replaces uw_branding;
          five standardized asset names in assets/ regardless of branding mode;
          create_qmd() updated to match (footer, name-based detection, logo
          overwrite exemption)
      +-- containr ripple documented -- containr::generate_dockerfile() users
          should pass misc_file = "assets/" to copy branding files into the
          container when create_qmd(use_style = TRUE) is used; documented in
          containr's @param misc_file and @section Prerequisites
      +-- CRAN submission planned (as v0.5.0)
      When ready to push to CRAN:
        devtools::check() clean
        rhub::rhub_check(platforms = c("linux", "macos", "macos-arm64", "windows"))
        devtools::check_win_devel() and devtools::check_win_release()
        Update cran-comments.md
        usethis::use_version("minor")
        devtools::submit_cran()

    containr v0.2.0
      +-- CRAN submission pending
      +-- Will eventually depend on toolero
      +-- misc_file = "assets/" documented as the path for branding file
          inclusion; no code change needed, existing vectorized misc_file
          already handles directories

    submitr v0.1.0
      +-- CRAN submission pending
      +-- manifest from write_by_group() is input to htc_gen_submit() in
          multiple-job mode -- direct integration point with toolero
      +-- project-manifest.json from generate_manifest() is the downstream
          record of what a CHTC job produced -- relevant to encapsulr::describe()

------------------------------------------------------------------------

## Open design questions

1.  Should arborize() eventually support a notation = “lingotree_r” mode
    that accepts an R list structure and generates nested tree() calls
    programmatically? This would remove the Typst knowledge requirement
    for the structured backend.

2.  Should create_qmd() gain a template argument in v0.5.0 to support
    curriculr delegation, or should curriculr continue to handle its own
    scaffolding independently?

3.  Should read_clean\_\*() functions grow into a larger family or stay
    minimal? The family could expand significantly if demand emerges.
    Current plan: tsv and parquet in v0.5.0, json and sqlite deferred.

4.  Should arborize() cache the rendered PDF alongside the PNG so that
    subsequent calls with the same tree string and settings skip the
    render step? Useful for documents with many trees.

5.  Should the informational message about which Typst package is being
    used be gated behind a verbose argument? Currently fires on every
    call. Useful for debugging but potentially chatty in production use.

6.  Should run_by_group() gain a progress bar via
    cli::cli_progress_bar() for sequential execution? Currently verbose
    = TRUE emits one message per group but does not render a progress
    bar.

7.  Should save_output() / generate_manifest() vignette be written as a
    companion to the split-apply vignette, covering the full arc from
    write_by_group() through run_by_group() through save_output() and
    generate_manifest()?

8.  Should \_brand.yml be adopted as branding = “brand-yml” in a future
    version? The spec absorbs logo and favicon cleanly and propagates
    brand identity across Quarto formats and Shiny.
    header.html/footer.html remain outside its scope. Implementation
    requires encoding color and typography data, not just copying files
    – deferred pending design work.
