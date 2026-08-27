# Check a project for toolero conventions

`check_project()` audits a project directory and reports whether it
follows the structure and conventions that
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
creates. It is useful both for projects initialized with
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
and for existing projects that were created independently.

## Usage

``` r
check_project(path = ".", config = NULL, error = TRUE)
```

## Arguments

- path:

  Character. Path to the project directory. Defaults to `"."` (the
  current working directory).

- config:

  Character or `NULL`. Path to a YAML configuration file produced by
  [`generate_project_config()`](https://erwinlares.github.io/toolero/reference/generate_project_config.md).
  When supplied, the `folders:` list in the file replaces the standard
  toolero folder set for the folder checks. Non-folder hygiene checks
  (`.Rproj`, `renv.lock`, git, `.gitignore`, README, `.RData`,
  `.Rhistory`, `.Rprofile`, `.Renviron`) always run regardless of the
  config. Defaults to `NULL` (standard toolero folders).

- error:

  **\[deprecated\]** Logical. Previously controlled whether the function
  printed a cli report (`TRUE`) or returned a tibble visibly without
  printing (`FALSE`). Deprecated in v0.5.0 – the cli report now always
  prints and the tibble is always returned invisibly. Assign the result
  to access it programmatically: `out <- check_project()`.

## Value

A tibble with columns `check`, `status`, and `message`, returned
invisibly. Assign the result to use it programmatically.

## Details

Each check records one of four status values: `"pass"` (the expected
artifact was found), `"fail"` (a required artifact is missing), `"warn"`
(a recommended artifact is missing or a problematic file was found), or
`"info"` (a file was found that warrants attention but is not
necessarily a problem).

When `config` is `NULL`, folder checks use the standard toolero set:
`data-raw/`, `data/`, `scripts/`, `output/figures/`, `output/tables/`,
and `reports/`. Missing standard folders are reported as `"warn"`.

When `config` is supplied, folder checks use the `folders:` list from
the YAML file instead. Missing config-declared folders are reported as
`"fail"` rather than `"warn"`, since the user explicitly declared the
expected structure.

README detection is case-insensitive and extension-agnostic: any file
whose stem matches `readme` (in any capitalization) counts, regardless
of extension or the absence of one.

## See also

[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md),
[`generate_project_config()`](https://erwinlares.github.io/toolero/reference/generate_project_config.md)

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
#> ! No scripts/ folder found -- consider adding one for analysis scripts
#> ! No output/figures/ folder found -- consider adding one for figures
#> ! No output/tables/ folder found -- consider adding one for tables
#> ! No reports/ folder found -- consider adding one for reports
#> ! No README found -- consider adding one to document the project
# }

# Audit a specific project directory
# \donttest{
project_dir <- withr::local_tempdir()
check_project(path = project_dir)
#> Error in check_project(path = project_dir): Directory /tmp/RtmpBGe5Yq/file4fba614d90bc does not exist.
# }

# Audit against a custom folder structure
# \donttest{
project_dir <- withr::local_tempdir()
config_path <- file.path(tempdir(), "my-config.yml")
generate_project_config("my-config.yml", path = tempdir())
#> ✔ Created /tmp/RtmpBGe5Yq/my-config.yml
#> ℹ Edit /tmp/RtmpBGe5Yq/my-config.yml to define your custom folder structure,
#>   then pass it to `init_project()` via `config =
#>   "/tmp/RtmpBGe5Yq/my-config.yml"`.
#> ℹ For easy reuse across projects, consider moving this file to /home/runner.
check_project(path = project_dir, config = config_path)
#> Error in check_project(path = project_dir, config = config_path): Directory /tmp/RtmpBGe5Yq/file4fba79f6ac8f does not exist.
# }

# Access results programmatically
# \donttest{
project_dir <- withr::local_tempdir()
out <- check_project(path = project_dir)
#> Error in check_project(path = project_dir): Directory /tmp/RtmpBGe5Yq/file4fba1e569511 does not exist.
# }
```
