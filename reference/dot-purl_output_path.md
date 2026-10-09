# Expected purl output path for a .qmd

Internal helper used by
[`check_project()`](https://erwinlares.github.io/toolero/reference/check_project.md).
Follows the convention `R/purl.R` itself follows. In an ordinary project
a document's derived script is flat, `R/<name>.R`. In a website or book
it lives under `R/` at the same path, relative to the project root, that
the document itself occupies, so two documents sharing a filename in
different directories (e.g. a directory-per-post convention using
`index.qmd`) map to different output paths.

## Usage

``` r
.purl_output_path(qmd_path, path, layout = .purl_layout(path))
```

## Arguments

- qmd_path:

  Character. Full path to a `.qmd` file.

- path:

  Character. Path to the project root.

- layout:

  `"flat"` or `"mirror"`. Defaults to the layout the project itself
  uses, see
  [`.purl_layout()`](https://erwinlares.github.io/toolero/reference/dot-purl_layout.md).

## Value

A single character string: the full path where the purled `.R` script is
expected.
