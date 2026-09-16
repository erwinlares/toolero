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
  toolero folder set for the folder checks. When `NULL` (the default)
  and the project carries a `_toolero.yml`, that file is used instead –
  there is no need to hand `check_project()` the same config on every
  call. Non-folder hygiene checks always run regardless.

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

README detection is case-insensitive and extension-agnostic: any file
whose stem matches `readme` (in any capitalization) counts, regardless
of extension or the absence of one.
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
uses the same detection when deciding whether it would overwrite an
existing README.

## Where the folder set comes from

Three sources, in order of precedence.

An explicit `config` argument wins. Folders it declares and the project
lacks are reported as `"fail"`: the caller named a file and that file
states what the project should look like.

Failing that, a `_toolero.yml` at the project root is used.
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
writes one recording the structure it actually created, so a folder
listed there and missing from disk means something removed it. That is
also a `"fail"`.

Failing both, the built-in standard set is used – `data-raw/`, `data/`,
`R/`, `scripts/`, `output/figures/`, `output/tables/`, and `reports/`.
Missing folders here are `"warn"`, not `"fail"`: nobody declared
anything, so the standard set is a suggestion rather than a contract.

A `_toolero.yml` that exists but cannot be parsed is reported as a
failing check and the audit continues against the built-in set. A
`config` that cannot be parsed is an error, since the caller asked for
that file specifically.

## The renv checks

Beyond the presence of `renv.lock`, two checks guard the failure mode
that costs the most to discover late: a lockfile that does not describe
the analysis, which produces a container image that builds cleanly and
then cannot run.

A `.renvignore` excluding `.qmd` files is reported, and the advice is to
remove the entry. It stops `renv` from seeing the
[`library()`](https://rdrr.io/r/base/library.html) calls in a project
whose Quarto document is the source of truth. That the document will
eventually be purled to a `.R` file does not make up for it: the
snapshot you containerize from may be taken before the purl, and the
`.qmd` is the file being maintained either way. Versions of
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
before v0.5.0 wrote one; projects created by those versions still carry
it.

A `renv.lock` recording no packages is reported only when the project
also has `.R` or `.qmd` source files. A newly scaffolded project
legitimately has an empty lockfile –
[`renv::scaffold()`](https://rstudio.github.io/renv/reference/scaffold.html)
does no dependency discovery, because there is nothing yet to discover –
so the pairing is what makes the observation worth printing.

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
#> ! No _toolero.yml found -- create one with `generate_project_config("_toolero.yml")` and edit it to match this project
#> ✖ No .Rproj file found -- use `usethis::create_project()` to initialize one
#> ✖ No renv.lock found -- use `renv::init()` to get started
#> ✖ No git repository found -- use `usethis::use_git()` to initialize one
#> ! No .gitignore found -- consider adding one to avoid committing unwanted files
#> ! No data-raw/ folder found -- consider adding one for raw input data
#> ! No data/ folder found -- consider adding one for cleaned data
#> ! No R/ folder found -- consider adding one for the .R script derived from your .qmd
#> ! No scripts/ folder found -- consider adding one for hand-written scripts
#> ! No output/figures/ folder found -- consider adding one for figures
#> ! No output/tables/ folder found -- consider adding one for tables
#> ! No reports/ folder found -- consider adding one for reports
#> ! No README found -- consider adding one to document the project
# }

# Audit a specific project directory
# \donttest{
project_dir <- withr::local_tempdir()
check_project(path = project_dir)
#> Error in check_project(path = project_dir): Directory /tmp/RtmpI0VrBJ/file4e0931d205ac does not exist.
# }

# Audit against a custom folder structure
# \donttest{
project_dir <- withr::local_tempdir()
config_path <- file.path(tempdir(), "my-config.yml")
generate_project_config("my-config.yml", path = tempdir())
#> ✔ Created /tmp/RtmpI0VrBJ/my-config.yml
#> ℹ Edit /tmp/RtmpI0VrBJ/my-config.yml to define your custom folder structure,
#>   then pass it to `init_project()` via `config =
#>   "/tmp/RtmpI0VrBJ/my-config.yml"`.
#> ℹ For easy reuse across projects, consider moving this file to /home/runner.
check_project(path = project_dir, config = config_path)
#> Error in check_project(path = project_dir, config = config_path): Directory /tmp/RtmpI0VrBJ/file4e094c44211f does not exist.
# }

# Access results programmatically
# \donttest{
project_dir <- withr::local_tempdir()
out <- check_project(path = project_dir)
#> Error in check_project(path = project_dir): Directory /tmp/RtmpI0VrBJ/file4e0936c10294 does not exist.
# }
```
