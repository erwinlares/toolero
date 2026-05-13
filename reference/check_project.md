# Check a project for toolero conventions

`check_project()` audits a project directory and reports whether it
follows the structure and conventions that
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
creates. It is useful both for projects initialized with
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
and for existing projects that were created independently.

## Usage

``` r
check_project(path = ".", error = TRUE)
```

## Arguments

- path:

  A character string with the path to the project directory. Defaults to
  `"."` (the current working directory).

- error:

  Logical. If `TRUE` (the default), prints a formatted cli report and
  returns the results invisibly. If `FALSE`, returns a tibble with
  columns `check`, `status`, and `message` without printing.

## Value

A tibble with columns `check`, `status`, and `message`. Returned
invisibly when `error = TRUE`, visibly when `error = FALSE`.

## Examples

``` r
# Audit the current working directory
# \donttest{
check_project()
#> 
#> ── Project check ───────────────────────────────────────────────────────────────
#> ✖ No .Rproj file found -- use `usethis::create_project()` to initialize one
#> ✖ No renv.lock found -- use `renv::init()` to get started
#> ✖ No git repository found -- use `usethis::use_git()` to initialize one
#> ! No .gitignore found -- consider adding one to avoid committing unwanted files
#> ! No data-raw/ folder found -- consider adding one for raw input data
#> ! No data/ folder found -- consider adding one for cleaned data
#> ! No docs/ folder found -- consider adding one for documentation
#> ! No R/ or scripts/ folder found -- consider adding one for analysis code
#> ! No README found -- consider adding one to document the project
# }

# Audit a specific project directory
if (FALSE) { # \dontrun{
check_project(path = "path/to/project")
} # }
```
