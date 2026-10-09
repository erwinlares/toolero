# Which layout does the purl hook use in this project?

Internal helper used by
[`check_project()`](https://erwinlares.github.io/toolero/reference/check_project.md).
Mirrors the decision `R/purl.R` makes for itself: `"mirror"` when
`_quarto.yml` declares `project: type:` as `website` or `book`, and
`"flat"` otherwise, including when there is no `_quarto.yml`, no
`type:`, or a file that cannot be parsed.

## Usage

``` r
.purl_layout(path)
```

## Arguments

- path:

  Character. Path to the project root.

## Value

`"mirror"` or `"flat"`.
