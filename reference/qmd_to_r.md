# Extract R code from a Quarto document

`qmd_to_r()` extracts R code chunks from a `.qmd` file and writes them
to a standalone `.R` script using
[`knitr::purl()`](https://rdrr.io/pkg/knitr/man/knit.html). It works on
any `.qmd` file regardless of whether it was created with
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md).

## Usage

``` r
qmd_to_r(input, output = NULL, documentation = 1L, quiet = TRUE)
```

## Arguments

- input:

  A character string with the path to the `.qmd` file. A relative path
  is read from the project root (see the Paths section).

- output:

  A character string with the path to the output `.R` file; a relative
  path is written under the project root. If `NULL` (the default), the
  output file is written to the same directory as `input` with the
  `.qmd` extension replaced by `.R`.

- documentation:

  An integer controlling how much documentation is included in the
  extracted script. Passed to
  [`knitr::purl()`](https://rdrr.io/pkg/knitr/man/knit.html): `0` strips
  all documentation; `1` (the default) includes chunk labels as
  comments; `2` includes full roxygen blocks.

- quiet:

  Logical. If `TRUE` (the default), suppresses knitr's own output.
  toolero provides its own cli feedback instead.

## Value

Invisibly returns the path to the output `.R` file.

## Details

The parent directory of `output` is created if it does not already
exist, and the creation is reported.
[`knitr::purl()`](https://rdrr.io/pkg/knitr/man/knit.html) does not do
this itself, so writing a derived script into `R/` from a project that
was not created by
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
would otherwise fail.

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

- Where a default is "beside the input" (`qmd_to_r()` and
  [`generate_kb_xml()`](https://erwinlares.github.io/toolero/reference/generate_kb_xml.md)),
  the output follows wherever the input was read from.

Two limits are worth knowing. A project nested inside another project is
not supported: the nearest marker wins, which can surprise you when you
work from the outer one. And on an execute node `~` and `$HOME` cannot
be trusted (`$HOME` can be the submit node's path), so prefer relative
paths in job scripts.

## Examples

``` r
# \donttest{
# Extract R code from a qmd file
qmd <- tempfile(fileext = ".qmd")
writeLines(c(
  "---",
  "title: Analysis",
  "---",
  "",
  "```{r}",
  "x <- 1 + 1",
  "```"
), qmd)

# Default output path: same directory, .R extension
qmd_to_r(input = qmd)
#> ✔ Extracted R code from /tmp/RtmpVdwYt8/file1a89362c0ac6.qmd to /tmp/RtmpVdwYt8/file1a89362c0ac6.R.

# Explicit output path. R/ is where toolero expects derived scripts;
# the directory is created if it does not exist yet.
out <- tempfile(fileext = ".R")
qmd_to_r(input = qmd, output = out)
#> ✔ Extracted R code from /tmp/RtmpVdwYt8/file1a89362c0ac6.qmd to /tmp/RtmpVdwYt8/file1a891b580c5f.R.

# Strip all documentation
qmd_to_r(input = qmd, output = out, documentation = 0L)
#> ✔ Extracted R code from /tmp/RtmpVdwYt8/file1a89362c0ac6.qmd to /tmp/RtmpVdwYt8/file1a891b580c5f.R.
# }
```
