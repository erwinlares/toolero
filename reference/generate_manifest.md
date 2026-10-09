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
  receiving the output record. An explicit relative value is read from
  the project root (see the Paths section); an absolute one is used as
  given. If `NULL` (the default), resolved from `config`'s `output_dir`
  convention when `config` is supplied, or `"output"` otherwise, exactly
  as
  [`save_output()`](https://erwinlares.github.io/toolero/reference/save_output.md)
  resolves it, so the two always meet at the same accumulator.

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
  record (see the Provenance section below). A relative path is read
  from the project root. Defaults to `"."`, the project root.

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
Without it, `output_dir` defaults to `output/` under the project root.
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
  (relative to the project root when the file is inside the project, as
  given to
  [`save_output()`](https://erwinlares.github.io/toolero/reference/save_output.md)
  otherwise), `r_class` (the object's classes joined with `"|"`),
  `timestamp` (same format as `generated_at`), `function_used`, `status`
  (`"success"` or `"failure"`), `error_message`, and `note`. A field
  with no value is written as `null`, never as an empty string.

`schema_version` increments only when an existing key is removed,
renamed, or changes meaning or type. A record with no `schema_version`
was written by toolero 0.5.x and has the version 1 shape without the
key. The full specification, including the rules for readers, is in the
family's `CONVENTIONS.md`.

The output record is toolero's own format. Read it with
[`read_output_records()`](https://erwinlares.github.io/toolero/reference/read_output_records.md);
other packages should treat the file as opaque rather than parse it.

## The output record and the job manifest

This is the *output record*: a record of outputs from a computation that
has already happened. It is distinct from the *job manifest* produced by
[`write_by_group()`](https://erwinlares.github.io/toolero/reference/write_by_group.md)
and consumed by `submitr::htc_gen_submit()`, which lists inputs to a
computation about to happen. The file name, `project-manifest.json`, and
this function's name predate the family's vocabulary and are kept for
compatibility; the file defaults to `project-manifest.json` rather than
`manifest.json` so the two documents cannot be confused on disk.

## Paths

A relative path is read from the project root, not from the working
directory. So `save_output(fit, "output/fit.rds", saveRDS)` writes into
the project's own `output/` folder whether you call it from the project
root, from a document under `reports/`, or from a job on an HTCondor
execute node. You never need to wrap a path in
[`here::here()`](https://here.r-lib.org/reference/here.html). Doing so
still works, because
[`here::here()`](https://here.r-lib.org/reference/here.html) returns an
absolute path and absolute paths are used as given.

The project root is found afresh on every call, in this order:

1.  The job's scratch directory, when `_CONDOR_SCRATCH_DIR` names one.
    HTCondor sets that variable itself, inside every job.

2.  The nearest folder above the working directory that carries a
    project marker: the `.here` file
    [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
    writes, an `.Rproj` file, a package `DESCRIPTION`, or a version
    control folder such as `.git`.

3.  The working directory, when neither of the above applies.

Absolute paths (including those starting with `~`, or a drive letter on
Windows) and URLs such as `https://` or `s3://` are used as given. `..`
and `./` are not interpreted, so `"../data/x.csv"` means the folder
above the root; write an absolute path to leave the project. A bare
`"."` means the root itself.

Functions that read are forgiving about older code. A relative path that
does not exist at the project root but does exist relative to the
working directory is read from there, and a message says so. Functions
that write never guess: a relative path is always written under the
root.

A few arguments are deliberately left alone:

- [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
  reads `path`, `config` and `use_rprofile` from the working directory,
  because the project does not exist yet and so has no root.

- Under `Rscript`,
  [`resolve_input_path()`](https://erwinlares.github.io/toolero/reference/resolve_input_path.md)
  reads the command line argument as given. Run `Rscript` from the
  project root or pass an absolute path.

- Arguments passed on through `...` to another function reach it
  untouched.

- Where a default is "beside the input"
  ([`qmd_to_r()`](https://erwinlares.github.io/toolero/reference/qmd_to_r.md)
  and
  [`generate_kb_xml()`](https://erwinlares.github.io/toolero/reference/generate_kb_xml.md)),
  the output follows wherever the input was read from.

Two limits are worth knowing. A project nested inside another project is
not supported: the nearest marker wins, which can surprise you when you
work from the outer one. And on an execute node `~` and `$HOME` cannot
be trusted (`$HOME` can be the submit node's path), so prefer relative
paths in job scripts.

## See also

[`save_output()`](https://erwinlares.github.io/toolero/reference/save_output.md),
which feeds the accumulator, and
[`read_output_records()`](https://erwinlares.github.io/toolero/reference/read_output_records.md),
which reads the output record back.

## Examples

``` r
output_dir <- withr::local_tempdir()

save_output(
  object = mtcars,
  file_path = fs::path(output_dir, "mtcars.rds"),
  .f = saveRDS,
  output_dir = output_dir
)
#> ℹ Created the directory /tmp/RtmpVdwYt8/file1a895b5c69d3 to hold mtcars.rds.

generate_manifest(output_dir = output_dir)
#> ✔ Wrote /tmp/RtmpVdwYt8/file1a895b5c69d3/project-manifest.json describing 1
#>   artifact.
```
