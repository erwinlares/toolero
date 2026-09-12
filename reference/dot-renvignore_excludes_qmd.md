# Does a .renvignore exclude Quarto documents?

Internal helper used by
[`check_project()`](https://erwinlares.github.io/toolero/reference/check_project.md).
Matches any entry ending in `.qmd`, which covers `*.qmd`, `**/*.qmd`,
and a bare `analysis.qmd`.

## Usage

``` r
.renvignore_excludes_qmd(path)
```

## Arguments

- path:

  Character. Path to a project directory.

## Value

A single logical.
