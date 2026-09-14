# Detect the current execution context

Identifies which of three execution environments the code is currently
running in: an interactive R session, a `quarto render` call, or a plain
`Rscript` invocation. This is useful for writing code that behaves
correctly across all three contexts, such as choosing figure dimensions
or deciding whether to report progress.

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

To resolve an input data path across the same three contexts, use
[`resolve_input_path()`](https://erwinlares.github.io/toolero/reference/resolve_input_path.md),
which calls this function and then validates what the chosen branch
produced.

Detection follows a priority order:

1.  If [`interactive()`](https://rdrr.io/r/base/interactive.html) is
    `TRUE`, returns `"interactive"`.

2.  If the environment variable `QUARTO_DOCUMENT_PATH` is set and
    non-empty, returns `"quarto"`.

3.  Otherwise, returns `"rscript"`.

The order is unobservable in practice, and that is worth recording so
nobody has to re-derive it. `QUARTO_DOCUMENT_PATH` is set only by Quarto
rendering a document, and every path that renders one – `quarto render`,
`quarto preview`,
[`quarto::quarto_render()`](https://quarto-dev.github.io/quarto-r/reference/quarto_render.html),
the RStudio Render button – runs the R code in a spawned process that is
not interactive. Running chunks inline in RStudio is the reverse case:
the session is interactive and the variable is unset (checked in
RStudio, September 2026). The two tests therefore never fire together,
so there is no case in which the priority arbitrates anything.

## See also

[`resolve_input_path()`](https://erwinlares.github.io/toolero/reference/resolve_input_path.md)
for the input-path case specifically.

## Examples

``` r
# \donttest{
# Behave differently depending on where the code is running. Progress
# output is useful at a console and only clutters a cluster job log.
context <- detect_execution_context()

if (context == "rscript") {
  options(cli.progress_show_after = Inf)
}
# }
```
