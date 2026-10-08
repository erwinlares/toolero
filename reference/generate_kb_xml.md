# Generate a KB-importable XML file from a Quarto document

Takes a Quarto document and produces an XML file that is directly
importable into a UW-Madison Knowledge Base (KB) article. The function
re-renders the `.qmd` with `embed-resources: true` so all visual assets
are self-contained, extracts the HTML body, and wraps it in the KB XML
structure along with metadata drawn from the document's YAML header.

## Usage

``` r
generate_kb_xml(html_path, qmd_path = NULL, output_dir = NULL)
```

## Arguments

- html_path:

  A string. Path to the rendered HTML file; a relative path is read from
  the project root. Used to infer the output filename and, if `qmd_path`
  is `NULL`, the location of the source `.qmd`.

- qmd_path:

  A string or `NULL`. Path to the source `.qmd` file (a relative path is
  read from the project root). If `NULL` (the default), inferred by
  replacing the `.html` extension of `html_path` with `.qmd`.

- output_dir:

  A string or `NULL`. Directory where the `.xml` file will be written; a
  relative path is read from the project root. If `NULL` (the default),
  written to the same directory as `html_path`.

## Value

Invisibly returns the path to the written `.xml` file.

## Details

`generate_kb_xml()` performs the following steps:

1.  Validates that `html_path` exists.

2.  Infers `qmd_path` from `html_path` if not supplied, then validates
    it.

3.  Extracts `title`, `description`, and `categories` from the `.qmd`
    YAML header and maps them to `kb_title`, `kb_summary`, and
    `kb_keywords`.

4.  Re-renders the `.qmd` in an isolated temporary directory with
    `embed-resources: true` so all CSS, images, and JS are
    self-contained. The `data/` and `assets/` folders are copied
    alongside the `.qmd` to ensure the render succeeds.

5.  Extracts the `<body>` from the embedded HTML.

6.  Escapes HTML entities in the body for XML compatibility, as required
    by the UW-Madison KB import format.

7.  Builds the XML structure with `kb_title`, `kb_keywords`,
    `kb_summary`, and `kb_body` nodes.

8.  Writes the `.xml` file to `output_dir`.

Temporary files are managed via
[`withr::local_tempdir()`](https://withr.r-lib.org/reference/with_tempfile.html)
and are automatically cleaned up when the function exits, even on error.

When importing the resulting XML into the KB, check the *Decode HTML
entity in body content* option.

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
  and `generate_kb_xml()`), the output follows wherever the input was
  read from.

Two limits are worth knowing. A project nested inside another project is
not supported: the nearest marker wins, which can surprise you when you
work from the outer one. And on an execute node `~` and `$HOME` cannot
be trusted (`$HOME` can be the submit node's path), so prefer relative
paths in job scripts.

## Examples

``` r
# \donttest{
# Infer qmd_path automatically, write XML alongside the HTML
# generate_kb_xml(html_path = "docs/analysis.html")

# Supply qmd_path explicitly and write to a specific output directory
# generate_kb_xml(
#   html_path  = "docs/analysis.html",
#   qmd_path   = "analysis.qmd",
#   output_dir = "exports"
# )
# }
```
