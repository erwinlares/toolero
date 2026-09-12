# Does a lockfile record no packages?

Internal helper used by
[`check_project()`](https://erwinlares.github.io/toolero/reference/check_project.md).
Returns `TRUE` only when the lockfile parses and records no packages
other than `renv` itself.

## Usage

``` r
.renv_lock_is_bare(lockfile)
```

## Arguments

- lockfile:

  Character. Path to a `renv.lock` file.

## Value

A single logical.

## Details

`renv` is discounted because
[`renv::scaffold()`](https://rstudio.github.io/renv/reference/scaffold.html)
installs it into the project library and records it, so the lockfile of
a freshly scaffolded project is not literally empty. What matters is
whether anything the *analysis* depends on is in there.

An unparseable lockfile returns `FALSE`: that is a different problem and
this helper should not report it as this one.
