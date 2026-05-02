# Build a throwaway Quarto document for syntactic tree rendering

Constructs the content of a minimal `.qmd` file that imports the
appropriate Typst tree package and renders one syntactic tree. The
generated Typst block differs depending on `tree_notation`:

## Usage

``` r
.build_arborize_qmd(
  tree,
  tree_notation = c("simple", "structured"),
  typst_package,
  papersize = "a5",
  margin = "0.5cm"
)
```

## Arguments

- tree:

  A character string. The syntactic tree in the notation appropriate for
  `tree_notation`.

- tree_notation:

  A character string. One of `"simple"` or `"structured"`.

- typst_package:

  A character string. The resolved Typst package import string, derived
  internally from `tree_notation`.

- papersize:

  A character string. Typst paper size.

- margin:

  A character string. Page margin.

## Value

A character string containing the complete `.qmd` file content.

## Details

- `"simple"` uses `@preview/syntree` and bracket notation

- `"structured"` uses `@preview/lingotree` and nested `tree()` calls

Separating this builder from
[`arborize()`](https://erwinlares.github.io/toolero/reference/arborize.md)
makes the QMD content testable without requiring a Quarto installation.
