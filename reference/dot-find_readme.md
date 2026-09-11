# Find a README file in a project directory

Internal helper locating a README regardless of capitalization or
extension. Any file whose stem matches `readme` counts: `README.md`,
`readme`, `Readme.pdf`, and `README.tex` all match. A directory named
`readme` does not, nor does `readme-old.md`, nor a double extension such
as `readme.tar.gz`.

## Usage

``` r
.find_readme(path)
```

## Arguments

- path:

  Character. Path to a project directory.

## Value

The full path to the first matching file, or `NULL` when the directory
holds none or does not exist.

## Details

Shared by
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md),
which refuses to write a README over one that already exists, and
[`check_project()`](https://erwinlares.github.io/toolero/reference/check_project.md),
which reports whether the project has one. Before this helper existed
the two disagreed:
[`check_project()`](https://erwinlares.github.io/toolero/reference/check_project.md)
matched any variant while
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
checked one exact filename, so a project holding `readme.txt` would
quietly acquire a second `README.md` beside it.
