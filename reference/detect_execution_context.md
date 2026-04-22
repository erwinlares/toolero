# Detect the current execution context

Identifies which of three execution environments the code is currently
running in: an interactive R session, a `quarto render` call, or a plain
`Rscript` invocation. This is useful for writing code that behaves
correctly across all three contexts, such as resolving input file paths
in a portable way.

## Usage

``` r
detect_execution_context(interactive_fn = interactive)
```

## Arguments

- interactive_fn:

  A function. Used to detect whether the session is interactive.
  Defaults to
  [`base::interactive`](https://rdrr.io/r/base/interactive.html).
  Override in tests to simulate different execution environments.

## Value

A character string, one of `"interactive"`, `"quarto"`, or `"rscript"`.

## Details

Detection follows a priority order:

1.  If [`interactive()`](https://rdrr.io/r/base/interactive.html) is
    `TRUE`, returns `"interactive"`.

2.  If the environment variable `QUARTO_DOCUMENT_PATH` is set and
    non-empty, returns `"quarto"`.

3.  Otherwise, returns `"rscript"`.

## Examples

``` r
# \donttest{
context <- detect_execution_context()

input_file <- switch(context,
  interactive = "data/sample.csv",
  quarto      = params$input_file,
  rscript     = commandArgs(trailingOnly = TRUE)[1]
)
# }
```
