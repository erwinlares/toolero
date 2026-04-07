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
  open = TRUE
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

## Value

Called for its side effects. Does not return a value.

## Examples

``` r
if (FALSE) { # \dontrun{
# Create a project with the standard folder structure
init_project("~/Documents/my-project")

# Create a project with an additional folder
init_project("~/Documents/my-project", extra_folders = c("notebooks", "presentations"))

# Create a project without renv or git
init_project("~/Documents/my-project", use_renv = FALSE, use_git = FALSE)
} # }
```
