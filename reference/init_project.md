# Initialize a new R project with a standard folder structure

`init_project()` creates a new R project at the given path with an
opinionated folder structure suited for research workflows. It
optionally initializes `renv` for package management and git for version
control.

## Usage

``` r
init_project(
  file_path,
  use_renv = TRUE,
  use_git = TRUE,
  extra_folders = NULL,
  open = FALSE,
  uw_branding = FALSE
)
```

## Arguments

- file_path:

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
init_project(file_path = file.path(tempdir(), "project1"),
             use_renv = FALSE, use_git = FALSE)
#> ✔ Creating /tmp/RtmpYumPDn/project1/.
#> ✔ Setting active project to "/tmp/RtmpYumPDn/project1".
#> ✔ Creating R/.
#> ✔ Writing a sentinel file .here.
#> ☐ Build robust paths within your project via `here::here()`.
#> ℹ Learn more at <https://here.r-lib.org>.
#> ✔ Setting active project to "<no active project>".

init_project(file_path = file.path(tempdir(), "project2"),
             uw_branding = TRUE, use_renv = FALSE, use_git = FALSE)
#> ✔ Creating /tmp/RtmpYumPDn/project2/.
#> ✔ Setting active project to "/tmp/RtmpYumPDn/project2".
#> ✔ Creating R/.
#> ✔ Writing a sentinel file .here.
#> ☐ Build robust paths within your project via `here::here()`.
#> ℹ Learn more at <https://here.r-lib.org>.
#> ✔ Setting active project to "<no active project>".

init_project(file_path = file.path(tempdir(), "project3"),
             extra_folders = c("notebooks"),
             use_renv = FALSE, use_git = FALSE)
#> ✔ Creating /tmp/RtmpYumPDn/project3/.
#> ✔ Setting active project to "/tmp/RtmpYumPDn/project3".
#> ✔ Creating R/.
#> ✔ Writing a sentinel file .here.
#> ☐ Build robust paths within your project via `here::here()`.
#> ℹ Learn more at <https://here.r-lib.org>.
#> ✔ Setting active project to "<no active project>".
# }
```
