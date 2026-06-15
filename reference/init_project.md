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
  custom_folders = NULL,
  config = NULL,
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

- custom_folders:

  A character vector of folder names to add to or remove from the
  project structure after the base set is resolved. Bare names (e.g.,
  `"models"`) add a folder. Names prefixed with `"-"` (e.g.,
  `"-output/figures"`) suppress creation of that folder. When removing,
  only the named leaf is suppressed – parent directories are unaffected.
  Duplicates of existing folders generate a message and are skipped.
  References to non-existent folders via `"-"` generate a warning.
  Defaults to `NULL`.

- config:

  A character string. Path to a YAML project config file produced by
  [`generate_project_config()`](https://erwinlares.github.io/toolero/reference/generate_project_config.md).
  When supplied, the folder list in the config replaces the built-in
  standard structure entirely. `custom_folders` is still applied on top
  of the config-derived set. Defaults to `NULL`.

- open:

  Logical. If `TRUE`, opens the new project in RStudio after creation.
  Defaults to `FALSE`.

- uw_branding:

  Logical. If `TRUE`, creates an `assets/` folder and populates it with
  UW-Madison RCI branding files (`styles.css`, `header.html`,
  `rci-banner.png`). Defaults to `FALSE`.

## Value

Called for its side effects. Invisibly returns `path`.

## Examples

``` r
if (FALSE) { # \dontrun{
init_project(path = file.path(tempdir(), "project1"),
             use_renv = FALSE, use_git = FALSE)

init_project(path = file.path(tempdir(), "project2"),
             uw_branding = TRUE, use_renv = FALSE, use_git = FALSE)

# Add a folder and suppress one from the standard set
init_project(path = file.path(tempdir(), "project3"),
             custom_folders = c("models", "-output/figures"),
             use_renv = FALSE, use_git = FALSE)

# Drive structure entirely from a config file
init_project(path = file.path(tempdir(), "project4"),
             config = "~/linguistics-project.yml",
             use_renv = FALSE, use_git = FALSE)
} # }
```
