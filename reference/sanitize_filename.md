# Sanitize a string for use in a filename

Lowercases, replaces every run of non-alphanumeric characters with a
single `-`, and strips leading and trailing dashes.

## Usage

``` r
sanitize_filename(x)
```

## Arguments

- x:

  A character vector.

## Value

A character vector of the same length.

## Details

The collapsing is what the rest of
[`write_by_group()`](https://erwinlares.github.io/toolero/reference/write_by_group.md)'s
filename scheme rests on: because a run of separators becomes exactly
one dash, a sanitized value can contain a single `-` but never two
consecutive ones. That leaves `--` free to mark the boundary between
grouping columns without any possibility of colliding with content.
