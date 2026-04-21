# Create a new Quarto document from a template

Creates a new Quarto document in the specified directory, along with a
sample dataset and UW-Madison branded assets. Optionally pre-populates
the YAML header with user-supplied metadata.

## Usage

``` r
create_qmd(
  path = NULL,
  filename = "analysis.qmd",
  yaml_data = NULL,
  overwrite = FALSE
)
```

## Arguments

- path:

  A string or `NULL`. Path to the directory where the document will be
  created. If `NULL`, the user must supply a path explicitly.

- filename:

  A string. Name of the generated `.qmd` file. Defaults to
  `"analysis.qmd"`.

- yaml_data:

  A string or `NULL`. Path to a YAML file containing metadata to
  pre-populate the document header. If `NULL` (the default), the
  template is copied as-is with placeholder prompts intact.

- overwrite:

  A logical. Whether to overwrite existing files. Defaults to `FALSE`.

## Value

Invisibly returns `path`.

## Details

`create_qmd()` performs the following steps:

1.  Validates that `path` exists.

2.  Creates a `data/` folder under `path` and copies `sample.csv` there.

3.  Checks for `assets/styles.css` and `assets/header.html` - creates
    the `assets/` folder if needed and copies both from the package.

4.  Copies the template `.qmd` to `path/filename`.

5.  If `yaml_data` is provided, reads the YAML file and substitutes
    values into the document header.

Note: `path` has no default value. Always supply an explicit path to
avoid writing files to unexpected locations. Use
[`tempdir()`](https://rdrr.io/r/base/tempfile.html) for temporary output
during testing or exploration.

## Examples

``` r
# \donttest{
# Create with placeholder YAML in a temp directory
create_qmd(path = tempdir())
#> ✔ Created /tmp/RtmpD2mH2m/data/sample.csv
#> ✔ Created /tmp/RtmpD2mH2m/assets/styles.css
#> ✔ Created /tmp/RtmpD2mH2m/assets/header.html
#> ✔ Created /tmp/RtmpD2mH2m/analysis.qmd

# Create with a custom filename
create_qmd(path = tempdir(), filename = "report.qmd", overwrite = TRUE)
#> ✔ Created /tmp/RtmpD2mH2m/data/sample.csv
#> ✔ Created /tmp/RtmpD2mH2m/assets/styles.css
#> ✔ Created /tmp/RtmpD2mH2m/assets/header.html
#> ✔ Created /tmp/RtmpD2mH2m/report.qmd

# Create with pre-populated YAML
yaml_file <- tempfile(fileext = ".yml")
writeLines("author:\n  - name: 'Your Name'", yaml_file)
create_qmd(path = tempdir(), yaml_data = yaml_file, overwrite = TRUE)
#> ✔ Created /tmp/RtmpD2mH2m/data/sample.csv
#> ✔ Created /tmp/RtmpD2mH2m/assets/styles.css
#> ✔ Created /tmp/RtmpD2mH2m/assets/header.html
#> ✔ Created /tmp/RtmpD2mH2m/analysis.qmd
# }
```
