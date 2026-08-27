# Read the project accumulator

Internal helper used by
[`generate_manifest()`](https://erwinlares.github.io/toolero/reference/generate_manifest.md)
to read `output_dir/accumulator.csv` back into a data frame, validating
its header against the expected schema.

## Usage

``` r
.read_accumulator(output_dir = "output")
```

## Arguments

- output_dir:

  Character. Directory containing `accumulator.csv`.

## Value

A data frame with the columns given by
[`.accumulator_columns()`](https://erwinlares.github.io/toolero/reference/dot-accumulator_columns.md),
all of type character.

## Details

A missing accumulator is an error rather than an empty result. The file
is created by the first
[`save_output()`](https://erwinlares.github.io/toolero/reference/save_output.md)
call, so its absence means no save was ever recorded – most often
because
[`save_output()`](https://erwinlares.github.io/toolero/reference/save_output.md)
was called with a different `output_dir`, or with `manifest = FALSE`, or
was never reached at all. Returning an empty manifest in that case would
present a setup mistake as a finished record.

Every column is read as character. Timestamps in particular must not be
coerced, since
[`.dedupe_accumulator()`](https://erwinlares.github.io/toolero/reference/dot-dedupe_accumulator.md)
compares them lexicographically and relies on the exact string written
by
[`save_output()`](https://erwinlares.github.io/toolero/reference/save_output.md).

Empty fields are read back as `NA` via `na.strings = ""`, matching the
`na = ""` convention used when the accumulator is written. Without this
the `error_message` column of every successful row would return as an
empty string rather than `NA`, and that difference would surface in the
manifest.
