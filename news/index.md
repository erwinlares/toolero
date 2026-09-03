# Changelog

## toolero 0.4.0.9000

#### Breaking changes

- [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md):
  the `uw_branding` argument is deprecated in favor of the new
  `branding` argument. `uw_branding = TRUE` maps to
  `branding = "uw-madison"` (not `branding = TRUE`, which now means
  generic placeholder assets); `uw_branding = FALSE` maps to
  `branding = "none"`. A
  [`lifecycle::deprecate_warn()`](https://lifecycle.r-lib.org/reference/deprecate_soft.html)
  fires when `uw_branding` is supplied. Removal planned for v0.6.0
  alongside `check_project(error)`.

- [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md):
  the `use_style` argument now detects branding files by standardized
  name (`styles.css`, `header.html`, `footer.html`) rather than scanning
  for any `.css` or `.html` file and erroring on ambiguity. Custom
  directories are the user’s responsibility to populate under these
  exact names. The old “error when multiple `.css` or `.html` files
  found” behavior is removed.

- [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md):
  `footer.html` is now separately wired as `include-after-body:` in the
  generated YAML, a new Quarto YAML key not present in previous
  versions. Projects using `use_style = TRUE` will now have a footer
  included if `assets/footer.html` exists.

- [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md):
  now creates a `README.md` file at the project root by default. The new
  `use_readme` argument defaults to `TRUE`; calls that previously
  created no README – which was all of them, since the argument did not
  exist – will now produce one. Pass `use_readme = FALSE` to opt out and
  preserve the old behavior.

#### New features

- [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md):
  new `branding` argument replacing `uw_branding`. Accepts `TRUE`
  (generic placeholder assets), `"uw-madison"` (UW-Madison RCI
  branding), or `"none"`/`FALSE` (no assets folder). All modes produce
  the same five standardized filenames in `assets/`: `logo.png`,
  `favicon.png`, `header.html`, `footer.html`, `styles.css` – so
  downstream consumers
  ([`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md),
  `containr::generate_dockerfile()`) can reference those names
  regardless of which branding mode was used.

- [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md):
  new `use_readme` argument controlling whether a README is created at
  the project root. `TRUE` (default) creates `README.md`; `"plain"`
  creates `README.txt` with identical content – only the extension
  differs; `FALSE` creates no README. Both formats copy the same file,
  `inst/templates/readme-template.md`: a generalist guide that explains
  what a README is and why it matters, lays out a recommended section
  structure covering material shared by all research artifacts as well
  as software-specific and data-specific sections, and defers detailed
  guidance to the Cornell Data Services README guides rather than
  reproducing them. If a README already exists at the destination,
  [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
  aborts with an informative message instead of overwriting it.

- [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md):
  `use_style = TRUE` now wires all three styling files present in
  `assets/` – `styles.css` as `css:`, `header.html` as
  `include-before-body:`, and `footer.html` as `include-after-body:` –
  rather than only `css:` and one HTML include. Any subset may be
  present; only files that exist are injected.

- [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md):
  `assets/logo.png` is now exempt from `overwrite`. An existing logo
  (e.g. placed by `init_project(branding = )`) is always left in place
  even when `overwrite = TRUE`, since a generic placeholder silently
  replacing institutional branding would be surprising. All other files
  (`sample.csv`, `_quarto.yml`, `purl.R`, the `.qmd` itself) continue to
  respect `overwrite`.

#### Internal changes

- `inst/assets/` now contains ten files under a `uw-*` / `generic-*`
  prefix convention: `uw-logo.png`, `uw-favicon.png`, `uw-header.html`,
  `uw-footer.html`, `uw-styles.css`, and five `generic-*` counterparts.
  The copy step in
  [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
  strips the prefix and writes standardized names into the project’s
  `assets/` directory. The old three-file UW set (`rci-banner.png`,
  `header.html`, `styles.css`) in `inst/extdata/` has been removed;
  `inst/extdata/` now contains only `data-provenance.md`.

- `inst/templates/logo.png` removed. The generic placeholder logo is now
  `inst/assets/generic-logo.png`, which
  `create_qmd(include_examples = TRUE)` copies into `assets/logo.png`
  when no logo already exists.

- `.inject_style_yaml()` gains `header_file` and `footer_file` arguments
  (replacing the old single `html_file` argument), maps them to
  `include-before-body:` and `include-after-body:` respectively, and
  drops the `favicon_file` argument (favicon wiring belongs in
  `_quarto.yml` as a website-project option, not in the per-document
  YAML).

- `style_dir` is absolutized via
  [`fs::path_abs()`](https://fs.r-lib.org/reference/path_math.html) in
  [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
  before style detection, ensuring
  [`fs::path_rel()`](https://fs.r-lib.org/reference/path_math.html)
  comparisons are valid when a relative `use_style` path is combined
  with an absolute `path` argument.

- Added `inst/templates/readme-template.md`, the generalist README
  template copied by
  [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)’s
  new `use_readme` argument.

## toolero 0.4.0.9000 (prior development entries)

#### New features

- Added
  [`save_output()`](https://erwinlares.github.io/toolero/reference/save_output.md)
  for writing an object to disk via a user-supplied function and
  recording the write in a project-level accumulator at
  `output_dir/accumulator.csv`. The accumulator is append-only and
  carries one row per call, recording `file_path`, `r_class`,
  `timestamp`, `function_used`, `status`, `error_message`, and `note`.
  The call to the write function is wrapped in a narrowly-scoped
  [`tryCatch()`](https://rdrr.io/r/base/conditions.html) – only that
  call, not the rest of
  [`save_output()`](https://erwinlares.github.io/toolero/reference/save_output.md)’s
  body – so a failed write is recorded with `status = "failure"` and the
  caught error message before the original condition is rethrown
  unmodified, preserving condition class and traceback. Missing
  destination directories are created automatically and reported.
- Added
  [`generate_manifest()`](https://erwinlares.github.io/toolero/reference/generate_manifest.md)
  for reading the project accumulator, collapsing it to one row per
  output file (keeping the latest write per path, since the accumulator
  may contain superseded rows from reruns within a session), and writing
  `project-manifest.json`. The manifest records `execution_context` and
  `generated_at` once at the top level, followed by an `artifacts` array
  with one entry per deduplicated output, ordered chronologically. Field
  names are toolero-native rather than RO-Crate vocabulary – that
  translation belongs in `encapsulr::describe()` as a thin mapping
  layer. Checksums are deliberately excluded: `rocrateR::bag_rocrate()`
  computes `manifest-sha512.txt` at bagging time, and duplicating that
  here would create a second record to keep in sync. A missing
  accumulator is an error; an accumulator with no rows produces an empty
  manifest with a warning.

#### Improvements

- [`check_project()`](https://erwinlares.github.io/toolero/reference/check_project.md):
  README detection is now case-insensitive and extension-agnostic. Any
  file whose stem matches `readme` (in any capitalization) is
  recognized, regardless of extension or the absence of one. Previously
  only `README.md`, `README.Rmd`, and `README.qmd` were checked, all
  case-sensitively, missing common variants like `readme.md` or a plain
  `README` on Linux (issue
  [\#11](https://github.com/erwinlares/toolero/issues/11)).
- [`check_project()`](https://erwinlares.github.io/toolero/reference/check_project.md):
  the standard folder set now matches
  [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
  – `data-raw/`, `data/`, `scripts/`, `output/figures/`,
  `output/tables/`, and `reports/`. The previous hardcoded set
  (`data-raw/`, `data/`, `docs/`) was stale relative to the v0.4.0
  breaking change to
  [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md).
- [`check_project()`](https://erwinlares.github.io/toolero/reference/check_project.md):
  new `config` argument accepts a path to a YAML file produced by
  [`generate_project_config()`](https://erwinlares.github.io/toolero/reference/generate_project_config.md).
  When supplied, the `folders:` list in the file replaces the standard
  toolero folder set for the folder checks. Non-folder hygiene checks
  (`.Rproj`, `renv.lock`, git, `.gitignore`, README, and hidden files)
  always run regardless of the config. Folders declared in the config
  but missing from the project are reported as `"fail"` rather than
  `"warn"` – the user declared them explicitly, so their absence is a
  conformance failure rather than an advisory (issue
  [\#12](https://github.com/erwinlares/toolero/issues/12)).

#### Deprecated features

- `check_project(error)`: the `error` argument is deprecated and will be
  removed in v0.6.0. The cli report now always prints and the tibble is
  always returned invisibly. To access results programmatically, assign
  the output directly: `out <- check_project()`. Passing `error = FALSE`
  continues to work but triggers a deprecation warning.

## toolero 0.4.0

CRAN release: 2026-07-16

#### New features

- Added
  [`run_by_group()`](https://erwinlares.github.io/toolero/reference/run_by_group.md),
  the apply half of the split-apply workflow. Accepts either a manifest
  CSV produced by `write_by_group(manifest = TRUE)` or a named list of
  data frames. Applies a user-supplied function to each group subset and
  collects the results into a flat tibble (when the function returns a
  data frame) or a nested tibble with a list-column (when it returns
  anything else). Supports parallel execution via `furrr` and `future`
  through the `workers` argument, with a ceiling at
  `max(1L, parallelly::availableCores() - 1L)` to reserve one core for
  the main session. A `seed` argument enables reproducible parallel
  execution for analyses involving randomness.
- Added
  [`read_clean_csv()`](https://erwinlares.github.io/toolero/reference/read_clean_csv.md)
  for reading CSV files into a tibble with
  [`janitor::clean_names()`](https://sfirke.github.io/janitor/reference/clean_names.html)
  applied automatically. Supports explicit missing-value codes via `na`,
  selective row dropping via `drop_na` (accepts `TRUE` or a character
  vector of column names), an optional ingest summary via `summary`, and
  pass-through arguments to
  [`readr::read_csv()`](https://readr.tidyverse.org/reference/read_delim.html)
  via `...`.
- Added
  [`write_clean_csv()`](https://erwinlares.github.io/toolero/reference/write_clean_csv.md)
  for writing data frames to CSV with clean column names. Applies
  [`janitor::clean_names()`](https://sfirke.github.io/janitor/reference/clean_names.html)
  if column names are not already clean and reports affected columns via
  cli feedback.
- Added
  [`check_project()`](https://erwinlares.github.io/toolero/reference/check_project.md)
  for auditing a project directory against toolero conventions. Checks
  for expected folders, an `.Rproj` file, `renv.lock`, a git repository,
  a README, a `.gitignore`, and hidden files such as `.RData` or
  `.Rhistory`. Operates in two modes: a cli report (default) or a tibble
  return for programmatic use (`error = FALSE`).
- Added
  [`qmd_to_r()`](https://erwinlares.github.io/toolero/reference/qmd_to_r.md)
  for extracting R code chunks from any `.qmd` file into a standalone
  `.R` script via
  [`knitr::purl()`](https://rdrr.io/pkg/knitr/man/knit.html). The output
  path defaults to the same directory as the input with the extension
  replaced. The `documentation` argument controls how much context is
  preserved in the extracted script.
- Added
  [`generate_project_config()`](https://erwinlares.github.io/toolero/reference/generate_project_config.md)
  for writing a skeleton YAML project configuration file pre-filled with
  the standard toolero folder structure. Intended to be edited by the
  user and passed to
  [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
  via the new `config` argument. `filename` is required and explicit;
  `path` defaults to `"."`. An `overwrite` argument (default `FALSE`)
  guards against accidental replacement of an existing config. The file
  extension is normalized to `.yml` regardless of what is supplied.
- Added Palmer Penguins attribution (Horst, Hill & Gorman, 2020) to the
  template `.qmd`, the
  [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
  roxygen `@details` section, and a provenance note in `inst/extdata/`.

#### Breaking changes

- [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md):
  the standard folder structure has been revised to better reflect
  research workflow conventions established by The Carpentries and
  UW-Madison Libraries. The new standard set is `data-raw/`, `data/`,
  `scripts/`, `output/figures/`, `output/tables/`, and `reports/`. The
  previous set (`data/`, `data-raw/`, `images/`, `plots/`, `results/`,
  `scripts/`, `docs/`, `R/`) is no longer created by default.
- [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md):
  `extra_folders` has been renamed to `custom_folders`. The argument now
  supports a dplyr-select-like syntax: bare names add folders
  (e.g. `"models"`), names prefixed with `"-"` suppress creation of that
  folder from the resolved set (e.g. `"-output/figures"`). Suppression
  removes only the named leaf – parent directories are preserved.
  Duplicate additions emit an informational message and are skipped;
  references to non-existent folders via `"-"` emit a warning.
- [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md):
  no longer copies `styles.css` and `header.html` from the package into
  the project. Custom styling is now controlled exclusively by the new
  `use_style` argument. Projects that relied on
  [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
  copying UW-branded assets should use
  `init_project(branding = "uw-madison")` to scaffold those files, then
  pass `use_style = TRUE` to
  [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
  to wire them into the YAML.
- [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md):
  sample data is now copied into `data-raw/` instead of `data/`,
  consistent with
  [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)’s
  folder structure.

#### New features (continued from above)

- [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md):
  added `config` argument. When supplied, the folder list in the YAML
  file replaces the built-in standard structure entirely.
  `custom_folders` is still applied on top of the config-derived set.
  Configs are produced by
  [`generate_project_config()`](https://erwinlares.github.io/toolero/reference/generate_project_config.md)
  and can be stored in the user home directory for reuse across project
  types.
- [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md):
  added `include_examples` argument (default `TRUE`). When `TRUE`,
  copies a sample dataset (`sample.csv`) into `data-raw/`, a placeholder
  logo (`logo.png`) into `assets/`, and uses a worked example template
  with a `params` block referencing the sample data. When `FALSE`,
  creates a blank skeleton `.qmd` with only the YAML header and a setup
  chunk – no sample data, no logo, no example analysis block.
- [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md):
  added `use_style` argument (default `FALSE`). Accepts `FALSE` (no
  custom styling), `TRUE` (scans `assets/` for standardized branding
  files by name), or a directory path (scans that directory instead).
  `styles.css` is added as `css:`, `header.html` as
  `include-before-body:`, and `footer.html` as `include-after-body:`.
  Only files that exist are wired into the YAML.
- Added `inst/templates/skeleton.qmd` – a minimal Quarto template used
  when `include_examples = FALSE`. Contains the YAML header, a setup
  chunk with
  [`library(toolero)`](https://github.com/erwinlares/toolero), and a
  single placeholder heading.
- [`write_by_group()`](https://erwinlares.github.io/toolero/reference/write_by_group.md):
  `group_col` now accepts a character vector of column names, enabling
  grouping by more than one column at once. Sanitized filenames join
  multiple columns with `--` (e.g. `group_col = c("species", "sex")` on
  an Adelie male produces `adelie--male.csv`); only combinations
  actually present in the data produce files, not the full cross-product
  of possible values. When `manifest = TRUE`, the manifest gains one
  column per grouping variable (holding the raw, unsanitized value) in
  addition to a composite `group_value` column joining the raw values
  with `" | "`. Single-column calls are unaffected – filenames, manifest
  schema, and behavior are unchanged from previous versions.
- [`write_by_group()`](https://erwinlares.github.io/toolero/reference/write_by_group.md):
  added `drop_na` argument (default `TRUE`). Rows with a missing value
  in any grouping column are dropped before splitting, with a cli
  message reporting how many rows were dropped and from which column(s)
  – this was previously silent, undocumented behavior inherited from
  [`split()`](https://rdrr.io/r/base/split.html). Set `drop_na = FALSE`
  to instead treat missing values as their own group rather than
  dropping them.

#### Bug fixes

- [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md):
  `use_style = TRUE` now correctly copies `rci-banner.png` from
  `inst/assets/` into the project `assets/` directory. Previously the
  banner was only copied inside the `include_examples` block and was
  silently omitted when `use_style = TRUE` was combined with
  `include_examples = FALSE`.
- [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md):
  `filename` argument now normalizes the file extension to `.qmd` via
  [`fs::path_ext_set()`](https://fs.r-lib.org/reference/path_file.html).
  Passing `"my-document"` and `"my-document.qmd"` both produce
  `my-document.qmd`; a double extension is never added.
- [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md):
  path construction now uses
  [`fs::path()`](https://fs.r-lib.org/reference/path.html) throughout
  rather than `glue::glue("{path}/{folder}")`, ensuring correct behavior
  on all platforms.
- [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md):
  branding files are now copied from `inst/assets/` rather than
  `inst/extdata/`, consistent with the rest of the package.

## toolero 0.3.0

CRAN release: 2026-04-27

#### Breaking changes

- [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md):
  `filename` is now the first argument and has no default – it must be
  supplied explicitly. `path` is now the second argument and defaults to
  `"."`, allowing natural calls like `create_qmd("analysis.qmd")`.
- [`write_by_group()`](https://erwinlares.github.io/toolero/reference/write_by_group.md):
  sanitized output filenames now use `-` (dash) as the separator instead
  of `_` (underscore), consistent with the package convention that file
  names use dashes. Existing workflows that reference output paths by
  name will need to update accordingly.
- [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md):
  the `file_path` argument has been renamed to `path` for consistency
  with
  [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
  and the broader package API. Calls using `file_path =` by name will
  error; positional calls are unaffected.

#### New features

- Added
  [`generate_kb_xml()`](https://erwinlares.github.io/toolero/reference/generate_kb_xml.md)
  to produce UW-Madison KB-importable XML files from rendered Quarto
  documents. Extracts metadata from the `.qmd` YAML header and
  re-renders with embedded resources for self-contained import.
- [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md):
  added `use_purl` argument (default `TRUE`) that scaffolds a
  `_quarto.yml` post-render hook and a `purl.R` script for extracting R
  code from rendered documents into `R/`.

#### Bug fixes

- [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md):
  now runs
  [`renv::snapshot()`](https://rstudio.github.io/renv/reference/snapshot.html)
  and creates `.renvignore` after
  [`renv::init()`](https://rstudio.github.io/renv/reference/init.html),
  ensuring the lockfile is populated and `.qmd` files are excluded from
  dependency scanning at project creation time.
- [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md):
  `_quarto.yml` is now copied from `inst/templates/` rather than written
  from a hardcoded string, so changes to the template are reflected
  automatically.
- [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md):
  `purl.R` is now correctly placed in `R/` instead of the project root,
  consistent with `_quarto.yml` calling `Rscript R/purl.R`.
- [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md):
  fixed YAML boolean serialization when `yaml_data` is supplied.
  [`yaml::as.yaml()`](https://yaml.r-lib.org/reference/as.yaml.html) was
  converting `true`/`false` to `yes`/`no`, which Quarto does not
  recognize. A custom handler now forces unquoted `true`/`false` output.
- `inst/templates/purl.R`: replaced `QUARTO_DOCUMENT_PATH` environment
  variable approach with
  [`fs::dir_ls()`](https://fs.r-lib.org/reference/dir_ls.html) glob
  scan, which works reliably regardless of how Quarto invokes the
  post-render script.

## toolero 0.2.0

CRAN release: 2026-04-24

#### Breaking changes

- [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md):
  `path` is now a required argument with no default. Passing `NULL` or
  omitting it raises an error. Use
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html) for temporary
  output.
- [`write_by_group()`](https://erwinlares.github.io/toolero/reference/write_by_group.md):
  `output_dir` is now a required argument with no default. Passing
  `NULL` or omitting it raises an error. Use
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html) for temporary
  output.
- [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md):
  `open` now defaults to `FALSE` instead of `TRUE` to avoid disrupting
  the current RStudio session in non-interactive contexts.

#### New features

- Added
  [`detect_execution_context()`](https://erwinlares.github.io/toolero/reference/detect_execution_context.md)
  to identify whether code is running in an interactive R session, a
  `quarto render` call, or a plain `Rscript` invocation. Returns one of
  `"interactive"`, `"quarto"`, or `"rscript"`.
- Added
  [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
  to scaffold a new Quarto document from a reproducible template,
  including a sample dataset, UW-Madison branded assets, and
  three-context input resolution via
  [`detect_execution_context()`](https://erwinlares.github.io/toolero/reference/detect_execution_context.md).
  Optionally pre-populates the YAML header from a user-supplied YAML
  config file.
- Added
  [`write_by_group()`](https://erwinlares.github.io/toolero/reference/write_by_group.md)
  to split a data frame by a single grouping column and write each group
  to a separate CSV file. Filenames are derived from sanitized group
  values. Optionally writes a `manifest.csv` listing output files, group
  values, and row counts.

## toolero 0.1.1

#### New features

- Added `uw_branding` argument to
  [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md).
  When `TRUE`, creates an `assets/` folder in the new project and
  populates it with UW-Madison RCI branding files (`styles.css`,
  `header.html`, `rci-banner.png`).

## toolero 0.1.0

- Initial CRAN submission.
