# Read and clean a CSV file

`read_clean_csv()` reads a CSV file, standardizes column names,
optionally handles missing values, and optionally prints an ingest
summary. It combines
[`readr::read_csv()`](https://readr.tidyverse.org/reference/read_delim.html),
[`janitor::clean_names()`](https://sfirke.github.io/janitor/reference/clean_names.html),
and
[`tidyr::drop_na()`](https://tidyr.tidyverse.org/reference/drop_na.html)
into a single, reproducibility-friendly step.

## Usage

``` r
read_clean_csv(
  path,
  na = c("", "NA"),
  drop_na = FALSE,
  summary = FALSE,
  verbose = FALSE,
  ...
)
```

## Arguments

- path:

  A character string with the path to the CSV file.

- na:

  A character vector of strings to treat as missing values. Passed
  directly to
  [`readr::read_csv()`](https://readr.tidyverse.org/reference/read_delim.html).
  Defaults to `c("", "NA")`, which matches `readr`'s own default
  behavior.

- drop_na:

  Logical or character vector. If `FALSE` (the default), no rows are
  dropped. If `TRUE`, drops all rows containing any missing value. If a
  character vector of column names, drops only rows with missing values
  in those columns. Always emits a cli message reporting how many rows
  were dropped and how many remain.

- summary:

  Logical. If `TRUE`, prints a brief ingest summary after reading and
  cleaning: row and column counts, number of column names cleaned, and
  missing value totals. Reflects the final state of the tibble after any
  `drop_na` action. Defaults to `FALSE`.

- verbose:

  Logical. If `TRUE`, displays column type messages from
  [`readr::read_csv()`](https://readr.tidyverse.org/reference/read_delim.html).
  Defaults to `FALSE`.

- ...:

  Additional arguments passed to
  [`readr::read_csv()`](https://readr.tidyverse.org/reference/read_delim.html),
  such as `col_types`, `skip`, or `locale`.

## Value

A tibble with cleaned column names.

## Examples

``` r
# \donttest{
sample_path <- system.file("templates", "sample.csv", package = "toolero")

# Basic usage
data <- read_clean_csv(sample_path)

# Explicit missing-value codes
data <- read_clean_csv(sample_path, na = c("", "NA", "N/A", ".", "-999"))

# Drop rows missing in any column
data <- read_clean_csv(sample_path, drop_na = TRUE)
#> Dropped 11 rows with missing values across all columns -- 333 rows remaining.

# Drop rows missing in specific columns
data <- read_clean_csv(sample_path, drop_na = c("bill_length_mm", "sex"))
#> Dropped 11 rows with missing values in columns: "bill_length_mm" and "sex" --
#> 333 rows remaining.

# Print ingest summary
data <- read_clean_csv(sample_path, summary = TRUE)
#> ✔ Read 344 rows and 8 columns.
#> ℹ 0 column names cleaned.
#> ℹ 5 columns contain missing values (19 total missing values).

# Combine arguments
data <- read_clean_csv(
  sample_path,
  na      = c("", "NA", "N/A", "."),
  drop_na = TRUE,
  summary = TRUE
)
#> Dropped 11 rows with missing values across all columns -- 333 rows remaining.
#> ✔ Read 333 rows and 8 columns.
#> ℹ 0 column names cleaned.
#> ℹ 0 columns contain missing values (0 total missing values).
# }
```
