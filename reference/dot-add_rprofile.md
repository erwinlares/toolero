# Preserve access to a personal `.Rprofile`

Internal helper backing
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)'s
`use_rprofile` argument. R reads exactly one `.Rprofile` per session:
the one in the current working directory if it exists, `~/.Rprofile`
only if it does not.
[`renv::scaffold()`](https://rstudio.github.io/renv/reference/scaffold.html)
writes a project-level `.Rprofile` containing
`source("renv/activate.R")`, so once a project is under renv, whatever
aliases, options, or helper functions a user keeps in a personal
`.Rprofile` stop loading for that project – silently, since nothing
errors.

## Usage

``` r
.add_rprofile(path, source = "~/.Rprofile")
```

## Arguments

- path:

  A character string. The project root.

- source:

  A character string. The file to source, written into the guard exactly
  as given (e.g. `"~/.Rprofile"` or `"~/dotfiles/rprofile"`). Resolved
  by
  [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
  from its `use_rprofile` argument.

## Value

Called for its side effects. Returns `invisible(NULL)`.

## Details

This appends a guarded block to the project's `.Rprofile` (creating the
file if `use_renv = FALSE` left none behind) that sources `source` if it
exists, after renv's own activation line so the project library is set
up first. `source` is written into the block exactly as given – never
expanded or resolved to an absolute path here – so a `~`-relative value
stays portable across whoever opens the project, the same way the
default `~/.Rprofile` already does. The existence check happens at every
session start rather than once at project-creation time, so a file
written or edited after the project is created is still picked up.
