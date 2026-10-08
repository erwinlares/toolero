# Generate a CITATION.cff file

Writes a Citation File Format (`CITATION.cff`) skeleton, optionally
pre-filled with author information from a profile written by
[`generate_profile()`](https://erwinlares.github.io/toolero/reference/generate_profile.md),
so a project's citation metadata doesn't mean retyping the same name,
affiliation, and ORCID a third time.

## Usage

``` r
generate_citation(
  filename = "CITATION.cff",
  path = ".",
  profile = NULL,
  overwrite = FALSE
)
```

## Arguments

- filename:

  Character. Name of the file to write. Defaults to `"CITATION.cff"`,
  the name tools that read this format expect; changing it means those
  tools will not find the file automatically.

- path:

  Character. Directory to write the file into. Defaults to `"."`, the
  project root. A relative path is read from the project root (see the
  Paths section).

- profile:

  Character or `NULL`. Path to a profile file (a relative path is read
  from the project root), typically one written by
  [`generate_profile()`](https://erwinlares.github.io/toolero/reference/generate_profile.md).
  When supplied, every entry in the profile's `author:` block becomes an
  author entry in the generated file. When `NULL` (the default), a
  single generic placeholder author is written instead.

- overwrite:

  Logical. When `FALSE` (default), an existing file at the destination
  is an error rather than being replaced.

## Value

The path to the written file, invisibly.

## Details

`title`, `version`, `repository-code`, `url`, and `license` are project
facts a personal profile has no way to know, so they are left as
placeholders (some commented out) regardless of `profile`.
`date-released` is filled in with today's date, since that much is
always knowable at generation time; edit it later if the actual release
date differs.

The given-names/family-names split needed by the Citation File Format is
done by splitting a profile's single `name` field on its last space,
which is right for the ordinary case and wrong for some real names.
Review the generated file's `given-names`/`family-names` fields before
relying on them, especially for a multi-word family name.

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

[`generate_profile()`](https://erwinlares.github.io/toolero/reference/generate_profile.md),
the function that writes the file this one can read from.

## Examples

``` r
# \donttest{
generate_citation(path = tempdir())
#> ✔ Wrote /tmp/Rtmp6kXUCf/CITATION.cff.
#> ℹ Wrote a placeholder author -- edit /tmp/Rtmp6kXUCf/CITATION.cff directly, or
#>   supply `profile`.
#> ℹ Fill in title and, when they're true of this project, the commented-out
#>   fields.

profile_file <- tempfile(fileext = ".yml")
writeLines(
  paste(
    'author:',
    '  - name: "Erwin Lares"',
    '    affiliation: "RCI, UW-Madison"',
    '    orcid: "0000-0002-3284-828X"',
    sep = "\n"
  ),
  profile_file
)
generate_citation(path = tempdir(), profile = profile_file, overwrite = TRUE)
#> ✔ Wrote /tmp/Rtmp6kXUCf/CITATION.cff.
#> ℹ Author information came from /tmp/Rtmp6kXUCf/file19e74166a1.yml --
#>   double-check the given-names/family-names split.
#> ℹ Fill in title and, when they're true of this project, the commented-out
#>   fields.
# }
```
