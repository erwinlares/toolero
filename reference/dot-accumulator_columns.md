# Accumulator column schema

Internal helper returning the canonical column names of
`accumulator.csv`, in order. Single source of truth shared by
[`.append_accumulator_row()`](https://erwinlares.github.io/toolero/reference/dot-append_accumulator_row.md)
and the accumulator reader behind
[`generate_manifest()`](https://erwinlares.github.io/toolero/reference/generate_manifest.md),
so that schema drift surfaces as an error rather than as silently
misaligned rows.

## Usage

``` r
.accumulator_columns()
```

## Value

A character vector of column names.
