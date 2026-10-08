# Write a cleaned data frame to a CSV file

`write_clean_csv()` writes a data frame to a CSV file using
[`readr::write_csv()`](https://readr.tidyverse.org/reference/write_delim.html)
and emits a cli confirmation message reporting the number of rows and
columns written. It is the natural counterpart to
[`read_clean_csv()`](https://erwinlares.github.io/toolero/reference/read_clean_csv.md),
reinforcing the convention that `data-raw/` holds original inputs and
`data/` holds cleaned, analysis-ready outputs.

## Usage

``` r
write_clean_csv(data, path, overwrite = FALSE, ...)
```

## Arguments

- data:

  A data frame or tibble to write.

- path:

  A character string with the path to the output CSV file. A relative
  path is written under the project root (see the Paths section), and
  its folder is created if it does not exist.

- overwrite:

  Logical. If `FALSE` (the default), errors if the file already exists.
  Set to `TRUE` to overwrite an existing file.

- ...:

  Additional arguments passed to
  [`readr::write_csv()`](https://readr.tidyverse.org/reference/write_delim.html),
  such as `append`, `col_names`, or `quote`.

## Value

Invisibly returns `path`, resolved from the project root when it was
relative.

## Details

If column names are not already clean, `write_clean_csv()` applies
[`janitor::clean_names()`](https://sfirke.github.io/janitor/reference/clean_names.html)
before writing and emits a warning listing the affected columns.

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
data <- read_clean_csv(sample_path)

# Write to a temp file
out <- tempfile(fileext = ".csv")
write_clean_csv(data, out)
#> ✔ Wrote 344 rows and 8 columns to /tmp/Rtmp6kXUCf/file19e72d58b9b8.csv.

# Overwrite an existing file
write_clean_csv(data, out, overwrite = TRUE)
#> ✔ Wrote 344 rows and 8 columns to /tmp/Rtmp6kXUCf/file19e72d58b9b8.csv.

# Dirty names are cleaned automatically with a warning
dirty <- data.frame("First Name" = "Jane", "Last Name" = "Doe",
                    check.names = FALSE)
write_clean_csv(dirty, tempfile(fileext = ".csv"))
#> Warning: Column names were not clean -- applying `janitor::clean_names()` before
#> writing. Affected columns: "First Name" and "Last Name"
#> ✔ Wrote 1 row and 2 columns to /tmp/Rtmp6kXUCf/file19e73d5de709.csv.
# }
```
