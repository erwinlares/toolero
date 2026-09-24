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
  header_defaults = NULL,
  overwrite = FALSE,
  use_purl = FALSE,
  include_examples = TRUE,
  use_style = FALSE,
  yaml_data = lifecycle::deprecated()
)
```

## Arguments

- filename:

  A string or `NULL`. Name of the generated `.qmd` file. Must be
  supplied explicitly, e.g. `"analysis.qmd"`.

- path:

  A string. Path to the directory where the document will be created.
  Defaults to `"."` (the current working directory).

- header_defaults:

  A string or `NULL`. Path to a YAML file supplying values to
  pre-populate the document header – typically a profile written by
  [`generate_profile()`](https://erwinlares.github.io/toolero/reference/generate_profile.md),
  but any YAML file following the same shape works. If `NULL` (the
  default), the template is copied as-is with placeholder prompts
  intact. Every key in the file, at any depth, replaces the template's
  key of the same name; keys the file does not mention are left exactly
  as the template wrote them. A key whose value is itself a mapping
  (`format: html: ...`) is descended into and merged key by key, so a
  sibling the file doesn't mention – `css:` from `use_style`, say –
  survives; a key whose value is a sequence (`author:`, `categories:`)
  is replaced as a whole, not merged element by element. Named
  `yaml_data` before v0.5.1.9000; that name still works but is
  deprecated (see below).

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
    any other scaffolded file – an existing `R/purl.R` is left in place
    unless `overwrite = TRUE`).

  - Ensures `path/_quarto.yml` has a `project: post-render:` entry
    pointing at `R/purl.R` – *unless* `_quarto.yml` already exists and
    declares `project: type:` as `website`, `book`, or `manuscript`, in
    which case the hook is deliberately **not** wired automatically. A
    `cli_warn()` explains why, reports whether `R/purl.R` was created or
    was already present, and names the `post-render:` entry to add by
    hand. This guard exists because `R/purl.R` purls each document to a
    path mirroring its source location under `R/` – safe within a single
    project, but the interesting failure mode it's protecting against is
    deciding *whether* to opt a multi-document project in at all, since
    a website or book renders many documents on every full build and the
    person scaffolding one `.qmd` may not be thinking about the other
    twenty. If `_quarto.yml` does not yet exist at all, the package
    template is copied in as usual (nothing to guard against yet – a
    fresh `_quarto.yml` with no `type:` is not a multi- document
    project). Outside the guarded types, an existing `_quarto.yml` gets
    the hook merged into its existing `project:` block rather than
    overwritten, so `type`, `website`, and any other project options are
    left untouched. This merge (when it happens) is unaffected by
    `overwrite`, since appending one line to `post-render` is
    non-destructive.

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
  (`sample.csv`) into `data-raw/` and uses a template `.qmd`
  pre-populated with a worked analysis example. The YAML header includes
  a `params` block referencing the sample data. If `FALSE`, creates a
  blank `.qmd` with only the YAML header and no example content, and
  skips copying the sample dataset.

  A placeholder logo (`generic-logo.png`, copied as `logo.png`) is also
  copied into `assets/`, but only when branding is actually part of the
  project: if `path` carries a `_toolero.yml` (as written by
  [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md))
  whose `folders:` list does not include `assets` (i.e. the project was
  scaffolded with `branding = "none"`), the logo is skipped along with
  it, so a project that declared no branding does not end up with an
  undeclared `assets/logo.png` anyway. A `.qmd` created outside any
  toolero-scaffolded project (no `_toolero.yml` at `path`) always gets
  the logo, since there is no project-level branding decision to defer
  to. If `assets/logo.png` already exists (e.g. from a prior
  [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
  call with `branding` set), it is always left untouched – an existing
  logo takes precedence over the generic placeholder even when
  `overwrite = TRUE`.

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

- yaml_data:

  **\[deprecated\]** A string or `NULL`. Renamed to `header_defaults` in
  v0.5.1.9000 – the argument still works, and its value is used when
  `header_defaults` is not also supplied, but new code should use
  `header_defaults`.

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

6.  If `header_defaults` (or the deprecated `yaml_data`) is provided,
    reads the YAML file and substitutes its values into the document
    header, descending into nested mappings so a sibling key it doesn't
    mention survives. This runs after style injection and the purl
    stamp, so `header_defaults` can override any auto-generated YAML
    key, including `purl` itself.

7.  If `use_purl = TRUE`, ensures `R/purl.R` exists. Then, unless
    `_quarto.yml` already exists and declares `project: type:` as
    `website`, `book`, or `manuscript` (in which case wiring is skipped
    with a warning explaining why), ensures `_quarto.yml` has the
    post-render hook – creating `_quarto.yml` from the package template
    if absent, or merging the hook into the existing file's `project:`
    block if present.

8.  The sample dataset bundled with the template, `data-raw/sample.csv`,
    is a subset of the Palmer Archipelago penguin data, taken from an
    earlier version of the `palmerpenguins` package than the one on CRAN
    today. Treat it as teaching material rather than as a citable copy
    of the data.

    Since R 4.5.0 the same data ships with base R, so
    [`?datasets::penguins`](https://rdrr.io/r/datasets/penguins.html) is
    the most convenient reference, with
    [`datasets::penguins_raw`](https://rdrr.io/r/datasets/penguins.html)
    carrying the uncleaned form. One difference matters when reading the
    two side by side: base R shortened four of the column names, so
    `bill_length_mm`, `bill_depth_mm`, `flipper_length_mm` and
    `body_mass_g` here are `bill_len`, `bill_dep`, `flipper_len` and
    `body_mass` there. `species`, `island`, `sex` and `year` are spelled
    the same in both. This template keeps the longer names, which carry
    their units.

    Original data: Gorman KB, Williams TD, Fraser WR (2014). Ecological
    sexual dimorphism and environmental variability within a community
    of Antarctic penguins (genus Pygoscelis). PLoS ONE 9(3): e90081.
    [doi:10.1371/journal.pone.0090081](https://doi.org/10.1371/journal.pone.0090081)
    . R package: Horst AM, Hill AP, Gorman KB (2020). palmerpenguins:
    Palmer Archipelago (Antarctica) Penguin Data.
    [doi:10.5281/zenodo.3960218](https://doi.org/10.5281/zenodo.3960218)
    . Collected by Palmer Station Antarctica LTER, a member of the Long
    Term Ecological Research Network.

Every edit to the document's YAML header is made line by line rather
than by parsing the header and writing it back out. Keys the edit does
not touch keep the template's own quoting, indentation, comments, and
ordering, so the document a reader opens is the template we shipped plus
the keys they asked for.

Note: `filename` has no default value and must always be supplied
explicitly. Use [`tempdir()`](https://rdrr.io/r/base/tempfile.html) for
temporary output during testing or exploration.

## Examples

``` r
# \donttest{
# Minimal blank document -- no examples, no styling, no purl
create_qmd(path = tempdir(), filename = "analysis.qmd",
           include_examples = FALSE)
#> ✔ Created /tmp/RtmpU20TFH/analysis.qmd

# Full worked example with sample data and placeholder logo
create_qmd(path = tempdir(), filename = "analysis.qmd",
           overwrite = TRUE)
#> ✔ Created /tmp/RtmpU20TFH/data-raw/sample.csv
#> ✔ Created /tmp/RtmpU20TFH/assets/logo.png
#> ✔ Created /tmp/RtmpU20TFH/analysis.qmd

# Opt this document into purl: stamps purl: true and wires up
# R/purl.R + the _quarto.yml post-render hook (merged if the file
# already exists, e.g. inside a larger Quarto website project)
create_qmd(path = tempdir(), filename = "analysis.qmd",
           overwrite = TRUE, use_purl = TRUE)
#> ✔ Created /tmp/RtmpU20TFH/data-raw/sample.csv
#> ℹ Skipping /tmp/RtmpU20TFH/assets/logo.png -- existing logo left in place.
#> ✔ Created /tmp/RtmpU20TFH/analysis.qmd
#> ✔ Created /tmp/RtmpU20TFH/R/purl.R
#> ✔ Created /tmp/RtmpU20TFH/_quarto.yml

# Blank document wired to branding assets (assumes assets/ exists,
# e.g. from init_project(branding = "uw-madison"))
create_qmd(path = tempdir(), filename = "report.qmd",
           include_examples = FALSE, use_style = TRUE,
           overwrite = TRUE)
#> Warning: No styles.css, header.html, or footer.html found in /tmp/RtmpU20TFH/assets.
#> Skipping style injection.
#> ✔ Created /tmp/RtmpU20TFH/report.qmd

# Blank document with custom branding from a different directory
create_qmd(path = tempdir(), filename = "report.qmd",
           include_examples = FALSE, use_style = "my-branding/",
           overwrite = TRUE)
#> Warning: Style directory /home/runner/work/toolero/toolero/docs/reference/my-branding
#> does not exist. Skipping style injection. Create the directory and add your
#> branding assets, or set `use_style = FALSE`.
#> ✔ Created /tmp/RtmpU20TFH/report.qmd

# Pre-populated YAML header, typically from generate_profile()
profile_file <- tempfile(fileext = ".yml")
writeLines("author:\n  - name: 'Your Name'", profile_file)
create_qmd(path = tempdir(), filename = "analysis.qmd",
           header_defaults = profile_file, overwrite = TRUE)
#> ✔ Created /tmp/RtmpU20TFH/data-raw/sample.csv
#> ℹ Skipping /tmp/RtmpU20TFH/assets/logo.png -- existing logo left in place.
#> ✔ Created /tmp/RtmpU20TFH/analysis.qmd
# }
```
