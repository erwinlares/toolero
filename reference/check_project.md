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

  Character. Path to the project directory. A relative path is read from
  the project root (see the Paths section). Defaults to `"."`, the
  project root, so calling it from a subfolder audits the project.

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

## Stale purled scripts

Every `.qmd` under `path` whose header declares `purl: true` (see
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)'s
`use_purl` argument) gets its own row, comparing it against the `.R`
script `R/purl.R` is expected to have derived from it. In an ordinary
project that script is flat, `reports/analysis.qmd` to `R/analysis.R`.
In a Quarto website or book (`project: type:` in `_quarto.yml`) it
mirrors the document's path, `posts/one/index.qmd` to
`R/posts/one/index.R`. A script found at the other layout's path, which
happens when `R/purl.R` is an older copy, is reported with the path it
was found at and how to refresh the hook. Missing entirely, or older
than the `.qmd` it was purled from, is reported as `"warn"`: the `.qmd`
is the source of truth, so an `R/` script older than the document it
came from means an edit was made and not yet re-rendered, and a
container or cluster job that bakes in the `.R` file would run the old
analysis without any error to say so. Documents never opted into purl
produce no row – nothing to check.

## Paths

A relative path is read from the project root, not from the working
directory. So `save_output(fit, "output/fit.rds", saveRDS)` writes into
the project's own `output/` folder whether you call it from the project
root, from a document under `reports/`, or from a job on an HTCondor
execute node. You never need to wrap a path in
[`here::here()`](https://here.r-lib.org/reference/here.html). Doing so
still works, because
[`here::here()`](https://here.r-lib.org/reference/here.html) returns an
absolute path and absolute paths are used as given.

The project root is found afresh on every call, in this order:

1.  The job's scratch directory, when `_CONDOR_SCRATCH_DIR` names one.
    HTCondor sets that variable itself, inside every job.

2.  The nearest folder above the working directory that carries a
    project marker: the `.here` file
    [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
    writes, an `.Rproj` file, a package `DESCRIPTION`, or a version
    control folder such as `.git`.

3.  The working directory, when neither of the above applies.

Absolute paths (including those starting with `~`, or a drive letter on
Windows) and URLs such as `https://` or `s3://` are used as given. `..`
and `./` are not interpreted, so `"../data/x.csv"` means the folder
above the root; write an absolute path to leave the project. A bare
`"."` means the root itself.

Functions that read are forgiving about older code. A relative path that
does not exist at the project root but does exist relative to the
working directory is read from there, and a message says so. Functions
that write never guess: a relative path is always written under the
root.

A few arguments are deliberately left alone:

- [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
  reads `path`, `config` and `use_rprofile` from the working directory,
  because the project does not exist yet and so has no root.

- Under `Rscript`,
  [`resolve_input_path()`](https://erwinlares.github.io/toolero/reference/resolve_input_path.md)
  reads the command line argument as given. Run `Rscript` from the
  project root or pass an absolute path.

- Arguments passed on through `...` to another function reach it
  untouched.

- Where a default is "beside the input"
  ([`qmd_to_r()`](https://erwinlares.github.io/toolero/reference/qmd_to_r.md)
  and
  [`generate_kb_xml()`](https://erwinlares.github.io/toolero/reference/generate_kb_xml.md)),
  the output follows wherever the input was read from.

Two limits are worth knowing. A project nested inside another project is
not supported: the nearest marker wins, which can surprise you when you
work from the outer one. And on an execute node `~` and `$HOME` cannot
be trusted (`$HOME` can be the submit node's path), so prefer relative
paths in job scripts.

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
#> ✔ Found toolero.Rproj
#> ✖ No renv.lock found -- use `renv::init()` to get started
#> ✔ git repository initialized
#> ✔ Found .gitignore
#> ! No data-raw/ folder found -- consider adding one for raw input data
#> ! No data/ folder found -- consider adding one for cleaned data
#> ✔ Found R/
#> ! No scripts/ folder found -- consider adding one for hand-written scripts
#> ! No output/figures/ folder found -- consider adding one for figures
#> ! No output/tables/ folder found -- consider adding one for tables
#> ! No reports/ folder found -- consider adding one for reports
#> ✔ Found README.md
# }

# Audit a specific project directory
# \donttest{
project_dir <- withr::local_tempdir()
check_project(path = project_dir)
#> Error in check_project(path = project_dir): Directory /tmp/RtmpVdwYt8/file1a893948d8cf does not exist.
# }

# Audit against a custom folder structure
# \donttest{
project_dir <- withr::local_tempdir()
config_path <- file.path(tempdir(), "my-config.yml")
generate_project_config("my-config.yml", path = tempdir())
#> ✔ Created /tmp/RtmpVdwYt8/my-config.yml
#> ℹ Edit /tmp/RtmpVdwYt8/my-config.yml to define your custom folder structure,
#>   then pass it to `init_project()` via `config =
#>   "/tmp/RtmpVdwYt8/my-config.yml"`.
#> ℹ For easy reuse across projects, consider moving this file to /home/runner.
check_project(path = project_dir, config = config_path)
#> Error in check_project(path = project_dir, config = config_path): Directory /tmp/RtmpVdwYt8/file1a8975b02909 does not exist.
# }

# Access results programmatically
# \donttest{
project_dir <- withr::local_tempdir()
out <- check_project(path = project_dir)
#> Error in check_project(path = project_dir): Directory /tmp/RtmpVdwYt8/file1a89669176d3 does not exist.
# }
```
