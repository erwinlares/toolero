# The criterion that identifies a project root

Internal helper. The same markers
[`here::here()`](https://here.r-lib.org/reference/here.html) looks for,
so that toolero's own functions and the
[`here::here()`](https://here.r-lib.org/reference/here.html) calls in a
scaffolded document agree on where the project root is: a `.here` file
(which
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
writes), an RStudio `.Rproj` file, an R package `DESCRIPTION`, a
`remake.yml`, a `.projectile` file, or a version control root (`.git`,
`.svn`).

## Usage

``` r
.project_root_criterion()
```

## Value

An `rprojroot` root criterion.
