# Generate a data documentation stub

Writes a Markdown file documenting a single dataset, with the standard
sections a data-management plan asks for – source, date obtained,
license and usage terms, collection method, variables, and known issues
– pre-filled where they can be, and left as placeholders where they
can't.

## Usage

``` r
generate_data_doc(dataset, path = "data", overwrite = FALSE)
```

## Arguments

- dataset:

  A character string. The file name of the dataset this doc describes,
  e.g. `"survey_responses.csv"`. Used to name the output file (the
  extension is replaced with `.md`) and to fill in the doc's title; must
  be supplied, since there is no reasonable default.

- path:

  A character string. Directory in which to write the file. A relative
  path is read from the project root (see the Paths section). Defaults
  to `"data"`, the project's `data/` folder.

- overwrite:

  Logical. If `TRUE`, overwrites an existing doc at the same location.
  Defaults to `FALSE`.

## Value

Invisibly returns the full path to the written file.

## Details

Recall that a research compendium's `data/` and `data-raw/` folders hold
the data itself, but not where it came from or what its columns mean.
`generate_data_doc()` fills that gap the same way
[`generate_citation()`](https://erwinlares.github.io/toolero/reference/generate_citation.md)
fills in for a missing `CITATION.cff`: a skeleton with a few fields
already filled in, ready for you to complete by hand.

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
[`generate_license()`](https://erwinlares.github.io/toolero/reference/generate_license.md),
[`generate_citation()`](https://erwinlares.github.io/toolero/reference/generate_citation.md)

## Examples

``` r
if (FALSE) { # \dontrun{
generate_data_doc("survey_responses.csv")

generate_data_doc("weather_2024.csv", path = "data-raw")
} # }
```
