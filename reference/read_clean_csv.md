# Read and clean a CSV file

`read_clean_csv()` reads a CSV file and cleans the column names in one
step. It leverages
[`readr::read_csv()`](https://readr.tidyverse.org/reference/read_delim.html)
for reading and
[`janitor::clean_names()`](https://sfirke.github.io/janitor/reference/clean_names.html)
for making column names tidyverse-friendly (lowercase, no spaces, no
special characters). By default, column type messages are suppressed.
Set `verbose = TRUE` to display them.

## Usage

``` r
read_clean_csv(file_path, verbose = FALSE)
```

## Arguments

- file_path:

  A character string with the path to the CSV file.

- verbose:

  Logical. If `TRUE`, displays column type messages from
  [`readr::read_csv()`](https://readr.tidyverse.org/reference/read_delim.html).
  Defaults to `FALSE`.

## Value

A tibble with clean column names.

## Examples

``` r
# \donttest{
# Read and clean a CSV file silently
sample_path <- system.file("templates", "sample.csv", package = "toolero")
data <- read_clean_csv(sample_path)

# Show column type messages
data <- read_clean_csv(sample_path, verbose = TRUE)
#> Rows: 344 Columns: 8
#> ── Column specification ────────────────────────────────────────────────────────
#> Delimiter: ","
#> chr (3): species, island, sex
#> dbl (5): bill_length_mm, bill_depth_mm, flipper_length_mm, body_mass_g, year
#> 
#> ℹ Use `spec()` to retrieve the full column specification for this data.
#> ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
# }
```
