# Generate a project configuration file

Writes a YAML configuration file pre-filled with the standard toolero
folder structure and naming conventions. Edit the file to define a
custom project layout, then pass its path to
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
via the `config` argument.

## Usage

``` r
generate_project_config(filename, path = ".", overwrite = FALSE)
```

## Arguments

- filename:

  A character string. Name of the YAML file to create (e.g.,
  `"linguistics-project.yml"`). Must be supplied explicitly.

- path:

  A character string. Directory in which to write the file. A relative
  path is read from the project root (see the Paths section). Defaults
  to `"."`, the project root. Consider using `"~"` (your home directory)
  so the file is easy to reference in future
  [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
  calls regardless of which project is active.

- overwrite:

  Logical. If `TRUE`, overwrites an existing file at the same location.
  Defaults to `FALSE`.

## Value

Invisibly returns the full path to the written file.

## Details

The file uses the same schema as the `_toolero.yml` that
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
writes into a project, so a config you author by hand and the project
config a project carries are the same kind of document. The only
difference is who wrote it.

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
[`check_project()`](https://erwinlares.github.io/toolero/reference/check_project.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Write to the current working directory
generate_project_config("my-project.yml")

# Write to home directory for easy reuse across projects
generate_project_config("linguistics-project.yml", path = "~")

# Overwrite an existing config
generate_project_config("my-project.yml", overwrite = TRUE)
} # }
```
