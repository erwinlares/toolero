# Initialize a new R project with a standard folder structure

`init_project()` creates a new R project at the given path with an
opinionated folder structure suited for research workflows. It
optionally initializes `renv` for package management and git for version
control.

## Usage

``` r
init_project(
  path,
  use_renv = TRUE,
  use_git = TRUE,
  extra_folders = NULL,
  open = FALSE,
  uw_branding = FALSE
)
```

## Arguments

- path:

  A character string with the path and name of the new project (e.g.,
  `"~/Documents/my-project"`).

- use_renv:

  Logical. If `TRUE`, initializes `renv` in the new project. Defaults to
  `TRUE`.

- use_git:

  Logical. If `TRUE`, initializes a git repository in the new project.
  Defaults to `TRUE`.

- extra_folders:

  A character vector of additional folder names to create inside the
  project. Defaults to `NULL`.

- open:

  Logical. If `TRUE`, opens the new project in RStudio after creation.
  Defaults to `TRUE`.

- uw_branding:

  Logical. If `TRUE`, creates an `assets/` folder and populates it with
  UW-Madison RCI branding files (`styles.css`, `header.html`,
  `rci-banner.png`). Defaults to `FALSE`.

## Value

Called for its side effects. Does not return a value.

## Examples

``` r
# \donttest{
init_project(path = file.path(tempdir(), "project1"),
             use_renv = FALSE, use_git = FALSE)
#> ! New project /tmp/RtmpS8Xp4P/project1 would be nested inside an existing
#>   project /tmp/RtmpS8Xp4P/, which is rarely a good idea.
#> ℹ If this is unexpected, the here package has a function, `here::dr_here()`
#>   that reveals why a particular path is regarded as a project. To learn more,
#>   run `here::dr_here()` in a fresh R session that has /tmp/RtmpS8Xp4P/ as
#>   working directory.
#> Error in ui_yep(x = x, yes = yes, no = no, n_yes = n_yes, n_no = n_no,     shuffle = shuffle, .envir = .envir): ✖ User input required, but session is not interactive.
#> ℹ Query: "Do you want to create anyway?"

init_project(path = file.path(tempdir(), "project2"),
             uw_branding = TRUE, use_renv = FALSE, use_git = FALSE)
#> ! New project /tmp/RtmpS8Xp4P/project2 would be nested inside an existing
#>   project /tmp/RtmpS8Xp4P/, which is rarely a good idea.
#> ℹ If this is unexpected, the here package has a function, `here::dr_here()`
#>   that reveals why a particular path is regarded as a project. To learn more,
#>   run `here::dr_here()` in a fresh R session that has /tmp/RtmpS8Xp4P/ as
#>   working directory.
#> Error in ui_yep(x = x, yes = yes, no = no, n_yes = n_yes, n_no = n_no,     shuffle = shuffle, .envir = .envir): ✖ User input required, but session is not interactive.
#> ℹ Query: "Do you want to create anyway?"

init_project(path = file.path(tempdir(), "project3"),
             extra_folders = c("notebooks"),
             use_renv = FALSE, use_git = FALSE)
#> ! New project /tmp/RtmpS8Xp4P/project3 would be nested inside an existing
#>   project /tmp/RtmpS8Xp4P/, which is rarely a good idea.
#> ℹ If this is unexpected, the here package has a function, `here::dr_here()`
#>   that reveals why a particular path is regarded as a project. To learn more,
#>   run `here::dr_here()` in a fresh R session that has /tmp/RtmpS8Xp4P/ as
#>   working directory.
#> Error in ui_yep(x = x, yes = yes, no = no, n_yes = n_yes, n_no = n_no,     shuffle = shuffle, .envir = .envir): ✖ User input required, but session is not interactive.
#> ℹ Query: "Do you want to create anyway?"
# }
```
