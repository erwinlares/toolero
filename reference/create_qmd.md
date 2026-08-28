# Create a new Quarto document from a template

Creates a new Quarto document in the specified directory. Optionally
copies a sample dataset and a worked analysis example, wires up custom
branding assets from a directory of standardized files, and scaffolds a
post-render purl hook for extracting R code.

## Usage

``` r
create_qmd(
  filename = NULL,
  path = ".",
  yaml_data = NULL,
  overwrite = FALSE,
  use_purl = FALSE,
  include_examples = TRUE,
  use_style = FALSE
)
```

## Arguments

- filename:

  A string or `NULL`. Name of the generated `.qmd` file. Must be
  supplied explicitly, e.g. `"analysis.qmd"`.

- path:

  A string. Path to the directory where the document will be created.
  Defaults to `"."` (the current working directory).

- yaml_data:

  A string or `NULL`. Path to a YAML file containing metadata to
  pre-populate the document header. If `NULL` (the default), the
  template is copied as-is with placeholder prompts intact.

- overwrite:

  A logical. Whether to overwrite existing files. Defaults to `FALSE`.
  Note two exceptions: `assets/logo.png` is never overwritten, since an
  existing logo is assumed to be deliberate branding rather than a stale
  copy of the placeholder; and `_quarto.yml` is never governed by
  `overwrite` at all – when it is touched, it is merged rather than
  replaced, and in some cases (see `use_purl` below) it is left
  untouched entirely regardless of `overwrite`, on purpose.

- use_purl:

  Logical. Defaults to `FALSE`. When `TRUE`:

  - Stamps the document's own YAML header with `purl: true`.

  - Ensures `R/purl.R` exists in `path` (subject to `overwrite`, like
    any other scaffolded file).

  - Ensures `path/_quarto.yml` has a `project: post-render:` entry
    pointing at `R/purl.R` – *unless* `_quarto.yml` already exists and
    declares `project: type:` as `website`, `book`, or `manuscript`, in
    which case the hook is deliberately **not** wired automatically. A
    `cli_warn()` explains why and shows the `project:` snippet needed to
    add it by hand. This guard exists because `R/purl.R` purls each
    document to a path mirroring its source location under `R/` – safe
    within a single project, but the interesting failure mode it's
    protecting against is deciding *whether* to opt a multi-document
    project in at all, since a website or book renders many documents on
    every full build and the person scaffolding one `.qmd` may not be
    thinking about the other twenty. If `_quarto.yml` does not yet exist
    at all, the package template is copied in as usual (nothing to guard
    against yet – a fresh `_quarto.yml` with no `type:` is not a multi-
    document project). Outside the guarded types, an existing
    `_quarto.yml` gets the hook merged into its existing `project:`
    block rather than overwritten, so `type`, `website`, and any other
    project options are left untouched. This merge (when it happens) is
    unaffected by `overwrite`, since appending one line to `post-render`
    is non-destructive.

  When `use_purl = FALSE`, the document's header is still stamped, with
  `purl: false`, so `R/purl.R` (in a project where some other document
  has `use_purl = TRUE`) can positively confirm this document should be
  skipped rather than merely lacking an opinion.

  `R/purl.R` itself only purls documents whose own header carries
  `purl: true`, so turning this on for one document inside a larger
  project – a Quarto website, a book – does not cause every other `.qmd`
  in that project to be purled whenever the project renders in full.
  Output paths under `R/` mirror each source document's path relative to
  the project root, so two documents that happen to share a filename in
  different directories (e.g. a directory-per-post convention using
  `index.qmd`) do not overwrite each other's output.

- include_examples:

  Logical. If `TRUE` (the default), copies a sample dataset
  (`sample.csv`) into `data-raw/`, a placeholder logo
  (`generic-logo.png`, copied as `logo.png`) into `assets/`, and uses a
  template `.qmd` pre-populated with a worked analysis example. If
  `assets/logo.png` already exists (e.g. from a prior
  [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
  call with `branding` set), it is always left untouched – an existing
  logo takes precedence over the generic placeholder even when
  `overwrite = TRUE`. The YAML header includes a `params` block
  referencing the sample data. If `FALSE`, creates a blank `.qmd` with
  only the YAML header and no example content, and skips copying the
  sample dataset and logo.

- use_style:

  Logical or character. Controls whether custom branding assets are
  wired into the YAML.

  - `FALSE` (the default): no custom styling. The YAML `format: html:`
    block contains only standard Quarto options.

  - `TRUE`: shorthand for `"assets/"`. Looks in `path/assets/` for
    `styles.css`, `header.html`, and `footer.html` by name, and wires up
    whichever of these are present.

  - A directory path (e.g. `"my-branding/"`): looks in the given
    directory for the same three standardized filenames. The caller is
    responsible for ensuring the directory contains the files it needs
    under these exact names; `create_qmd()` does not rename or infer
    from other file names.

  `styles.css` is added as `css:`, `header.html` as
  `include-before-body:`, and `footer.html` as `include-after-body:`.
  Any subset may be present; only files that exist are wired into the
  YAML. If none of the three are found, a warning is issued and style
  injection is skipped. Note that `favicon.png`, though shipped with the
  branding asset set, is not wired into the document YAML – favicons are
  a Quarto website-project option rather than an HTML format option, so
  set it in `_quarto.yml` if you need one.

## Value

Invisibly returns `path`.

## Details

`create_qmd()` performs the following steps:

1.  Validates that `filename` is supplied and `path` exists.

2.  If `include_examples = TRUE`: creates `data-raw/` under `path` and
    copies `sample.csv` there. Creates `assets/` if needed and copies
    the generic placeholder logo as `logo.png`, unless a logo already
    exists there. Uses the example template for the `.qmd`.

3.  If `include_examples = FALSE`: uses the skeleton template for the
    `.qmd`. No sample data or logo is copied.

4.  If `use_style` is `TRUE` or a directory path: looks for
    `styles.css`, `header.html`, and `footer.html` by name and injects
    whichever are present into the YAML header.

5.  Stamps `purl: true` or `purl: false` into the document's own YAML
    header, reflecting `use_purl`.

6.  If `yaml_data` is provided, reads the YAML file and substitutes
    values into the document header. This runs after style injection and
    the purl stamp, so `yaml_data` can override any auto-generated YAML
    key, including `purl` itself.

7.  If `use_purl = TRUE`, ensures `R/purl.R` exists. Then, unless
    `_quarto.yml` already exists and declares `project: type:` as
    `website`, `book`, or `manuscript` (in which case wiring is skipped
    with a warning explaining why), ensures `_quarto.yml` has the
    post-render hook – creating `_quarto.yml` from the package template
    if absent, or merging the hook into the existing file's `project:`
    block if present.

8.  The sample dataset bundled with the template is a subset of the
    Palmer Penguins dataset. Citation: Horst AM, Hill AP, Gorman KB
    (2020). palmerpenguins: Palmer Archipelago (Antarctica) Penguin
    Data. R package version 0.1.0.
    [doi:10.5281/zenodo.3960218](https://doi.org/10.5281/zenodo.3960218)

Note: `filename` has no default value and must always be supplied
explicitly. Use [`tempdir()`](https://rdrr.io/r/base/tempfile.html) for
temporary output during testing or exploration.

## Examples

``` r
# \donttest{
# Minimal blank document -- no examples, no styling, no purl
create_qmd(path = tempdir(), filename = "analysis.qmd",
           include_examples = FALSE)
#> ✔ Created /tmp/Rtmpzi3IQZ/analysis.qmd

# Full worked example with sample data and placeholder logo
create_qmd(path = tempdir(), filename = "analysis.qmd",
           overwrite = TRUE)
#> ✔ Created /tmp/Rtmpzi3IQZ/data-raw/sample.csv
#> ✔ Created /tmp/Rtmpzi3IQZ/assets/logo.png
#> ✔ Created /tmp/Rtmpzi3IQZ/analysis.qmd

# Opt this document into purl: stamps purl: true and wires up
# R/purl.R + the _quarto.yml post-render hook (merged if the file
# already exists, e.g. inside a larger Quarto website project)
create_qmd(path = tempdir(), filename = "analysis.qmd",
           overwrite = TRUE, use_purl = TRUE)
#> ✔ Created /tmp/Rtmpzi3IQZ/data-raw/sample.csv
#> ℹ Skipping /tmp/Rtmpzi3IQZ/assets/logo.png -- existing logo left in place.
#> ✔ Created /tmp/Rtmpzi3IQZ/analysis.qmd
#> ✔ Created /tmp/Rtmpzi3IQZ/R/purl.R
#> ✔ Created /tmp/Rtmpzi3IQZ/_quarto.yml

# Blank document wired to branding assets (assumes assets/ exists,
# e.g. from init_project(branding = "uw-madison"))
create_qmd(path = tempdir(), filename = "report.qmd",
           include_examples = FALSE, use_style = TRUE,
           overwrite = TRUE)
#> Warning: No styles.css, header.html, or footer.html found in /tmp/Rtmpzi3IQZ/assets.
#> Skipping style injection.
#> ✔ Created /tmp/Rtmpzi3IQZ/report.qmd

# Blank document with custom branding from a different directory
create_qmd(path = tempdir(), filename = "report.qmd",
           include_examples = FALSE, use_style = "my-branding/",
           overwrite = TRUE)
#> Warning: Style directory /home/runner/work/toolero/toolero/docs/reference/my-branding
#> does not exist. Skipping style injection. Create the directory and add your
#> branding assets, or set `use_style = FALSE`.
#> ✔ Created /tmp/Rtmpzi3IQZ/report.qmd

# Pre-populated YAML overrides
yaml_file <- tempfile(fileext = ".yml")
writeLines("author:\n  - name: 'Your Name'", yaml_file)
create_qmd(path = tempdir(), filename = "analysis.qmd",
           yaml_data = yaml_file, overwrite = TRUE)
#> ✔ Created /tmp/Rtmpzi3IQZ/data-raw/sample.csv
#> ℹ Skipping /tmp/Rtmpzi3IQZ/assets/logo.png -- existing logo left in place.
#> ✔ Created /tmp/Rtmpzi3IQZ/analysis.qmd
# }
```
