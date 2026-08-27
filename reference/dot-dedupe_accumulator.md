# Deduplicate accumulator rows by file path

Internal helper used by
[`generate_manifest()`](https://erwinlares.github.io/toolero/reference/generate_manifest.md)
to collapse an append-only accumulator to one row per `file_path`,
keeping the most recent row for each.

## Usage

``` r
.dedupe_accumulator(accumulator)
```

## Arguments

- accumulator:

  A data frame with the columns given by
  [`.accumulator_columns()`](https://erwinlares.github.io/toolero/reference/dot-accumulator_columns.md).

## Value

A data frame with the same columns, one row per distinct `file_path`,
ordered by `timestamp` ascending.

## Details

The accumulator is append-only, so re-running an analysis within a
session leaves superseded rows behind. Rows are ordered by `timestamp` –
which sorts correctly as a string, since
[`save_output()`](https://erwinlares.github.io/toolero/reference/save_output.md)
writes UTC with millisecond precision – and the last row for each path
is kept. Position in the file breaks ties, so two rows sharing a
timestamp resolve in append order.

Note that the surviving row for a path may record a failure: if a save
succeeded and a later re-run of the same path failed, the failure is
what the manifest reports. This is the intended reading. The manifest
describes the state of the project at the end of the run, not the best
outcome observed along the way.
