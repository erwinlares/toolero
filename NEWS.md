# toolero 0.5.0


### Breaking changes

* `create_qmd()`: both bundled templates now set
  `format: html: embed-resources: true` rather than stating the Quarto
  default of `false`. A non-self-contained HTML depends on the `_files/`
  sidecar directory rendered beside it, and nothing that moves these
  documents around knows about sidecars: `submitr::htc_gen_executable()`
  archives a folder, an emailed report is one file, and a rendered
  document committed next to its analysis quietly depends on a directory
  nobody thinks to copy. The cost of `true` is a larger file; the cost of
  `false` is an artifact that works only on the machine that made it. Set
  it back in your own header if you would rather have the sidecar.

* `init_project()`: uses `renv::scaffold()` instead of `renv::init()` when
  `use_renv = TRUE`, no longer writes a `.renvignore` containing `*.qmd`, and
  no longer takes a snapshot at creation time.

  `renv::init()` loads the newly created project into the **calling** R
  session, repointing `.libPaths()` at a library that is empty apart from
  `renv` itself. Every package the caller had available disappears until they
  restart R, which surfaces later as confusing `there is no package called
  ...` errors having nothing to do with the project just created. The
  `restart` argument suppresses the restart, not the activation, and
  `bare = TRUE` skips dependency discovery but still loads. `renv::scaffold()`
  creates the same infrastructure -- `renv/library`, `renv/activate.R`,
  `renv/.gitignore`, an `.Rprofile` that activates the project in future
  sessions, and an initial `renv.lock` -- and leaves the caller's session
  untouched.

  The `.renvignore` excluded Quarto documents from `renv`'s dependency
  discovery, so a project whose `library()` calls live in its `.qmd` source
  -- the arrangement this package recommends -- could snapshot a lockfile
  with none of the analysis packages in it, and
  `containr::generate_dockerfile()` would then build an image that could not
  run the analysis. The file was written at a point in `init_project()` where
  the project contained no `.qmd` files at all, so it never affected the
  snapshot taken at creation time; its only effect was on every snapshot the
  user took afterwards. Take a snapshot yourself once the project has code in
  it, and before containerizing. Projects created by earlier versions still
  carry the file and should have it removed by hand.

* `write_by_group()`: the job manifest now has one schema regardless of how
  many grouping columns were supplied. One column per grouping variable
  holding the raw value, then `group_value`, `n_rows`, `file_path`. Grouping
  on a single column previously produced only the last three; it now also
  carries the grouping column, whose value repeats `group_value` exactly.
  That redundancy is deliberate -- one schema with a varying column count is
  easier to read, validate and rely on than two schemas selected by how many
  columns you happened to group on. `run_by_group()` and
  `submitr::htc_gen_submit()` read `group_value` and `file_path` and are
  unaffected.

* `write_by_group()`: groups are now written, and manifest rows recorded, in
  order of first appearance in the data rather than in sort order of the
  sanitized key. Numeric groups no longer come out `10, 11, 9`. This is more
  than cosmetic: `submitr` writes `subdatasets.csv` in manifest order,
  HTCondor assigns `ProcId` in that order, and log filenames are
  reconstructed from position, so manifest row order is the mapping from a
  job number back to a group. The caveat about iteration order has been
  removed from the documentation, since there is no longer anything to warn
  about.

* `write_by_group()`: with `drop_na = FALSE`, a grouping column holding both
  missing values and the literal string `"NA"` is now an error naming the
  column, rather than silently merging two different groups into one file.
  Missing values are coerced to `"NA"` so they form their own group, so a
  column containing North America, Not Applicable, or a country code would
  otherwise have collapsed the two. `drop_na = TRUE` is unaffected: the
  missing rows are gone before the coercion, so no collision is possible.

* `check_project()`: the standard folder set now comes from
  `.default_folders()` and therefore includes `R/`. A project without an `R/`
  folder gains a `"warn"` row it did not have before.

* `init_project()`: `R/` is now part of the standard folder set. The derived
  `.R` script belongs there, whether it comes from `qmd_to_r()` or from the
  post-render hook `create_qmd(use_purl = TRUE)` scaffolds, and `R/purl.R`
  was already being created there by `create_qmd()` without the folder ever
  being declared. `scripts/` remains in the set and is now documented as the
  home for hand-written scripts.

* `init_project()`: every precondition is now checked before anything is
  created. A call that would previously create the project directory, its
  folders, and its branding assets before aborting on an existing README now
  aborts first and leaves nothing behind.

* `init_project()`: README detection at the destination is now
  case-insensitive and extension-agnostic, matching `check_project()`. A
  project already containing `readme.txt`, `README`, or `Readme.pdf` now
  aborts rather than quietly acquiring a second `README.md` beside it. Both
  functions now share one `.find_readme()` helper (issue #11).

* `init_project()`: when the folder set comes from `config`, a
  `custom_folders` removal is honored literally and the parent folder is no
  longer added back. `custom_folders = "-output/figures"` against the
  built-in default set still leaves `output/` behind, since that set is a
  convention; against a config it does not, since a config is an explicit and
  complete statement of the intended structure.

* `init_project()`: aborts rather than overwriting an existing `_toolero.yml`
  or existing files in `assets/`.

* `generate_project_config()`: the generated file now carries
  `schema_version` and a `conventions:` block in addition to `folders:`, and
  is written from the same template and writer as the `_toolero.yml` that
  `init_project()` records. Files produced by earlier versions, which carried
  only `folders:`, continue to be read without change.

* `init_project()`: the `uw_branding` argument is deprecated in favor of the
  new `branding` argument. `uw_branding = TRUE` maps to `branding =
  "uw-madison"` (not `branding = TRUE`, which now means generic placeholder
  assets); `uw_branding = FALSE` maps to `branding = "none"`. A
  `lifecycle::deprecate_warn()` fires when `uw_branding` is supplied.
  Removal planned for v0.6.0 alongside `check_project(error)`.

* `create_qmd()`: the `use_style` argument now detects branding files by
  standardized name (`styles.css`, `header.html`, `footer.html`) rather than
  scanning for any `.css` or `.html` file and erroring on ambiguity. Custom
  directories are the user's responsibility to populate under these exact
  names. The old "error when multiple `.css` or `.html` files found" behavior
  is removed.

* `create_qmd()`: `footer.html` is now separately wired as
  `include-after-body:` in the generated YAML, a new Quarto YAML key not
  present in previous versions. Projects using `use_style = TRUE` will now
  have a footer included if `assets/footer.html` exists.

* `init_project()`: now creates a `README.md` file at the project root by
  default. The new `use_readme` argument defaults to `TRUE`; calls that
  previously created no README -- which was all of them, since the argument
  did not exist -- will now produce one. Pass `use_readme = FALSE` to opt
  out and preserve the old behavior.

### New features

* `write_by_group()`: new `prefix` argument, a namespace prepended to every
  output filename. `prefix = "data"` turns `a.csv` into `data-a.csv`, and
  `a--female.csv` into `data-a--female.csv`. It is sanitized the same way
  group values are and joined with a single `-`, not the `--` that separates
  grouping columns: `--` is there to keep the group tuple and the filename in
  one-to-one correspondence, and a prefix is constant across every file in a
  call, so it cannot create a collision. Without a prefix, splitting on a
  short column produces short filenames such as `a.csv`, and since
  `submitr::htc_gen_submit()` reduces the manifest to `basename()` those land
  in one flat directory on the access point where two datasets split on the
  same column would overwrite each other. `prefix` is last in the signature,
  so adding it shifts no existing positional argument. Defaults to `NULL`,
  which leaves filenames exactly as before.

* `check_project()`: reads the project's own `_toolero.yml` when no `config`
  argument is supplied, so a customized project no longer has to be handed
  the same config on every call. Precedence is explicit `config`, then the
  project's manifest, then the built-in standard set. A folder declared in
  either of the first two and missing from disk is reported as `"fail"`
  rather than `"warn"`: a declaration that is not met is a conformance
  failure, whereas the standard set is a suggestion nobody signed up for. A
  `_toolero.yml` that exists but cannot be parsed is reported as a failing
  check and the audit continues against the standard set, since aborting the
  audit is less useful than reporting the problem (issue #12).

* `check_project()`: new `_toolero.yml` check, reporting whether the project
  carries a manifest. Absence is a `"warn"` -- a project predating v0.5.0
  legitimately has none -- and the message says how to create one.

* `check_project()`: reports naming conventions only when they differ from
  the defaults, as a single `"info"` row naming what changed. Silence when
  they match, so a conventions row always means something in this project
  resolves differently from every other one.

* `check_project()`: new `renv.lock packages` check, reporting a lockfile
  that records no packages other than `renv` itself **when the project also
  has `.R` or `.qmd` source files**. The pairing is what makes it worth
  printing: a freshly scaffolded project legitimately has an empty lockfile,
  since `renv::scaffold()` does no dependency discovery, but a project with
  code in it and nothing in its lockfile is the state that produces a
  container image which builds cleanly and then cannot run. The source scan
  covers the project root and the declared folders rather than recursing
  through everything, so `renv/library` is neither walked nor mistaken for
  the project's own code.

* `check_project()`: new `.renvignore` check, reporting an entry that
  excludes `.qmd` files. The advice is to remove it. Purling to `.R` later is
  not a substitute, since the snapshot you containerize from may be taken
  before the purl and the `.qmd` is the file being maintained either way.
  Versions of `init_project()` before v0.5.0 wrote such a file, so projects
  created by those versions still carry one.

* `init_project()`: writes a project manifest, `_toolero.yml`, to the project
  root, recording the folder set it resolved and the naming conventions in
  force. The file records the *resolved*
  structure, never the inputs that produced it, so a project built from a
  `config`, one built with `custom_folders`, and one built from the defaults
  all produce the same shape of file. It exists because the structure is
  configurable: `check_project()` can audit a customized project without
  being handed the same config again, and `containr` and `submitr` can
  resolve where code, data, and outputs live rather than assuming. Commit the
  file -- it describes the project, not the machine it was created on. The
  format is experimental and may gain keys before it settles; `schema_version`
  exists so a reader can tell whether it understands what it is holding
  (issue #12).

* `init_project()` and `generate_project_config()` now share one schema, one
  template (`inst/templates/_toolero.yml`), and one writer. A config authored
  by hand and a manifest a project carries are the same kind of document; the
  only difference is who wrote it.

* Project configuration files may now declare a `conventions:` block
  alongside `folders:`. Three keys are recognized: `output_dir` (where the
  analysis writes artifacts, read by `save_output()` and
  `generate_manifest()`), `script_dir` (where the derived `.R` script lives),
  and `split_dir` (where `write_by_group()` writes per-group subsets). Any
  key a file does not supply falls back to the package default, and
  unrecognized keys are ignored with a warning. These are the names the
  toolero family resolves rather than hardcodes.

* `init_project()`: writes a zero-byte `.gitkeep` into each folder it creates
  that is still empty when the call finishes. git tracks files rather than
  directories, so without this a scaffolded structure survives nothing -- the
  opening commit contains the files at the project root and none of the
  layout, and a collaborator cloning the repository gets a project with no
  folders in it. It is also the most common way `check_project()` would report
  a folder as failing on a project where nothing is actually wrong. The
  placeholders are written whether or not `use_git = TRUE`, since a project
  can be git-initialized at any point afterwards. Folders that already have
  content are left alone, so `assets/` gets none.

* `init_project()`: when `branding` is enabled, `assets/` now joins the
  project's folder set and is recorded in the manifest alongside every other
  folder, so downstream packages can find the branding files without being
  told about them separately.

* `init_project()`: new `branding` argument replacing `uw_branding`. Accepts
  `TRUE` (generic placeholder assets), `"uw-madison"` (UW-Madison RCI
  branding), or `"none"`/`FALSE` (no assets folder). All modes produce the
  same five standardized filenames in `assets/`: `logo.png`, `favicon.png`,
  `header.html`, `footer.html`, `styles.css` -- so downstream consumers
  (`create_qmd()`, `containr::generate_dockerfile()`) can reference those
  names regardless of which branding mode was used.

* `init_project()`: new `use_readme` argument controlling whether a README
  is created at the project root. `TRUE` (default) creates `README.md`;
  `"plain"` creates `README.txt` with identical content -- only the
  extension differs; `FALSE` creates no README. Both formats copy the same
  file, `inst/templates/readme-template.md`: a generalist guide that
  explains what a README is and why it matters, lays out a recommended
  section structure covering material shared by all research artifacts as
  well as software-specific and data-specific sections, and defers detailed
  guidance to the Cornell Data Services README guides rather than
  reproducing them. If a README already exists at the destination,
  `init_project()` aborts with an informative message instead of
  overwriting it.

* `create_qmd()`: `use_style = TRUE` now wires all three styling files
  present in `assets/` -- `styles.css` as `css:`, `header.html` as
  `include-before-body:`, and `footer.html` as `include-after-body:` --
  rather than only `css:` and one HTML include. Any subset may be present;
  only files that exist are injected.

* `create_qmd()`: `assets/logo.png` is now exempt from `overwrite`. An
  existing logo (e.g. placed by `init_project(branding = )`) is always left
  in place even when `overwrite = TRUE`, since a generic placeholder silently
  replacing institutional branding would be surprising. All other files
  (`sample.csv`, `_quarto.yml`, `purl.R`, the `.qmd` itself) continue to
  respect `overwrite`.

* Added `resolve_input_path()`, which resolves an input data path for the
  current execution context and explains what went wrong when it cannot.
  It replaces the `switch()` on `detect_execution_context()` that this
  family of packages has been recommending in four different places, which
  had already drifted: the roxygen example resolved the interactive branch
  to `data/sample.csv` while the bundled template resolved it to
  `data-raw/sample.csv`.

  Each of the three branch arguments is an ordinary R argument and
  therefore a promise, so only the branch matching the context is ever
  evaluated, exactly as in the hand-written `switch()`. The difference is
  where the evaluation happens. A document that declares no `params:`
  block raises `object 'params' not found`, and because the promise is now
  forced inside `resolve_input_path()` rather than in the document's own
  frame, that error can be caught and turned into a message about the YAML
  header. No amount of documentation could have reached it.

  Three failures it reports that previously surfaced one call later as
  something unhelpful: `commandArgs(trailingOnly = TRUE)[1]` returning
  `NA_character_` when no argument was passed, which is what
  `submitr`'s single mode with no `data_files` produces; a `params` block
  that exists without an `input_file` key; and a resolved path that is
  simply not there, which is most often a working directory that is not
  what the author assumed.

  Omitting an argument is meaningful. The `rscript` branch defaults to the
  first command line argument. The `interactive` and `quarto` branches both
  fall back to the document's own `params$input_file`, so a document whose
  header declares one can call `resolve_input_path()` with no arguments and
  the path is written once, in the header, rather than there and again in a
  chunk that has to be kept in step with it.

### Bug fixes

* `create_qmd()`: the YAML header was matched with a regular expression
  whose match included both `---` fences, and that whole string, trailing
  fence and all, was handed to `yaml::yaml.load()`, where the closing
  fence reads as the start of a second, empty YAML document. The parser
  tolerated it, so nothing visibly broke; the fences are now stripped
  before anything parses the header.

* `create_qmd(use_purl = TRUE)`: the warning issued when automatic
  post-render wiring is skipped for a `website`, `book`, or `manuscript`
  project asserted that `R/purl.R` "was still created". It may not have
  been: the script is scaffolded subject to `overwrite`, so an existing
  copy is left in place. The warning now reports which of the two
  happened, since whoever reads it is about to point a post-render hook
  at that script by hand and needs to know whether it is the copy this
  version ships. The manual instructions in the same warning are now
  phrased inline rather than as a two-line YAML snippet, which `cli`
  collapsed onto one line anyway.

* `init_project(use_git = TRUE)` initialized the git repository, staged files
  and made the opening commit in **the caller's project rather than the
  project it had just created**. `usethis::create_project()` sets the active
  `usethis` project only for its own duration -- it uses
  `usethis::local_project()` internally and restores the caller's project when
  it returns with `open = FALSE` -- and `init_project()` then called
  `usethis::use_git()` without setting the project again. Running
  `init_project()` from inside another package or project therefore added
  entries to *that* project's `.gitignore` and offered to commit *its*
  uncommitted files under the message `"initial commit"`, which is easy to
  accept because the prompt looks entirely plausible. `init_project()` now
  calls `usethis::local_project(path, force = TRUE, setwd = FALSE)` after
  creating the project, so every later step resolves against the new project,
  and the caller's project is restored when the function returns. Every test
  in the suite passed `use_git = FALSE`, which is why this went unnoticed; the
  git path is now covered.

* `init_project()`: documented that `R/` cannot be suppressed, by `config`
  or by `custom_folders`. `usethis::create_project()` calls
  `use_directory("R")` unconditionally, so the directory is present in
  every project regardless of the resolved folder set. A structure that
  leaves it out is honored everywhere else: `R/` is absent from
  `_toolero.yml`, gets no `.gitkeep`, and is not audited by
  `check_project()`. Only the directory itself is unavoidable. No code
  change; the test that asserted otherwise was the thing that was wrong,
  and it only began failing once `R/` joined the default folder set in
  this release.

* `save_output()` and `generate_manifest()`: the guard that reports an
  accumulator whose columns do not match the expected schema could not
  format its own message. The expected columns reached `cli` as
  `{.val {.accumulator_columns()}}`, and `cli` 3.4.0 and later read a `{}`
  expression beginning with a dot as an inline style name rather than as R
  code, so formatting failed and the explanation was replaced by a `cli`
  parse error. The failure only ever surfaced in the one branch whose
  purpose is to explain what went wrong. Both sites now bind the schema to
  a local first. The existing tests asserted only that something was
  thrown, which is why this went unnoticed; they now check that the message
  names a column.

* `run_by_group(workers = NULL)`: `NULL` skipped the validation block
  entirely and then reached `if (workers > 1L)` about a hundred and sixty
  lines later, where `NULL > 1L` is `logical(0)` and `if` raises "argument
  is of length zero". `NULL` is now documented and accepted as a way of
  saying "do not parallelize" and is coerced to `1L`. The block also now
  rejects a `workers` of any length other than one, so that everything
  after it can rely on `workers` being a single integer of at least one
  rather than on a reader noticing the gap.

* `qmd_to_r()`: creates the parent directory of `output` if it does not
  already exist. `knitr::purl()` writes through a connection and does not,
  so an explicit output path into a folder that is not there failed with a
  connection error naming the file rather than the missing directory. `R/`
  is the documented home for derived scripts, which makes this the ordinary
  case for any project not created by `init_project()`.

* `run_by_group()`: when running sequentially, arguments in `...` are now
  forwarded to `.f` unevaluated rather than captured with `list(...)`
  first. Most arguments are unaffected either way: a number, a string, a
  logical, a file path are ordinary values, and they reached `.f` correctly
  before and still do. The case that was broken is the one argument that is
  not an ordinary value, a bare *column name*. The old behaviour forced
  every argument in `run_by_group()`'s own frame, where a symbol like
  `flipper_length_mm` means nothing, so a function written to capture it
  with `{{ }}` failed with `object 'flipper_length_mm' not found` before it
  was ever entered. Such functions now work:

  ```r
  plot_group <- function(data, x, y) {
    ggplot2::ggplot(data, ggplot2::aes(x = {{ x }}, y = {{ y }})) +
      ggplot2::geom_point()
  }

  run_by_group(groups = subsets, .f = plot_group,
               x = flipper_length_mm, y = body_mass_g)
  ```

  To be clear about what this does *not* ask of you: `run_by_group()` places
  no requirement on how `.f` is written. `{{ }}` is what any function
  accepting a bare column name needs, called directly or not; a function
  taking only ordinary values needs nothing. If you would rather avoid tidy
  evaluation altogether, pass the column name as a string and index with
  `.data[[x]]` inside `.f`, which works in both modes.

  Two smaller consequences follow, both matching what a direct call to `.f`
  does: an argument with a side effect is evaluated at most once for the
  whole call rather than once per group, as before, and an argument `.f`
  never touches is now never evaluated at all, where previously it was.

  **Bare column names do not survive `workers > 1`.** Parallel execution
  sends the work to separate R sessions, so every argument has to be
  materialized and serialized first, and an argument whose value exists only
  inside the data mask `.f` builds has nothing to serialize. `run_by_group()`
  now reports that directly, naming the two ways forward, rather than letting
  it surface from inside `future`'s globals inspection as an unattributed
  `object 'x' not found`. Ordinary values, strings included, are unaffected.
  The portable form for a bare column name moves it inside `.f`, and works in
  both modes:

  ```r
  run_by_group(
    groups  = subsets,
    .f      = \(d) plot_group(d, x = flipper_length_mm, y = body_mass_g),
    workers = 4
  )
  ```

  Closes #16.

### Internal changes

* New `R/utils-yaml.R` holds the line-oriented header helpers:
  `.split_yaml_header()`, `.join_yaml_header()`, `.set_yaml_key()` and
  `.set_yaml_keys()`, with `.yaml_indent()`, `.yaml_line_key()`,
  `.find_yaml_key()`, `.yaml_entry_extent()`, `.first_child_indent()`,
  `.splice()` and `.render_yaml_entry()` beneath them. Only the value
  being written passes through `yaml::as.yaml()`.

* `.inject_style_yaml()`, `.inject_purl_yaml()` and `.substitute_yaml()`
  were three near-identical copies of the same parse-mutate-serialize
  block, differing only in the mutation between the two. They are now
  three thin callers of `.set_yaml_keys()`, and `.stamp_params_yaml()`
  joins them as a fourth.

* `create_qmd()` resolves `sample.csv`, the `.qmd` templates, `purl.R`
  and `_quarto.yml` through `.package_template()` rather than calling
  `system.file(mustWork = TRUE)` directly, so a missing or misnamed
  template reports which file it wanted instead of `pkgload`'s bare
  `Can't find package file.`

* `.standard_folder_message()` and `.cli_escape()` moved from
  `R/check-project.R` to `R/utils-project.R`. The folder set and the advice
  for each member of it are one fact, and keeping them in separate files is
  how they drift; `.standard_folder_message()` gained entries for `R/` and
  `assets/` in the move. `check_project()`'s inline config parsing and README
  detection were replaced by calls to the shared `.read_config_file()` and
  `.find_readme()`.

* `write_by_group()`: documentation now uses the term *job manifest*
  consistently for the `manifest.csv` it writes, distinguishing it from the
  *project manifest* `generate_manifest()` produces. The first lists inputs to
  a computation that has not happened; the second records outputs from one
  that has.

* `sanitize_filename()` gained roxygen explaining the invariant the filename
  scheme depends on: because a run of non-alphanumeric characters collapses
  to exactly one dash, a sanitized value can contain a single `-` but never
  two consecutive ones, which is what leaves `--` free to mark a column
  boundary.

* Added `.renv_lock_is_bare()`, `.project_has_sources()` and
  `.renvignore_excludes_qmd()` to `R/check-project.R`, backing the two new
  renv checks.

* Added `R/utils-project.R`, holding the facts about a toolero project that
  more than one function needs: `.default_folders()`, `.default_conventions()`,
  `.project_yml_name()`, `.project_yml_schema_version()`, `.write_project_yml()`,
  `.read_project_yml()`, `.read_config_file()`, `.substitute_block()`, and
  `.find_readme()`. The standard folder set was previously spelled out in
  four places -- `init_project()`, `generate_project_config()`,
  `check_project()`, and `.standard_folder_message()` -- with nothing keeping
  them in step. Adding a folder to the standard set is now a one-line change
  in `.default_folders()`.

* Added `inst/templates/_toolero.yml`, the annotated template both
  `init_project()` and `generate_project_config()` render. The folder list
  and conventions block are placeholders filled at write time from
  `.default_folders()` and `.default_conventions()` rather than literal text,
  so the template cannot drift from the package defaults. Substitution is
  line-based rather than a YAML round trip, so the template's explanatory
  comments survive into the written file.

* `.resolve_custom_folders()` gains a `preserve_parents` argument.
  `init_project()` passes `FALSE` when the base folder set came from a
  `config`.

* Added `.branding_asset_names()`, replacing the inline vector of five
  standardized asset filenames.

* `init_project()`: the new project is now made the active `usethis` project
  explicitly, via `usethis::local_project()`, for the duration of the call.
  The surrounding `withr::with_dir(getwd(), ...)` block, which set the
  working directory to the working directory and therefore did nothing, has
  been removed. See the bug fix below for why the explicit call is needed.

* `inst/assets/` now contains ten files under a `uw-*` / `generic-*` prefix
  convention: `uw-logo.png`, `uw-favicon.png`, `uw-header.html`,
  `uw-footer.html`, `uw-styles.css`, and five `generic-*` counterparts.
  The copy step in `init_project()` strips the prefix and writes standardized
  names into the project's `assets/` directory. The old three-file UW set
  (`rci-banner.png`, `header.html`, `styles.css`) in `inst/extdata/` has been
  removed; `inst/extdata/` now contains only `data-provenance.md`.

* `inst/templates/logo.png` removed. The generic placeholder logo is now
  `inst/assets/generic-logo.png`, which `create_qmd(include_examples = TRUE)`
  copies into `assets/logo.png` when no logo already exists.

* `.inject_style_yaml()` gains `header_file` and `footer_file` arguments
  (replacing the old single `html_file` argument), maps them to
  `include-before-body:` and `include-after-body:` respectively, and drops
  the `favicon_file` argument (favicon wiring belongs in `_quarto.yml` as a
  website-project option, not in the per-document YAML).

* `style_dir` is absolutized via `fs::path_abs()` in `create_qmd()` before
  style detection, ensuring `fs::path_rel()` comparisons are valid when a
  relative `use_style` path is combined with an absolute `path` argument.

* Added `inst/templates/readme-template.md`, the generalist README template
  copied by `init_project()`'s new `use_readme` argument.

* `.ensure_directory()` moved from `R/save-output.R` to
  `R/utils-project.R`, since `qmd_to_r()` now uses it too and it is no
  longer specific to the accumulator. Its tests moved with it into the new
  `tests/testthat/test-utils-project.R`.


### New features (continued)

* Added `save_output()` for writing an object to disk via a user-supplied
  function and recording the write in a project-level accumulator at
  `output_dir/accumulator.csv`. The accumulator is append-only and carries
  one row per call, recording `file_path`, `r_class`, `timestamp`,
  `function_used`, `status`, `error_message`, and `note`. The call to the
  write function is wrapped in a narrowly-scoped `tryCatch()` -- only that
  call, not the rest of `save_output()`'s body -- so a failed write is
  recorded with `status = "failure"` and the caught error message before
  the original condition is rethrown unmodified, preserving condition class
  and traceback. Missing destination directories are created automatically
  and reported.
* Added `generate_manifest()` for reading the project accumulator,
  collapsing it to one row per output file (keeping the latest write per
  path, since the accumulator may contain superseded rows from reruns
  within a session), and writing `project-manifest.json`. The manifest
  records `execution_context` and `generated_at` once at the top level,
  followed by an `artifacts` array with one entry per deduplicated output,
  ordered chronologically. Field names are toolero-native rather than
  RO-Crate vocabulary -- that translation belongs in `encapsulr::describe()`
  as a thin mapping layer. Checksums are deliberately excluded:
  `rocrateR::bag_rocrate()` computes `manifest-sha512.txt` at bagging time,
  and duplicating that here would create a second record to keep in sync. A
  missing accumulator is an error; an accumulator with no rows produces an
  empty manifest with a warning.

### Improvements

* `create_qmd()`: every edit to a document's YAML header is now made line
  by line rather than by parsing the header and writing it back out. Keys
  the edit does not touch keep the template's own quoting, indentation,
  comments and ordering, so the document a reader opens is the template
  we shipped plus the keys they asked for. Previously a header was parsed
  and re-serialized once per edit -- up to three times in a single call
  with `use_style`, `use_purl` and `yaml_data` together -- and each pass
  stripped quoting from scalars, moved sequence indentation, and would
  have deleted any comment the header carried. Both templates now carry a
  YAML comment explaining `embed-resources`, which the old implementation
  could not have preserved.

* `create_qmd(yaml_data = )`: a key the supplied file does not mention is
  now left exactly as the template wrote it. Top-level keys the file does
  mention are replaced wholesale, as before.


* `check_project()`: README detection is now case-insensitive and
  extension-agnostic. Any file whose stem matches `readme` (in any
  capitalization) is recognized, regardless of extension or the absence of
  one. Previously only `README.md`, `README.Rmd`, and `README.qmd` were
  checked, all case-sensitively, missing common variants like `readme.md`
  or a plain `README` on Linux (issue #11).
* `check_project()`: the standard folder set now matches `init_project()` --
  `data-raw/`, `data/`, `scripts/`, `output/figures/`, `output/tables/`, and
  `reports/`. The previous hardcoded set (`data-raw/`, `data/`, `docs/`) was
  stale relative to the v0.4.0 breaking change to `init_project()`.
* `check_project()`: new `config` argument accepts a path to a YAML file
  produced by `generate_project_config()`. When supplied, the `folders:`
  list in the file replaces the standard toolero folder set for the folder
  checks. Non-folder hygiene checks (`.Rproj`, `renv.lock`, git,
  `.gitignore`, README, and hidden files) always run regardless of the
  config. Folders declared in the config but missing from the project are
  reported as `"fail"` rather than `"warn"` -- the user declared them
  explicitly, so their absence is a conformance failure rather than an
  advisory (issue #12).

* `detect_execution_context()`: its `@examples` no longer show the input
  resolution `switch()`, which now lives in `resolve_input_path()`. The
  example shows a use that is genuinely about the context itself, and a
  `@seealso` points at the new function.

* `detect_execution_context()`: the documented priority order now records
  that it is unobservable. `QUARTO_DOCUMENT_PATH` is set only by Quarto
  rendering a document, and every path that renders one runs the R code in
  a process that is not interactive; running chunks inline in RStudio is
  the reverse, interactive with the variable unset. The two tests never
  fire together, so the priority never arbitrates anything. The order is
  unchanged.

* `create_qmd()`: the credit for the bundled `sample.csv` now says what the
  file is and where to read about it. It is a subset of the Palmer
  Archipelago penguin data taken from an earlier version of
  `palmerpenguins` than the one on CRAN today, and since R 4.5.0 the same
  data ships with base R as `datasets::penguins`. The note records that
  base R shortened four column names, so `bill_length_mm`, `bill_depth_mm`,
  `flipper_length_mm` and `body_mass_g` in the CSV are `bill_len`,
  `bill_dep`, `flipper_len` and `body_mass` there. The template keeps the
  longer names, which carry their units. The Gorman, Williams and Fraser
  (2014) data paper is now cited alongside the R package.

* `create_qmd()`: the bundled example template resolves its input through
  `resolve_input_path()` rather than a hand-written `switch()`, and points
  out that the zero-argument form works once the header declares
  `input_file`.

* The README was brought up to date with the 0.5.0 changes. The opening
  workflow now runs end to end against the bundled sample data, with the
  analysis function defined inline: it previously read an `input.csv` that
  nothing created, called an undefined `my_analysis`, and wrote the derived
  script into `scripts/` rather than `R/`. Two claims that had gone stale
  are corrected: `R/purl.R` is scaffolded subject to `overwrite` rather
  than "unconditionally", and the job manifest has one schema rather than a
  separate three-column shape for single-column splits. New material covers
  `_toolero.yml` and what downstream packages read from it, `R/` in the
  standard folder set and why it cannot be suppressed, `.gitkeep`,
  `renv::scaffold()` and the absent creation-time snapshot, the two `renv`
  checks in `check_project()`, `prefix` and first-appearance ordering in
  `write_by_group()`, `resolve_input_path()`, `embed-resources: true`, the
  accumulator schema as the thing that holds still, and what running
  `toolero` inside a container commits you to. The dependency list now
  distinguishes required packages from suggested ones and names which
  function needs each, `knitr` for `qmd_to_r()` above all, which was absent
  from the list while being required by step 4 of the first workflow.

### Deprecated features

* `check_project(error)`: the `error` argument is deprecated and will be
  removed in v0.6.0. The cli report now always prints and the tibble is
  always returned invisibly. To access results programmatically, assign the
  output directly: `out <- check_project()`. Passing `error = FALSE`
  continues to work but triggers a deprecation warning.


# toolero 0.4.0

### New features

* Added `run_by_group()`, the apply half of the split-apply workflow. Accepts
  either a manifest CSV produced by `write_by_group(manifest = TRUE)` or a
  named list of data frames. Applies a user-supplied function to each group
  subset and collects the results into a flat tibble (when the function returns
  a data frame) or a nested tibble with a list-column (when it returns anything
  else). Supports parallel execution via `furrr` and `future` through the
  `workers` argument, with a ceiling at
  `max(1L, parallelly::availableCores() - 1L)` to reserve one core for the
  main session. A `seed` argument enables reproducible parallel execution for
  analyses involving randomness.
* Added `read_clean_csv()` for reading CSV files into a tibble with
  `janitor::clean_names()` applied automatically. Supports explicit
  missing-value codes via `na`, selective row dropping via `drop_na` (accepts
  `TRUE` or a character vector of column names), an optional ingest summary
  via `summary`, and pass-through arguments to `readr::read_csv()` via `...`.
* Added `write_clean_csv()` for writing data frames to CSV with clean column
  names. Applies `janitor::clean_names()` if column names are not already
  clean and reports affected columns via cli feedback.
* Added `check_project()` for auditing a project directory against toolero
  conventions. Checks for expected folders, an `.Rproj` file, `renv.lock`,
  a git repository, a README, a `.gitignore`, and hidden files such as
  `.RData` or `.Rhistory`. Operates in two modes: a cli report (default) or
  a tibble return for programmatic use (`error = FALSE`).
* Added `qmd_to_r()` for extracting R code chunks from any `.qmd` file into
  a standalone `.R` script via `knitr::purl()`. The output path defaults to
  the same directory as the input with the extension replaced. The
  `documentation` argument controls how much context is preserved in the
  extracted script.
* Added `generate_project_config()` for writing a skeleton YAML project
  configuration file pre-filled with the standard toolero folder structure.
  Intended to be edited by the user and passed to `init_project()` via the
  new `config` argument. `filename` is required and explicit; `path` defaults
  to `"."`. An `overwrite` argument (default `FALSE`) guards against
  accidental replacement of an existing config. The file extension is
  normalized to `.yml` regardless of what is supplied.
* Added Palmer Penguins attribution (Horst, Hill & Gorman, 2020) to the
  template `.qmd`, the `create_qmd()` roxygen `@details` section, and a
  provenance note in `inst/extdata/`.

### Breaking changes

* `init_project()`: the standard folder structure has been revised to better
  reflect research workflow conventions established by The Carpentries and
  UW-Madison Libraries. The new standard set is `data-raw/`, `data/`,
  `scripts/`, `output/figures/`, `output/tables/`, and `reports/`. The
  previous set (`data/`, `data-raw/`, `images/`, `plots/`, `results/`,
  `scripts/`, `docs/`, `R/`) is no longer created by default.
* `init_project()`: `extra_folders` has been renamed to `custom_folders`. The
  argument now supports a dplyr-select-like syntax: bare names add folders
  (e.g. `"models"`), names prefixed with `"-"` suppress creation of that
  folder from the resolved set (e.g. `"-output/figures"`). Suppression removes
  only the named leaf -- parent directories are preserved. Duplicate additions
  emit an informational message and are skipped; references to non-existent
  folders via `"-"` emit a warning.
* `create_qmd()`: no longer copies `styles.css` and `header.html` from the
  package into the project. Custom styling is now controlled exclusively by
  the new `use_style` argument. Projects that relied on `create_qmd()`
  copying UW-branded assets should use `init_project(branding = "uw-madison")`
  to scaffold those files, then pass `use_style = TRUE` to `create_qmd()` to
  wire them into the YAML.
* `create_qmd()`: sample data is now copied into `data-raw/` instead of
  `data/`, consistent with `init_project()`'s folder structure.

### New features (continued from above)

* `init_project()`: added `config` argument. When supplied, the folder list
  in the YAML file replaces the built-in standard structure entirely.
  `custom_folders` is still applied on top of the config-derived set.
  Configs are produced by `generate_project_config()` and can be stored in
  the user home directory for reuse across project types.
* `create_qmd()`: added `include_examples` argument (default `TRUE`). When
  `TRUE`, copies a sample dataset (`sample.csv`) into `data-raw/`, a
  placeholder logo (`logo.png`) into `assets/`, and uses a worked example
  template with a `params` block referencing the sample data. When `FALSE`,
  creates a blank skeleton `.qmd` with only the YAML header and a setup
  chunk -- no sample data, no logo, no example analysis block.
* `create_qmd()`: added `use_style` argument (default `FALSE`). Accepts
  `FALSE` (no custom styling), `TRUE` (scans `assets/` for standardized
  branding files by name), or a directory path (scans that directory
  instead). `styles.css` is added as `css:`, `header.html` as
  `include-before-body:`, and `footer.html` as `include-after-body:`. Only
  files that exist are wired into the YAML.
* Added `inst/templates/skeleton.qmd` -- a minimal Quarto template used when
  `include_examples = FALSE`. Contains the YAML header, a setup chunk with
  `library(toolero)`, and a single placeholder heading.
* `write_by_group()`: `group_col` now accepts a character vector of column
  names, enabling grouping by more than one column at once. Sanitized
  filenames join multiple columns with `--` (e.g. `group_col = c("species",
  "sex")` on an Adelie male produces `adelie--male.csv`); only combinations
  actually present in the data produce files, not the full cross-product of
  possible values. When `manifest = TRUE`, the manifest gains one column per
  grouping variable (holding the raw, unsanitized value) in addition to a
  composite `group_value` column joining the raw values with `" | "`.
  Single-column calls are unaffected -- filenames, manifest schema, and
  behavior are unchanged from previous versions.
* `write_by_group()`: added `drop_na` argument (default `TRUE`). Rows with a
  missing value in any grouping column are dropped before splitting, with a
  cli message reporting how many rows were dropped and from which column(s)
  -- this was previously silent, undocumented behavior inherited from
  `split()`. Set `drop_na = FALSE` to instead treat missing values as their
  own group rather than dropping them.

### Bug fixes

* `create_qmd()`: `use_style = TRUE` now correctly copies `rci-banner.png`
  from `inst/assets/` into the project `assets/` directory. Previously the
  banner was only copied inside the `include_examples` block and was silently
  omitted when `use_style = TRUE` was combined with `include_examples = FALSE`.
* `create_qmd()`: `filename` argument now normalizes the file extension to
  `.qmd` via `fs::path_ext_set()`. Passing `"my-document"` and
  `"my-document.qmd"` both produce `my-document.qmd`; a double extension is
  never added.
* `init_project()`: path construction now uses `fs::path()` throughout rather
  than `glue::glue("{path}/{folder}")`, ensuring correct behavior on all
  platforms.
* `init_project()`: branding files are now copied from `inst/assets/` rather
  than `inst/extdata/`, consistent with the rest of the package.


# toolero 0.3.0

### Breaking changes

* `create_qmd()`: `filename` is now the first argument and has no default --
  it must be supplied explicitly. `path` is now the second argument and
  defaults to `"."`, allowing natural calls like `create_qmd("analysis.qmd")`.
* `write_by_group()`: sanitized output filenames now use `-` (dash) as the
  separator instead of `_` (underscore), consistent with the package
  convention that file names use dashes. Existing workflows that reference
  output paths by name will need to update accordingly.
* `init_project()`: the `file_path` argument has been renamed to `path` for
  consistency with `create_qmd()` and the broader package API. Calls using
  `file_path =` by name will error; positional calls are unaffected.

### New features

* Added `generate_kb_xml()` to produce UW-Madison KB-importable XML files
  from rendered Quarto documents. Extracts metadata from the `.qmd` YAML
  header and re-renders with embedded resources for self-contained import.
* `create_qmd()`: added `use_purl` argument (default `TRUE`) that scaffolds
  a `_quarto.yml` post-render hook and a `purl.R` script for extracting R
  code from rendered documents into `R/`.

### Bug fixes

* `init_project()`: now runs `renv::snapshot()` and creates `.renvignore`
  after `renv::init()`, ensuring the lockfile is populated and `.qmd` files
  are excluded from dependency scanning at project creation time.
* `create_qmd()`: `_quarto.yml` is now copied from `inst/templates/` rather
  than written from a hardcoded string, so changes to the template are
  reflected automatically.
* `create_qmd()`: `purl.R` is now correctly placed in `R/` instead of the
  project root, consistent with `_quarto.yml` calling `Rscript R/purl.R`.
* `create_qmd()`: fixed YAML boolean serialization when `yaml_data` is
  supplied. `yaml::as.yaml()` was converting `true`/`false` to `yes`/`no`,
  which Quarto does not recognize. A custom handler now forces unquoted
  `true`/`false` output.
* `inst/templates/purl.R`: replaced `QUARTO_DOCUMENT_PATH` environment
  variable approach with `fs::dir_ls()` glob scan, which works reliably
  regardless of how Quarto invokes the post-render script.


# toolero 0.2.0

### Breaking changes

* `create_qmd()`: `path` is now a required argument with no default. Passing
  `NULL` or omitting it raises an error. Use `tempdir()` for temporary output.
* `write_by_group()`: `output_dir` is now a required argument with no default.
  Passing `NULL` or omitting it raises an error. Use `tempdir()` for temporary
  output.
* `init_project()`: `open` now defaults to `FALSE` instead of `TRUE` to avoid
  disrupting the current RStudio session in non-interactive contexts.

### New features

* Added `detect_execution_context()` to identify whether code is running in
  an interactive R session, a `quarto render` call, or a plain `Rscript`
  invocation. Returns one of `"interactive"`, `"quarto"`, or `"rscript"`.
* Added `create_qmd()` to scaffold a new Quarto document from a reproducible
  template, including a sample dataset, UW-Madison branded assets, and
  three-context input resolution via `detect_execution_context()`. Optionally
  pre-populates the YAML header from a user-supplied YAML config file.
* Added `write_by_group()` to split a data frame by a single grouping column
  and write each group to a separate CSV file. Filenames are derived from
  sanitized group values. Optionally writes a `manifest.csv` listing output
  files, group values, and row counts.


# toolero 0.1.1

### New features

* Added `uw_branding` argument to `init_project()`. When `TRUE`, creates an
  `assets/` folder in the new project and populates it with UW-Madison RCI
  branding files (`styles.css`, `header.html`, `rci-banner.png`).


# toolero 0.1.0

* Initial CRAN submission.
