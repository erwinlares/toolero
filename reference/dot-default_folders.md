# The standard toolero folder set

Internal helper returning the default project structure. Single source
of truth for
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md),
[`generate_project_config()`](https://erwinlares.github.io/toolero/reference/generate_project_config.md),
and
[`check_project()`](https://erwinlares.github.io/toolero/reference/check_project.md).

## Usage

``` r
.default_folders()
```

## Value

A character vector of folder paths, relative to the project root.

## Details

`R/` holds the `.R` script derived from the project's `.qmd` source,
whether that derivation happens through
[`qmd_to_r()`](https://erwinlares.github.io/toolero/reference/qmd_to_r.md)
or through the post-render hook scaffolded by
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md).
`scripts/` holds hand-written, human-maintained scripts. The distinction
matters because downstream packages resolve the derived script by
convention.
