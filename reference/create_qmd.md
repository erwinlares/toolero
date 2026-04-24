# Create a new Quarto document from a template

Creates a new Quarto document in the specified directory, along with a
sample dataset and UW-Madison branded assets. Optionally pre-populates
the YAML header with user-supplied metadata.

## Usage

``` r
create_qmd(
  path = NULL,
  filename = NULL,
  yaml_data = NULL,
  overwrite = FALSE,
  use_purl = TRUE
)
```

## Arguments

- path:

  A string or `NULL`. Path to the directory where the document will be
  created. If `NULL`, the user must supply a path explicitly.

- filename:

  A string or `NULL`. Name of the generated `.qmd` file. Must be
  supplied explicitly, e.g. `"analysis.qmd"`.

- yaml_data:

  A string or `NULL`. Path to a YAML file containing metadata to
  pre-populate the document header. If `NULL` (the default), the
  template is copied as-is with placeholder prompts intact.

- overwrite:

  A logical. Whether to overwrite existing files. Defaults to `FALSE`.

- use_purl:

  Logical. If `TRUE` (the default), creates a `_quarto.yml` file with a
  post-render hook and a `purl.R` script that extracts R code from the
  rendered document into a `.R` file. The target document is resolved
  dynamically from `QUARTO_DOCUMENT_PATH`, so the same `purl.R` works
  regardless of the document name.

## Value

Invisibly returns `path`.

## Details

`create_qmd()` performs the following steps:

1.  Validates that `path` exists.

2.  Validates that `filename` is supplied.

3.  Creates a `data/` folder under `path` and copies `sample.csv` there.

4.  Checks for `assets/styles.css` and `assets/header.html` - creates
    the `assets/` folder if needed and copies both from the package.

5.  Copies the template `.qmd` to `path/filename`.

6.  If `yaml_data` is provided, reads the YAML file and substitutes
    values into the document header.

7.  If `use_purl = TRUE`, writes a `_quarto.yml` with a post-render hook
    and copies `purl.R` from the package templates into `path`.

Note: `path` and `filename` have no default values. Always supply both
explicitly to avoid writing files to unexpected locations. Use
[`tempdir()`](https://rdrr.io/r/base/tempfile.html) for temporary output
during testing or exploration.

## Examples

``` r
# \donttest{
# Create a document in a temp directory
create_qmd(path = tempdir(), filename = "analysis.qmd")
#> ✔ Created /tmp/RtmpS8Xp4P/data/sample.csv
#> ✔ Created /tmp/RtmpS8Xp4P/assets/styles.css
#> ✔ Created /tmp/RtmpS8Xp4P/assets/header.html
#> ✔ Created /tmp/RtmpS8Xp4P/analysis.qmd
#> ✔ Created /tmp/RtmpS8Xp4P/_quarto.yml
#> ✔ Created /tmp/RtmpS8Xp4P/purl.R

# Create with a custom filename, without the purl hook
create_qmd(path = tempdir(), filename = "report.qmd",
            overwrite = TRUE, use_purl = FALSE)
#> ✔ Created /tmp/RtmpS8Xp4P/data/sample.csv
#> ✔ Created /tmp/RtmpS8Xp4P/assets/styles.css
#> ✔ Created /tmp/RtmpS8Xp4P/assets/header.html
#> ✔ Created /tmp/RtmpS8Xp4P/report.qmd

# Create with pre-populated YAML
yaml_file <- tempfile(fileext = ".yml")
writeLines("author:\n  - name: 'Your Name'", yaml_file)
create_qmd(path = tempdir(), filename = "analysis.qmd",
            yaml_data = yaml_file, overwrite = TRUE)
#> ✔ Created /tmp/RtmpS8Xp4P/data/sample.csv
#> ✔ Created /tmp/RtmpS8Xp4P/assets/styles.css
#> ✔ Created /tmp/RtmpS8Xp4P/assets/header.html
#> ✔ Created /tmp/RtmpS8Xp4P/analysis.qmd
#> ✔ Created /tmp/RtmpS8Xp4P/_quarto.yml
#> ✔ Created /tmp/RtmpS8Xp4P/purl.R
# }
```
