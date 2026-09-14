# Ensure the parent directory of a file exists

Internal helper confirming that the directory holding a file exists
before anything writes to it. Used by
[`save_output()`](https://erwinlares.github.io/toolero/reference/save_output.md),
[`.append_accumulator_row()`](https://erwinlares.github.io/toolero/reference/dot-append_accumulator_row.md),
[`generate_manifest()`](https://erwinlares.github.io/toolero/reference/generate_manifest.md)
and
[`qmd_to_r()`](https://erwinlares.github.io/toolero/reference/qmd_to_r.md).

## Usage

``` r
.ensure_directory(file_path)
```

## Arguments

- file_path:

  Character. The path whose parent directory is checked.

## Value

The directory path, invisibly.

## Details

The functions that do the writing error unhelpfully on a missing
directory. [`saveRDS()`](https://rdrr.io/r/base/readRDS.html) and
[`knitr::purl()`](https://rdrr.io/pkg/knitr/man/knit.html) both fail
through a connection, naming the file rather than the directory that is
actually absent, which sends the reader looking in the wrong place.

Missing directories are created rather than reported as an error, since
the callers are expected to run unattended on a cluster where nobody is
available to intervene. Creation is announced through `cli` so that the
action leaves a trace in the job log, whether or not anyone is watching
at the time. A bare filename resolves to `"."`, which always exists, so
no message is emitted in that case.
