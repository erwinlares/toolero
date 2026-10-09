# Does a purled script belong to a different, still-existing document?

Internal helper used by
[`check_project()`](https://erwinlares.github.io/toolero/reference/check_project.md).
`TRUE` when the script at `r_path` names a source document other than
`rel_qmd` and that document still exists under `path`. A script that
names a document that has since moved or been deleted is stale rather
than contested, so it returns `FALSE`, as it does for a script with no
such line.

## Usage

``` r
.purl_claimed_by_other(r_path, rel_qmd, path)
```

## Arguments

- r_path:

  Character. Path to the expected script.

- rel_qmd:

  Character. The document, relative to the project root.

- path:

  Character. Path to the project directory.

## Value

A single logical.
