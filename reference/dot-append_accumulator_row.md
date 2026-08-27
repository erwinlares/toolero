# Append a row to the project accumulator

Internal helper used by
[`save_output()`](https://erwinlares.github.io/toolero/reference/save_output.md)
to record one row of metadata to `output_dir/accumulator.csv`, creating
the file (with headers) on first write and appending without headers
thereafter.

## Usage

``` r
.append_accumulator_row(row, output_dir = "output")
```

## Arguments

- row:

  A single-row data frame whose columns match
  [`.accumulator_columns()`](https://erwinlares.github.io/toolero/reference/dot-accumulator_columns.md)
  exactly, in order.

- output_dir:

  Character. Directory containing (or to contain) `accumulator.csv`.

## Value

The path to the accumulator, invisibly.

## Details

When the accumulator already exists, its header is read and compared
against the expected schema before appending. A mismatch aborts rather
than appending misaligned rows to a file written under a different
schema version.

`NA` values are written as empty fields. Any reader of this file must
pass `na.strings = ""` to recover them as `NA` rather than as empty
strings.
