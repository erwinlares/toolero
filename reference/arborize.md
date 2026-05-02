# Render a syntactic tree as a PNG image

Takes a syntactic tree and renders it using Quarto's Typst engine,
exporting the result as a PNG image. Supports two rendering backends
controlled by `tree_notation`:

## Usage

``` r
arborize(
  tree,
  output = "syntactic-tree.png",
  dpi = 300,
  tree_notation = c("simple", "structured"),
  papersize = "a5",
  margin = "0.5cm",
  provenance = TRUE,
  overwrite = FALSE
)
```

## Arguments

- tree:

  A character string. For `tree_notation = "simple"`, a bracket notation
  string e.g. `"[S [NP] [VP]]"`. For `tree_notation = "structured"`, a
  lingotree `tree()` call string.

- output:

  A character string. Path to the output PNG file. Defaults to
  `"syntactic-tree.png"` in the current working directory.

- dpi:

  A numeric value. Resolution of the output PNG in dots per inch.
  Defaults to `300`. Use `600` for print-quality output.

- tree_notation:

  A character string. One of `"simple"` (default) or `"structured"`.
  Controls which Typst rendering backend is used. See Details.

- papersize:

  A character string. Typst paper size for the intermediate PDF.
  Defaults to `"a5"`. Increase to `"a4"` for very wide trees.

- margin:

  A character string. Page margin for the intermediate PDF. Defaults to
  `"0.5cm"`. Reduce for tighter crops around the tree.

- provenance:

  A logical. Whether to write a companion `.yaml` file recording the
  tree string and all rendering arguments alongside the PNG. Defaults to
  `TRUE`. The provenance file has the same name as the PNG but with a
  `.yaml` extension and lives in the same directory. Pass `FALSE` to
  suppress it.

- overwrite:

  A logical. Whether to overwrite existing output files. When `TRUE`,
  overwrites both the PNG and the provenance file if they exist.
  Defaults to `FALSE`.

## Value

Invisibly returns the path to the output PNG file.

## Details

- `"simple"` uses `@preview/syntree` and accepts a bracket notation
  string, e.g. `"[S [NP [Det the] [N cat]] [VP [V sat]]]"`. This is the
  most compact input format and suits basic linguistic trees.

- `"structured"` uses `@preview/lingotree` and accepts a nested `tree()`
  call string. This backend supports per-node styling, movement arrows,
  and multi-dominant trees.

The function is useful for producing standalone tree figures that can be
embedded in any document format – LaTeX, Word, HTML, or presentations –
without requiring a full LaTeX installation.

`arborize()` performs the following steps:

1.  Validates inputs and resolves the Typst package from
    `tree_notation`.

2.  Builds a minimal `.qmd` document via
    [`.build_arborize_qmd()`](https://erwinlares.github.io/toolero/reference/dot-build_arborize_qmd.md).

3.  Writes the document and renders it inside a self-cleaning temporary
    directory managed by
    [`withr::with_tempdir()`](https://withr.r-lib.org/reference/with_tempfile.html).

4.  Calls
    [`quarto::quarto_render()`](https://quarto-dev.github.io/quarto-r/reference/quarto_render.html)
    to produce an intermediate PDF via Typst.

5.  Converts the PDF to PNG using
    [`pdftools::pdf_convert()`](https://docs.ropensci.org/pdftools//reference/pdf_render_page.html).

6.  Reads the PNG bytes into memory before the temporary directory is
    deleted, then writes them to the specified output path.

7.  If `provenance = TRUE`, writes a companion `.yaml` file recording
    the tree string and all rendering arguments.

On first use, Typst will download the required package from the Typst
package registry. This requires an internet connection. Subsequent
renders use the locally cached package.

Requires Quarto 1.4 or later with Typst support, and the `pdftools`
package for PDF-to-PNG conversion. Install `pdftools` with
`install.packages("pdftools")`.

## References

syntree Typst package (v0.2.1):
<https://typst.app/universe/package/syntree>

lingotree Typst package (v1.0.0):
<https://typst.app/universe/package/lingotree>

## Examples

``` r
if (FALSE) { # \dontrun{
# Simple bracket notation (default) -- also writes tree-1.yaml
arborize("[NP [Det the] [N cat]]", output = "my-trees/tree-1.png")

# Suppress provenance file
arborize("[NP [Det the] [N cat]]", provenance = FALSE)

# Wider tree with print-quality output
arborize(
  paste0(
    "[Aspectual Classes ",
    "[Statives [States]] ",
    "[Dynamic ",
    "[Atelic [Activities]] ",
    "[Telic ",
    "[Instantaneous [Achievements]] ",
    "[Durative [Accomplishments]]]]]"
  ),
  output    = "aspectual-classes.png",
  dpi       = 600,
  papersize = "a4"
)

# Structured notation using lingotree
arborize(
  "tree(
    tag: [VP],
    tree(
      tag: [DP],
      [every],
      [farmer]
    ),
    [smiled]
  )",
  tree_notation = "structured",
  output        = "vp-tree.png"
)
} # }
```
