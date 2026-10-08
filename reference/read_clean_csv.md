# Read and clean a CSV file

`read_clean_csv()` reads a CSV file, standardizes column names,
optionally handles missing values, and optionally prints an ingest
summary. It combines
[`readr::read_csv()`](https://readr.tidyverse.org/reference/read_delim.html),
[`janitor::clean_names()`](https://sfirke.github.io/janitor/reference/clean_names.html),
and
[`tidyr::drop_na()`](https://tidyr.tidyverse.org/reference/drop_na.html)
into a single, reproducibility-friendly step.

## Usage

``` r
read_clean_csv(
  path,
  na = c("", "NA"),
  drop_na = FALSE,
  summary = FALSE,
  verbose = FALSE,
  ...
)
```

## Arguments

- path:

  A character string with the path to the CSV file. A relative path is
  read from the project root (see the Paths section).

- na:

  A character vector of strings to treat as missing values. Passed
  directly to
  [`readr::read_csv()`](https://readr.tidyverse.org/reference/read_delim.html).
  Defaults to `c("", "NA")`, which matches `readr`'s own default
  behavior.

- drop_na:

  Logical or character vector. If `FALSE` (the default), no rows are
  dropped. If `TRUE`, drops all rows containing any missing value. If a
  character vector of column names, drops only rows with missing values
  in those columns. Always emits a cli message reporting how many rows
  were dropped and how many remain.

- summary:

  Logical. If `TRUE`, prints a brief ingest summary after reading and
  cleaning: row and column counts, number of column names cleaned, and
  missing value totals. Reflects the final state of the tibble after any
  `drop_na` action. Defaults to `FALSE`.

- verbose:

  Logical. If `TRUE`, displays column type messages from
  [`readr::read_csv()`](https://readr.tidyverse.org/reference/read_delim.html).
  Defaults to `FALSE`.

- ...:

  Additional arguments passed to
  [`readr::read_csv()`](https://readr.tidyverse.org/reference/read_delim.html),
  such as `col_types`, `skip`, or `locale`.

## Value

A tibble with cleaned column names.

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

## Examples

``` r
# \donttest{
sample_path <- system.file("templates", "sample.csv", package = "toolero")

# Basic usage
data <- read_clean_csv(sample_path)

# Explicit missing-value codes
data <- read_clean_csv(sample_path, na = c("", "NA", "N/A", ".", "-999"))

# Drop rows missing in any column
data <- read_clean_csv(sample_path, drop_na = TRUE)
#> Dropped 11 rows with missing values across all columns -- 333 rows remaining.

# Drop rows missing in specific columns
data <- read_clean_csv(sample_path, drop_na = c("bill_length_mm", "sex"))
#> Dropped 11 rows with missing values in columns: "bill_length_mm" and "sex" --
#> 333 rows remaining.

# Print ingest summary
data <- read_clean_csv(sample_path, summary = TRUE)
#> ✔ Read 344 rows and 8 columns.
#> ℹ 0 column names cleaned.
#> ℹ 5 columns contain missing values (19 total missing values).

# Combine arguments
data <- read_clean_csv(
  sample_path,
  na      = c("", "NA", "N/A", "."),
  drop_na = TRUE,
  summary = TRUE
)
#> Dropped 11 rows with missing values across all columns -- 333 rows remaining.
#> ✔ Read 333 rows and 8 columns.
#> ℹ 0 column names cleaned.
#> ℹ 0 columns contain missing values (0 total missing values).
# }
```
