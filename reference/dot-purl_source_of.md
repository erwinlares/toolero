# Which document does a purled script say it came from?

Internal helper used by
[`check_project()`](https://erwinlares.github.io/toolero/reference/check_project.md).
Reads the first line of a script written by `R/purl.R`, which names its
source document, and returns that name. `NA` when the file does not
exist, and `""` when it exists but carries no such line (a hand-written
script, or one written by an older `R/purl.R`).

## Usage

``` r
.purl_source_of(r_path)
```

## Arguments

- r_path:

  Character. Path to a script.

## Value

A single string, or `NA_character_`.
