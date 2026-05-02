# Write a provenance YAML file alongside a rendered tree PNG

Records the tree string and all rendering arguments that produced a
given PNG file. The provenance file has the same name as the PNG but
with a `.yaml` extension, and is written to the same directory.

## Usage

``` r
.write_arborize_provenance(
  output,
  tree,
  tree_notation,
  typst_package,
  dpi,
  papersize,
  margin
)
```

## Arguments

- output:

  A character string. Absolute path to the PNG output file.

- tree:

  A character string. The tree string passed to
  [`arborize()`](https://erwinlares.github.io/toolero/reference/arborize.md).

- tree_notation:

  A character string. One of `"simple"` or `"structured"`.

- typst_package:

  A character string. The resolved Typst package.

- dpi:

  A numeric value. DPI used for rendering.

- papersize:

  A character string. Typst paper size used.

- margin:

  A character string. Page margin used.

## Value

Invisibly returns the path to the provenance file.
