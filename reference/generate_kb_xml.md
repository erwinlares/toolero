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

  A string. Path to the rendered HTML file. Used to infer the output
  filename and, if `qmd_path` is `NULL`, the location of the source
  `.qmd`.

- qmd_path:

  A string or `NULL`. Path to the source `.qmd` file. If `NULL` (the
  default), inferred by replacing the `.html` extension of `html_path`
  with `.qmd`.

- output_dir:

  A string or `NULL`. Directory where the `.xml` file will be written.
  If `NULL` (the default), written to the same directory as `html_path`.

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
