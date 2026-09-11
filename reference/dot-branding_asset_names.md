# Standardized branding asset filenames

Internal helper returning the five filenames that every branding mode
produces in a project's `assets/` directory. Both `branding = TRUE` and
`branding = "uw-madison"` write these exact names, differing only in
content, so that
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
and `containr` can reference them without knowing which mode was used.

## Usage

``` r
.branding_asset_names()
```

## Value

A character vector of filenames.
