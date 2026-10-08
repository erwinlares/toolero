# Generate a LICENSE file

Writes a plain-text `LICENSE` file at the project root, using one of a
small set of common license templates with the copyright holder and year
filled in.

## Usage

``` r
generate_license(
  license = "MIT",
  holder = NULL,
  year = format(Sys.Date(), "%Y"),
  path = ".",
  overwrite = FALSE
)
```

## Arguments

- license:

  A character string. One of `"MIT"`, `"CC0"`, or `"GPL-3"`. Only this
  small, common set is supported; write a `LICENSE` file by hand for
  anything else. Defaults to `"MIT"`.

- holder:

  A character string. The copyright holder – a person or an institution.
  Must be supplied explicitly; there is no default, since guessing it
  wrong is worse than asking.

- year:

  A character string. The copyright year. Defaults to the current year.

- path:

  A character string. Directory in which to write the file. A relative
  path is read from the project root (see the Paths section). Defaults
  to `"."`, the project root.

- overwrite:

  Logical. If `TRUE`, overwrites an existing `LICENSE` file at the same
  location. Defaults to `FALSE`.

## Value

Invisibly returns the full path to the written file.

## Details

Note that this is different from how an R package normally carries a
license. A package's `DESCRIPTION` declares
`License: MIT + file LICENSE` and pairs a two-line CRAN stub (`LICENSE`)
with the full text in a separate `LICENSE.md`. The projects
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
scaffolds are research compendia, not packages – there is no
`DESCRIPTION` to reference a license from – so `generate_license()`
instead writes one self-contained file carrying the license text
directly, the way a plain GitHub repository does.

## GPL-3

The GNU General Public License's full text runs to several hundred
lines. Rather than risk an inaccurate transcription of it,
`license = "GPL-3"` writes the license notice the Free Software
Foundation itself recommends attaching to a program, together with a
link to the canonical full text at
<https://www.gnu.org/licenses/gpl-3.0.txt>. `"MIT"` and `"CC0"` are both
short enough to reproduce here in full, and are written that way.

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
[`generate_data_doc()`](https://erwinlares.github.io/toolero/reference/generate_data_doc.md)

## Examples

``` r
if (FALSE) { # \dontrun{
generate_license(license = "MIT", holder = "Jane Researcher")

generate_license(license = "CC0", holder = "Example Lab",
                  path = "~/Documents/my-project")
} # }
```
