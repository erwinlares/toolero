# Normalize a value for single-line CSV storage

Internal helper collapsing embedded newlines and runs of whitespace to
single spaces, so that one accumulator row occupies one physical line.

## Usage

``` r
.flatten_field(x)
```

## Arguments

- x:

  A character string or `NULL`.

## Value

A single character string, or `NA_character_` when `x` is `NULL`.
