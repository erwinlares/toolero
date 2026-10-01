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
  output record files themselves. A named vector labels each folder's
  rows in the `source` column with its name; an unnamed one (or an
  element with an empty name) uses the path as given. If `NULL` (the
  default), reads the project's own output folder, resolved exactly as
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
#> ℹ Created the directory /tmp/RtmplBCetp/file1c2540bb19d1 to hold mtcars.rds.
generate_manifest(output_dir = output_dir, git_root = output_dir)
#> ✔ Wrote /tmp/RtmplBCetp/file1c2540bb19d1/project-manifest.json describing 1
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
