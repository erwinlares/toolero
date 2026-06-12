# toolero -- Package Development Plan

## What is toolero?

toolero is an R package designed to help researchers implement best practices
for their coding projects. It provides a small set of opinionated, practical
functions that reduce friction at the start of a project and during day-to-day
data work.

toolero is the foundational package in the *From the Notebook to the Cluster*
three-package suite:

```
toolero     -- research workflow toolkit (CRAN v0.4.0)
containr    -- Docker containerization toolkit (CRAN pending)
submitr     -- CHTC job submission toolkit (CRAN pending)
```

---

## Package identity

- Name: toolero
- On CRAN at v0.3.0, v0.4.0 developed and pushed to GitHub
- CRAN submission planned for July 2026 (CRAN resubmission policy)
- MIT license
- Influenced by The Carpentries and UW-Madison Libraries workshop practices
- UW-Madison RCI branding baked into templates

---

## Completed: v0.1.0

- init_project() -- standard folder structure, optional renv and git

## Completed: v0.1.1

- init_project() uw_branding argument -- copies RCI assets into assets/

## Completed: v0.2.0

- detect_execution_context() -- identifies interactive, quarto, rscript
- create_qmd() -- Quarto document scaffolding with UW branding and template
- write_by_group() -- splits data frame by group, writes CSVs

## Completed: v0.3.0

- generate_kb_xml() -- produces UW-Madison KB importable XML from Quarto docs
- create_qmd() use_purl argument -- post-render R code extraction hook
- Breaking changes: filename first in create_qmd(), dash separators in
  write_by_group(), file_path renamed to path in init_project()

## Completed: v0.4.0

- arborize() -- syntactic tree renderer with simple and structured notation
- .build_arborize_qmd() -- internal builder, fully tested without Quarto
- .write_arborize_provenance() -- writes companion .yaml provenance file
- Palmer Penguins credit in create_qmd() roxygen, template, DATA-PROVENANCE.md
- Lifecycle badge (stable) and Codecov coverage badge
- test-coverage GitHub Action
- arborize vignette with papersize/margin crop guidance
- JOURNAL.md and PLAN.md added, in .Rbuildignore
- .substitute_yaml() naming fix -- internal helper renamed from substitute_yaml()
- read_clean_csv() extended -- na, drop_na, summary, ... arguments added
- write_clean_csv() -- new exported function
- check_project() -- new exported function
- qmd_to_r() -- extracts R code from any .qmd into a standalone .R script
- run_by_group() -- applies a function to each group subset, collects results;
  supports manifest or named-list input, parallel execution via furrr/future,
  tabular and non-tabular output routing
- DESCRIPTION updated -- furrr and future added to Suggests, dplyr moved to
  Suggests, rlang := imported
- README updated -- run_by_group() added to quick reference and core workflow
  sections; first three sections rewritten to reflect From the Notebook to
  the Cluster family name
- NEWS.md updated -- full v0.4.0 entry drafted
- cran-comments.md drafted -- skeleton with progressive update markers

---

## Source file organization

```
R/
+-- init-project.R              # init_project()
+-- create-qmd.R                # create_qmd(), .substitute_yaml()
+-- read-clean-csv.R            # read_clean_csv()
+-- write-clean-csv.R           # write_clean_csv()
+-- detect-execution-context.R  # detect_execution_context()
+-- write-by-group.R            # write_by_group()
+-- run-by-group.R              # run_by_group()
+-- generate-kb-xml.R           # generate_kb_xml()
+-- check-project.R             # check_project(), .check_result(),
                                #   .print_check_project()
+-- arborize.R                  # arborize(), .build_arborize_qmd(),
                                #   .write_arborize_provenance()
+-- qmd-to-r.R                  # qmd_to_r()
+-- toolero-package.R           # package sentinel,
                                #   utils::globalVariables("results")
```

### Naming conventions

- Exported functions: snake_case
- Internal helpers: .dot_prefix()
- File names: kebab-case.R

---

## v0.5.0 roadmap

### High priority

- read_clean_tsv() and read_clean_parquet() -- the two most immediately
  useful members of the read_clean_*() family. Both are flat rectangular
  formats that work cleanly with janitor::clean_names(). Same argument
  signature as read_clean_csv(): na, drop_na, summary, ..., returning
  tibbles. read_clean_json() and read_clean_sqlite() are deferred pending
  design decisions about nested structures and table selection.

- template argument for create_qmd(). Currently create_qmd() always uses
  the internal toolero template. Adding a template argument would allow
  curriculr's create_cv() to delegate to create_qmd() for Quarto scaffolding
  instead of handling it independently. This is the primary blocker for
  restoring the intended delegation model across the package suite.

- read_clean_excel() -- companion to read_clean_csv() via readxl. Same
  conventions: janitor::clean_names() as core, na, drop_na, summary, verbose,
  ... arguments, returning tibbles.

### Medium priority

- arborize() v2 -- R list input for structured notation. Currently the
  structured backend passes the user's tree() string verbatim into #render().
  A future version could accept an R list structure and generate the nested
  tree() calls programmatically, removing the need for the user to know
  Typst syntax at all.

- arborize() node styling arguments. Expose lingotree's layer-spacing,
  child-spacing, branch-stroke, and color parameters as R arguments so users
  can control appearance without writing Typst.

- arborize() SVG output option. Typst can produce SVG directly -- offer it
  as an alternative to PNG for web embedding.

- rearborize() -- re-render from a provenance .yaml file. Currently the
  manual pattern (read yaml, call arborize() with recovered fields) is only
  five lines and does not justify an exported function. Implement if user
  demand materializes via GitHub issues.

- toolero delegation from curriculr -- once template argument is added to
  create_qmd(), restore create_cv() in curriculr to delegate to
  toolero::create_qmd() rather than handling scaffolding independently.

- split-apply vignette -- document write_by_group() and run_by_group() as a
  paired workflow. Narrative arc: split once, iterate the analysis function,
  connect to submitr for scale.

### Lower priority

- generate_kb_xml() improvements -- better handling of edge cases in HTML
  body extraction, support for documents with complex asset structures.

- lifecycle::badge() calls in exported function documentation -- mark
  individual functions with appropriate lifecycle stages in their roxygen
  blocks.

- Snapshot testing for create_qmd() and generate_kb_xml() -- verify output
  files match expected structure.

---

## Function inventory (current, v0.4.0)

| Function | Description |
|---|---|
| init_project() | Creates R project with standard folder structure |
| create_qmd() | Scaffolds Quarto document from reproducible template |
| read_clean_csv() | Reads CSV, cleans names, handles missing values |
| write_clean_csv() | Writes cleaned data frame to CSV with cli feedback |
| detect_execution_context() | Identifies interactive/quarto/rscript environment |
| write_by_group() | Splits data frame by group, writes CSVs, optional manifest |
| run_by_group() | Applies a function to each group subset, collects results |
| generate_kb_xml() | Produces UW-Madison KB importable XML |
| check_project() | Audits project structure against toolero conventions |
| arborize() | Renders syntactic tree as PNG via Quarto + Typst |
| qmd_to_r() | Extracts R code from a Quarto document into a .R script |

---

## Relationship to containr and submitr

```
toolero v0.4.0
  +-- run_by_group() added -- completes the split-apply workflow
  +-- pushed to GitHub
  +-- CRAN submission planned July 2026
  When ready to push to CRAN:
    devtools::check() clean
    devtools::check_rhub() for cross-platform verification
    Update cran-comments.md (skeleton drafted, append as work continues)
    devtools::submit_cran()

containr v0.1.2
  +-- CRAN submission pending
  +-- Will eventually depend on toolero

submitr v0.1.0
  +-- CRAN submission pending
  +-- manifest from write_by_group() is input to htc_gen_submit() in
      multiple-job mode -- direct integration point with toolero
```

---

## Open design questions

1. Should arborize() eventually support a notation = "lingotree_r" mode
   that accepts an R list structure and generates nested tree() calls
   programmatically? This would remove the Typst knowledge requirement for
   the structured backend.

2. Should create_qmd() gain a template argument in v0.5.0 to support
   curriculr delegation, or should curriculr continue to handle its own
   scaffolding independently?

3. Should read_clean_*() functions grow into a larger family or stay minimal?
   The family could expand significantly if demand emerges. Current plan:
   tsv and parquet in v0.5.0, json and sqlite deferred.

4. Should arborize() cache the rendered PDF alongside the PNG so that
   subsequent calls with the same tree string and settings skip the render
   step? Useful for documents with many trees.

5. Should the informational message about which Typst package is being used
   be gated behind a verbose argument? Currently fires on every call.
   Useful for debugging but potentially chatty in production use.

6. Should run_by_group() gain a progress bar via cli::cli_progress_bar()
   for sequential execution? Currently verbose = TRUE emits one message per
   group but does not render a progress bar.
