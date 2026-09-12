# Does the project contain R or Quarto source files?

Internal helper used by
[`check_project()`](https://erwinlares.github.io/toolero/reference/check_project.md)
to decide whether an empty lockfile is worth reporting.

## Usage

``` r
.project_has_sources(path, folders)
```

## Arguments

- path:

  Character. Path to a project directory.

- folders:

  Character vector. Folders declared for this project.

## Value

A single logical.

## Details

Searches the project root without recursing, plus each declared folder
with recursion. Deliberately not a recursive sweep of the whole project:
`renv/library` holds the sources of every installed package, which would
be both slow to walk and wrong to count as the project's own code.
