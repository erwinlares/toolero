# Ensure the parent directory of a file exists

Internal helper used by
[`save_output()`](https://erwinlares.github.io/toolero/reference/save_output.md)
and
[`.append_accumulator_row()`](https://erwinlares.github.io/toolero/reference/dot-append_accumulator_row.md)
to confirm that the directory holding a file exists before writing to
it. Many save functions error on a missing directory, and that error is
a poor description of what actually went wrong.

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

Missing directories are created rather than reported as an error, since
[`save_output()`](https://erwinlares.github.io/toolero/reference/save_output.md)
is expected to run unattended on a cluster where nobody is available to
intervene. Creation is announced through `cli` so that the action leaves
a trace in the job log, whether or not anyone is watching at the time. A
bare filename resolves to `"."`, which always exists, so no message is
emitted in that case.
