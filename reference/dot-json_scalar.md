# Reduce a parsed JSON value to a single string

Internal helper used by
[`read_output_records()`](https://erwinlares.github.io/toolero/reference/read_output_records.md).
A `null` or absent value becomes `NA`, as does anything that is not a
single value (an array or object, which only a record with an unknown
schema version could hold where version 1 has a scalar).

## Usage

``` r
.json_scalar(x)
```

## Arguments

- x:

  A value from `jsonlite::fromJSON(simplifyVector = FALSE)`.

## Value

A single character string, or `NA_character_`.
