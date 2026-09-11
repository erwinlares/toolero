# Read and validate a project configuration file

Internal helper that parses a project configuration file and returns its
folder set and conventions. The same schema serves three roles – a
hand-written config passed to
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md),
the `_toolero.yml` a project carries, and the audit target for
[`check_project()`](https://erwinlares.github.io/toolero/reference/check_project.md)
– so this is the one place the schema is validated.

## Usage

``` r
.read_config_file(config, arg = "config")
```

## Arguments

- config:

  Character. Path to the YAML file.

- arg:

  Character. Name of the calling argument, used in error messages.

## Value

A named list with elements `folders` (character vector) and
`conventions` (named list, defaults filled in for any key the file does
not supply).

## Details

A file with no `schema_version` is treated as schema 1, so configs
written by earlier versions of toolero, which carried only a `folders:`
key, continue to work unchanged.
