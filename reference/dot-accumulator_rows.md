# Turn deduplicated accumulator rows into rows

Internal helper used by
[`read_output_records()`](https://erwinlares.github.io/toolero/reference/read_output_records.md)
for the accumulator fallback.

## Usage

``` r
.accumulator_rows(artifacts, source)
```

## Arguments

- artifacts:

  A data frame with the columns given by
  [`.accumulator_columns()`](https://erwinlares.github.io/toolero/reference/dot-accumulator_columns.md),
  as returned by
  [`.dedupe_accumulator()`](https://erwinlares.github.io/toolero/reference/dot-dedupe_accumulator.md).

- source:

  Character. The label for these rows.

## Value

A data frame on
[`.output_records_template()`](https://erwinlares.github.io/toolero/reference/dot-output_records_template.md).
