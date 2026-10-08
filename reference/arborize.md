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

  A character string. Path to the output PNG file. A relative path is
  written under the project root (see the Paths section). Defaults to
  `"syntactic-tree.png"` at the project root.

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

  A logical. Whether to write a companion `.yml` file recording the tree
  string and all rendering arguments alongside the PNG. Defaults to
  `TRUE`. The provenance file has the same name as the PNG but with a
  `.yml` extension and lives in the same directory. Pass `FALSE` to
  suppress it. (toolero 0.5.x and earlier used `.yaml`.)

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

7.  If `provenance = TRUE`, writes a companion `.yml` file recording the
    tree string and all rendering arguments.

On first use, Typst will download the required package from the Typst
package registry. This requires an internet connection. Subsequent
renders use the locally cached package.

Requires Quarto 1.4 or later with Typst support, and the `pdftools`
package for PDF-to-PNG conversion. Install `pdftools` with
`install.packages("pdftools")`.

## Paths

A relative path is read from the project root, not from the working
directory. So `save_output(fit, "output/fit.rds", saveRDS)` writes into
the project's own `output/` folder whether you call it from the project
root, from a document under `reports/`, or from a job on an HTCondor
execute node. You never need to wrap a path in
[`here::here()`](https://here.r-lib.org/reference/here.html). Doing so
still works, because
[`here::here()`](https://here.r-lib.org/reference/here.html) returns an
absolute path and absolute paths are used as given.

The project root is found afresh on every call, in this order:

1.  The job's scratch directory, when `_CONDOR_SCRATCH_DIR` names one.
    HTCondor sets that variable itself, inside every job.

2.  The nearest folder above the working directory that carries a
    project marker: the `.here` file
    [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
    writes, an `.Rproj` file, a package `DESCRIPTION`, or a version
    control folder such as `.git`.

3.  The working directory, when neither of the above applies.

Absolute paths (including those starting with `~`, or a drive letter on
Windows) and URLs such as `https://` or `s3://` are used as given. `..`
and `./` are not interpreted, so `"../data/x.csv"` means the folder
above the root; write an absolute path to leave the project. A bare
`"."` means the root itself.

Functions that read are forgiving about older code. A relative path that
does not exist at the project root but does exist relative to the
working directory is read from there, and a message says so. Functions
that write never guess: a relative path is always written under the
root.

A few arguments are deliberately left alone:

- [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
  reads `path`, `config` and `use_rprofile` from the working directory,
  because the project does not exist yet and so has no root.

- Under `Rscript`,
  [`resolve_input_path()`](https://erwinlares.github.io/toolero/reference/resolve_input_path.md)
  reads the command line argument as given. Run `Rscript` from the
  project root or pass an absolute path.

- Arguments passed on through `...` to another function reach it
  untouched.

- Where a default is "beside the input"
  ([`qmd_to_r()`](https://erwinlares.github.io/toolero/reference/qmd_to_r.md)
  and
  [`generate_kb_xml()`](https://erwinlares.github.io/toolero/reference/generate_kb_xml.md)),
  the output follows wherever the input was read from.

Two limits are worth knowing. A project nested inside another project is
not supported: the nearest marker wins, which can surprise you when you
work from the outer one. And on an execute node `~` and `$HOME` cannot
be trusted (`$HOME` can be the submit node's path), so prefer relative
paths in job scripts.

## References

syntree Typst package (v0.2.1):
<https://typst.app/universe/package/syntree>

lingotree Typst package (v1.0.0):
<https://typst.app/universe/package/lingotree>

## Examples

``` r
if (FALSE) { # \dontrun{
# Simple bracket notation (default) -- also writes tree-1.yml
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
