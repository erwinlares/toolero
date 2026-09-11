# Read a project manifest from a project directory

Internal helper returning the parsed contents of `_toolero.yml` at the
root of `path`, or `NULL` when the project does not have one. A project
created before this file existed is a normal case, not an error, so the
absence is reported as `NULL` and callers decide what to do about it.

## Usage

``` r
.read_project_yml(path)
```

## Arguments

- path:

  Character. Path to a project directory.

## Value

A named list, or `NULL`.
