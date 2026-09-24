# Generate a data documentation stub

Writes a Markdown file documenting a single dataset, with the standard
sections a data-management plan asks for – source, date obtained,
license and usage terms, collection method, variables, and known issues
– pre-filled where they can be, and left as placeholders where they
can't.

## Usage

``` r
generate_data_doc(dataset, path = "data", overwrite = FALSE)
```

## Arguments

- dataset:

  A character string. The file name of the dataset this doc describes,
  e.g. `"survey_responses.csv"`. Used to name the output file (the
  extension is replaced with `.md`) and to fill in the doc's title; must
  be supplied, since there is no reasonable default.

- path:

  A character string. Directory in which to write the file. Defaults to
  `"data"`.

- overwrite:

  Logical. If `TRUE`, overwrites an existing doc at the same location.
  Defaults to `FALSE`.

## Value

Invisibly returns the full path to the written file.

## Details

Recall that a research compendium's `data/` and `data-raw/` folders hold
the data itself, but not where it came from or what its columns mean.
`generate_data_doc()` fills that gap the same way
[`generate_citation()`](https://erwinlares.github.io/toolero/reference/generate_citation.md)
fills in for a missing `CITATION.cff`: a skeleton with a few fields
already filled in, ready for you to complete by hand.

## See also

[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md),
[`generate_license()`](https://erwinlares.github.io/toolero/reference/generate_license.md),
[`generate_citation()`](https://erwinlares.github.io/toolero/reference/generate_citation.md)

## Examples

``` r
if (FALSE) { # \dontrun{
generate_data_doc("survey_responses.csv")

generate_data_doc("weather_2024.csv", path = "data-raw")
} # }
```
