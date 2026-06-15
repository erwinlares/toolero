# Create a new Quarto document from a template

Creates a new Quarto document in the specified directory. Optionally
copies a sample dataset and a worked analysis example, wires up custom
CSS and header styling from a directory of assets, and scaffolds a
post-render purl hook for extracting R code.

## Usage

``` r
create_qmd(
  filename = NULL,
  path = ".",
  yaml_data = NULL,
  overwrite = FALSE,
  use_purl = TRUE,
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

- use_purl:

  Logical. If `TRUE` (the default), creates a `_quarto.yml` file with a
  post-render hook and a `purl.R` script inside `R/` that extracts R
  code from the rendered document into a `.R` file. The target document
  is resolved dynamically by scanning the project root for `.qmd` files,
  so the same `purl.R` works regardless of the document name.

- include_examples:

  Logical. If `TRUE` (the default), copies a sample dataset
  (`sample.csv`) into `data-raw/`, a placeholder logo (`logo.png`) into
  `assets/`, and uses a template `.qmd` pre-populated with a worked
  analysis example. The YAML header includes a `params` block
  referencing the sample data. If `FALSE`, creates a blank `.qmd` with
  only the YAML header and no example content, and skips copying the
  sample dataset and logo.

- use_style:

  Logical or character. Controls whether custom CSS and header assets
  are wired into the YAML.

  - `FALSE` (the default): no custom styling. The YAML `format: html:`
    block contains only standard Quarto options.

  - `TRUE`: shorthand for `"assets/"`. Scans `path/assets/` for `.css`
    and `.html` files and adds them to the YAML.

  - A directory path (e.g. `"my-branding/"`): scans the given directory
    for `.css` and `.html` files and adds them to the YAML.

  If the directory contains exactly one `.css` file, it is added as
  `css:` in the YAML. If exactly one `.html` file is found, it is added
  as `include-before-body:`. If multiple `.css` or `.html` files are
  found, the function errors and asks the user to specify which file to
  use via `yaml_data`. If neither is found, a warning is issued.

## Value

Invisibly returns `path`.

## Details

`create_qmd()` performs the following steps:

1.  Validates that `filename` is supplied and `path` exists.

2.  If `include_examples = TRUE`: creates `data-raw/` under `path` and
    copies `sample.csv` there. Creates `assets/` if needed and copies a
    placeholder `logo.png`. Uses the example template for the `.qmd`.

3.  If `include_examples = FALSE`: uses the skeleton template for the
    `.qmd`. No sample data or logo is copied.

4.  If `use_style` is `TRUE` or a directory path: scans the directory
    for `.css` and `.html` files and injects them into the YAML header.

5.  If `yaml_data` is provided, reads the YAML file and substitutes
    values into the document header. This runs after style injection, so
    `yaml_data` can override any auto-generated YAML keys.

6.  If `use_purl = TRUE`, writes `_quarto.yml` with a post-render hook
    and copies `purl.R` into `path/R/`.

7.  The sample dataset bundled with the template is a subset of the
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
# Minimal blank document -- no examples, no styling
create_qmd(path = tempdir(), filename = "analysis.qmd",
           include_examples = FALSE)
#> ✔ Created /tmp/Rtmp2m2YgS/analysis.qmd
#> ✔ Created /tmp/Rtmp2m2YgS/_quarto.yml
#> ✔ Created /tmp/Rtmp2m2YgS/R/purl.R

# Full worked example with sample data and placeholder logo
create_qmd(path = tempdir(), filename = "analysis.qmd",
           overwrite = TRUE)
#> ✔ Created /tmp/Rtmp2m2YgS/data-raw/sample.csv
#> ✔ Created /tmp/Rtmp2m2YgS/assets/logo.png
#> ✔ Created /tmp/Rtmp2m2YgS/analysis.qmd
#> ✔ Created /tmp/Rtmp2m2YgS/_quarto.yml
#> ✔ Created /tmp/Rtmp2m2YgS/R/purl.R

# Blank document wired to UW branding assets (assumes assets/ exists)
create_qmd(path = tempdir(), filename = "report.qmd",
           include_examples = FALSE, use_style = TRUE,
           overwrite = TRUE)
#> ✔ Created /tmp/Rtmp2m2YgS/assets/rci-banner.png
#> Warning: No .css or .html files found in /tmp/Rtmp2m2YgS/assets. Skipping style
#> injection.
#> ✔ Created /tmp/Rtmp2m2YgS/report.qmd
#> ✔ Created /tmp/Rtmp2m2YgS/_quarto.yml
#> ✔ Created /tmp/Rtmp2m2YgS/R/purl.R

# Blank document with custom branding from a different directory
create_qmd(path = tempdir(), filename = "report.qmd",
           include_examples = FALSE, use_style = "my-branding/",
           overwrite = TRUE, use_purl = FALSE)
#> Warning: Style directory my-branding/ does not exist. Skipping style injection. Create
#> the directory and add your .css and/or .html assets, or set `use_style =
#> FALSE`.
#> ✔ Created /tmp/Rtmp2m2YgS/report.qmd

# Pre-populated YAML overrides
yaml_file <- tempfile(fileext = ".yml")
writeLines("author:\n  - name: 'Your Name'", yaml_file)
create_qmd(path = tempdir(), filename = "analysis.qmd",
           yaml_data = yaml_file, overwrite = TRUE)
#> ✔ Created /tmp/Rtmp2m2YgS/data-raw/sample.csv
#> ✔ Created /tmp/Rtmp2m2YgS/assets/logo.png
#> ✔ Created /tmp/Rtmp2m2YgS/analysis.qmd
#> ✔ Created /tmp/Rtmp2m2YgS/_quarto.yml
#> ✔ Created /tmp/Rtmp2m2YgS/R/purl.R
# }
```
