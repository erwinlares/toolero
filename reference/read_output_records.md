# Read one or more output records

**\[experimental\]**

Reads the output record, `project-manifest.json`, that
[`generate_manifest()`](https://erwinlares.github.io/toolero/reference/generate_manifest.md)
writes at the end of an analysis, and returns what it describes as a
table with one row per artifact. Given several output folders, it reads
each and stacks the results, so that the outputs of a multi-job run (one
folder per job, as `submitr::htc_collect()` leaves them) can be
inspected as one table.

`read_output_records()` is the reader that goes with
[`generate_manifest()`](https://erwinlares.github.io/toolero/reference/generate_manifest.md).
The output record is toolero's own format, and this is the one place
that interprets it, so other code (including other packages) can read
the table this returns rather than parse the file.

## Usage

``` r
read_output_records(
  path = NULL,
  filename = "project-manifest.json",
  config = NULL
)
```

## Arguments

- path:

  Character vector or `NULL`. Output folders, each holding a
  `project-manifest.json`, an `accumulator.csv`, or both; or paths to
  output record files themselves; relative paths are read from the
  project root (see the Paths section). A named vector labels each
  folder's rows in the `source` column with its name; an unnamed one (or
  an element with an empty name) uses the path as you typed it. If
  `NULL` (the default), reads the project's own output folder, resolved
  exactly as
  [`save_output()`](https://erwinlares.github.io/toolero/reference/save_output.md)
  and
  [`generate_manifest()`](https://erwinlares.github.io/toolero/reference/generate_manifest.md)
  resolve it.

- filename:

  Character. Name of the output record within each folder. Defaults to
  `"project-manifest.json"`. Ignored for elements of `path` that are
  files rather than folders.

- config:

  Character or `NULL`. Path to a project configuration file (typically a
  project's own `_toolero.yml`). Only consulted when `path` is `NULL`,
  to find the project's output folder from its `output_dir` convention.
  Defaults to `NULL`.

## Value

A tibble with one row per artifact and these columns, in order:

- `source` – the name given to the folder in `path`, or the path itself.

- `file_path`, `r_class`, `timestamp`, `function_used`, `status`,
  `error_message`, `note` – the seven artifact fields, exactly as
  recorded (see
  [`generate_manifest()`](https://erwinlares.github.io/toolero/reference/generate_manifest.md)).
  All character; timestamps are kept as the strings written, and a
  `null` in the record becomes `NA`.

- `read_from` – `"output record"`, or `"accumulator"` when the rows came
  from the fallback described below.

- `schema_version` – integer; `NA` for rows read from an accumulator.

- `execution_context`, `generated_at`, `commit` – facts about the run as
  a whole, repeated on each of its rows; `NA` for rows read from an
  accumulator, which does not record them.

An output record with no artifacts contributes no rows. When nothing at
all can be read, the result is a tibble with these columns and no rows.

## Versions

A record written by toolero 0.5.x carries no `schema_version` and is
read as version 1, which is the shape it has. A record with a version
this toolero does not know is read as far as possible, with a warning:
the fields listed above are taken where they exist and have a single
value, and anything else is ignored. The rules are the family's, set out
in its `CONVENTIONS.md`.

## When there is no usable output record

An analysis that stopped before
[`generate_manifest()`](https://erwinlares.github.io/toolero/reference/generate_manifest.md)
ran, or whose record cannot be parsed, may still have left its
accumulator behind. For each folder, `read_output_records()` reads the
output record when it can; otherwise it reads `accumulator.csv` from the
same folder, keeping the latest row per `file_path` exactly as
[`generate_manifest()`](https://erwinlares.github.io/toolero/reference/generate_manifest.md)
would, and warns that it did so. A folder with neither contributes no
rows, also with a warning. One incomplete folder therefore never stops
the others from being read. A path that does not exist at all is an
error, since that is a mistake in the call rather than a fact about a
run.

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

[`generate_manifest()`](https://erwinlares.github.io/toolero/reference/generate_manifest.md),
which writes the output record, and
[`save_output()`](https://erwinlares.github.io/toolero/reference/save_output.md),
which feeds it.

## Examples

``` r
output_dir <- withr::local_tempdir()

save_output(
  object = mtcars,
  file_path = fs::path(output_dir, "mtcars.rds"),
  .f = saveRDS,
  output_dir = output_dir
)
#> ℹ Created the directory /tmp/Rtmp6kXUCf/file19e724165569 to hold mtcars.rds.
generate_manifest(output_dir = output_dir, git_root = output_dir)
#> ✔ Wrote /tmp/Rtmp6kXUCf/file19e724165569/project-manifest.json describing 1
#>   artifact.

read_output_records(output_dir)
#> # A tibble: 1 × 13
#>   source    file_path r_class timestamp function_used status error_message note 
#>   <chr>     <chr>     <chr>   <chr>     <chr>         <chr>  <chr>         <chr>
#> 1 /tmp/Rtm… /tmp/Rtm… data.f… 2026-10-… saveRDS       succe… NA            NA   
#> # ℹ 5 more variables: read_from <chr>, schema_version <int>,
#> #   execution_context <chr>, generated_at <chr>, commit <chr>

if (FALSE) { # \dontrun{
# Several jobs brought back by submitr: label each job's rows by group.
jobs <- submitr::htc_collect()
jobs <- jobs[!is.na(jobs$output_dir), ]
records <- read_output_records(stats::setNames(jobs$output_dir, jobs$group_id))
} # }
```
