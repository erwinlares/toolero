# Write the output record

`generate_manifest()` reads the accumulator written by
[`save_output()`](https://erwinlares.github.io/toolero/reference/save_output.md)
over the course of an analysis, collapses it to one row per output file,
and writes the output record, `project-manifest.json`, describing every
artifact the project produced.

## Usage

``` r
generate_manifest(
  output_dir = NULL,
  filename = "project-manifest.json",
  overwrite = FALSE,
  config = NULL,
  git_root = "."
)
```

## Arguments

- output_dir:

  Character or `NULL`. Directory containing `accumulator.csv` and
  receiving the output record. If `NULL` (the default) and `config` is
  supplied, resolved from the config's `output_dir` convention; if
  `config` is also `NULL`, falls back to `"output"`, unchanged from
  earlier versions.

- filename:

  Character. Name of the output record file. Defaults to
  `"project-manifest.json"`.

- overwrite:

  Logical. When `FALSE` (default), an existing output record at that
  path is an error rather than being replaced.

- config:

  Character or `NULL`. Path to a project configuration file (typically a
  project's own `_toolero.yml`, as written by
  [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)).
  Only consulted when `output_dir` is not supplied; an explicit
  `output_dir` always wins. Defaults to `NULL`.

- git_root:

  Character. Directory to check for a git commit to record in the output
  record (see the Provenance section below). Defaults to `"."`.

## Value

The path to the output record, invisibly.

## Details

The output record opens with `schema_version`, then holds
`execution_context`, `generated_at`, and `commit` once at the top level,
followed by an `artifacts` array with one entry per output file, ordered
chronologically. Context, generation time, and commit are facts about
the run as a whole rather than about any individual artifact, so they
are not repeated per entry. Package and R versions are deliberately
absent: that is `renv`'s job, and duplicating it here would create a
second record to keep in sync.

Field names are toolero's own rather than RO-Crate vocabulary. The
translation to `@id`, `dateCreated`, and the rest belongs in
`encapsulr::describe()` as a thin mapping layer, so that toolero's
public interface does not inherit a downstream package's data model.

Checksums are likewise excluded. RO-Crate defers fixity to BagIt and
OCFL, and `rocrateR::bag_rocrate()` computes `manifest-sha512.txt`
automatically at bagging time.

A missing accumulator is an error: no save was ever recorded, and an
empty output record would present that as a finished result. An
accumulator holding no rows is different – the file exists, so the
machinery was wired up – and produces an empty output record with a
warning.

## Provenance

The output record also holds `commit`: the git commit checked out in
`git_root` at the moment the record was written, or `null` when the
project is not a git repository, has no commits yet, or `git` is not
installed. This is deliberately the one piece of "which version of the
code produced this" that package versions cannot supply – `renv.lock`
already answers which package versions were in play, but nothing else
records which revision of the analysis script itself ran. Like
`execution_context` and `generated_at`, it describes the run as a whole
and is not repeated per artifact.

`config` is entirely opt-in and affects `output_dir` only, not `commit`.
Nothing changes for a project never scaffolded by
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md):
pass `output_dir` (or rely on the `"output"` default) exactly as before.
When `config` is supplied but cannot be read, this aborts with the same
message
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
gives for a bad `config`, rather than silently falling back to
`"output"`.

## Format

The output record is a single JSON object with these keys, in this
order:

- `schema_version` – integer, currently `1`.

- `execution_context` – `"interactive"`, `"quarto"`, or `"rscript"`, as
  returned by
  [`detect_execution_context()`](https://erwinlares.github.io/toolero/reference/detect_execution_context.md).

- `generated_at` – when the record was written, in UTC with millisecond
  precision (`"2026-09-29T18:04:12.345Z"`).

- `commit` – a 40-character git commit SHA, or `null`.

- `artifacts` – an array, empty rather than absent when nothing was
  saved. Each entry carries the seven accumulator fields: `file_path`
  (the path as passed to
  [`save_output()`](https://erwinlares.github.io/toolero/reference/save_output.md)),
  `r_class` (the object's classes joined with `"|"`), `timestamp` (same
  format as `generated_at`), `function_used`, `status` (`"success"` or
  `"failure"`), `error_message`, and `note`. A field with no value is
  written as `null`, never as an empty string.

`schema_version` increments only when an existing key is removed,
renamed, or changes meaning or type. A record with no `schema_version`
was written by toolero 0.5.x and has the version 1 shape without the
key. The full specification, including the rules for readers, is in the
family's `CONVENTIONS.md`.

The output record is toolero's own format. Other packages should treat
it as an opaque file rather than parse it.

## The output record and the job manifest

This is the *output record*: a record of outputs from a computation that
has already happened. It is distinct from the *job manifest* produced by
[`write_by_group()`](https://erwinlares.github.io/toolero/reference/write_by_group.md)
and consumed by `submitr::htc_gen_submit()`, which lists inputs to a
computation about to happen. The file name, `project-manifest.json`, and
this function's name predate the family's vocabulary and are kept for
compatibility; the file defaults to `project-manifest.json` rather than
`manifest.json` so the two documents cannot be confused on disk.

## See also

[`save_output()`](https://erwinlares.github.io/toolero/reference/save_output.md)

## Examples

``` r
output_dir <- withr::local_tempdir()

save_output(
  object = mtcars,
  file_path = fs::path(output_dir, "mtcars.rds"),
  .f = saveRDS,
  output_dir = output_dir
)
#> ℹ Created the directory /tmp/RtmpW98hhs/file1dca74c5c83b to hold mtcars.rds.

generate_manifest(output_dir = output_dir)
#> ✔ Wrote /tmp/RtmpW98hhs/file1dca74c5c83b/project-manifest.json describing 1
#>   artifact.
```
