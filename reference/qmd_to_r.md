# Extract R code from a Quarto document

`qmd_to_r()` extracts R code chunks from a `.qmd` file and writes them
to a standalone `.R` script using
[`knitr::purl()`](https://rdrr.io/pkg/knitr/man/knit.html). It works on
any `.qmd` file regardless of whether it was created with
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md).

## Usage

``` r
qmd_to_r(input, output = NULL, documentation = 1L, quiet = TRUE)
```

## Arguments

- input:

  A character string with the path to the `.qmd` file.

- output:

  A character string with the path to the output `.R` file. If `NULL`
  (the default), the output file is written to the same directory as
  `input` with the `.qmd` extension replaced by `.R`.

- documentation:

  An integer controlling how much documentation is included in the
  extracted script. Passed to
  [`knitr::purl()`](https://rdrr.io/pkg/knitr/man/knit.html): `0` strips
  all documentation; `1` (the default) includes chunk labels as
  comments; `2` includes full roxygen blocks.

- quiet:

  Logical. If `TRUE` (the default), suppresses knitr's own output.
  toolero provides its own cli feedback instead.

## Value

Invisibly returns the path to the output `.R` file.

## Examples

``` r
# \donttest{
# Extract R code from a qmd file
qmd <- tempfile(fileext = ".qmd")
writeLines(c(
  "---",
  "title: Analysis",
  "---",
  "",
  "```{r}",
  "x <- 1 + 1",
  "```"
), qmd)

# Default output path: same directory, .R extension
qmd_to_r(input = qmd)
#> ✔ Extracted R code from /tmp/Rtmpkktyx4/file4f36d1c3e5f.qmd to /tmp/Rtmpkktyx4/file4f36d1c3e5f.R.

# Explicit output path
out <- tempfile(fileext = ".R")
qmd_to_r(input = qmd, output = out)
#> ✔ Extracted R code from /tmp/Rtmpkktyx4/file4f36d1c3e5f.qmd to /tmp/Rtmpkktyx4/file4f364a558fc9.R.

# Strip all documentation
qmd_to_r(input = qmd, output = out, documentation = 0L)
#> ✔ Extracted R code from /tmp/Rtmpkktyx4/file4f36d1c3e5f.qmd to /tmp/Rtmpkktyx4/file4f364a558fc9.R.
# }
```
