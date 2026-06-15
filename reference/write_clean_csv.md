# Write a cleaned data frame to a CSV file

`write_clean_csv()` writes a data frame to a CSV file using
[`readr::write_csv()`](https://readr.tidyverse.org/reference/write_delim.html)
and emits a cli confirmation message reporting the number of rows and
columns written. It is the natural counterpart to
[`read_clean_csv()`](https://erwinlares.github.io/toolero/reference/read_clean_csv.md),
reinforcing the convention that `data-raw/` holds original inputs and
`data/` holds cleaned, analysis-ready outputs.

## Usage

``` r
write_clean_csv(data, path, overwrite = FALSE, ...)
```

## Arguments

- data:

  A data frame or tibble to write.

- path:

  A character string with the path to the output CSV file.

- overwrite:

  Logical. If `FALSE` (the default), errors if the file already exists.
  Set to `TRUE` to overwrite an existing file.

- ...:

  Additional arguments passed to
  [`readr::write_csv()`](https://readr.tidyverse.org/reference/write_delim.html),
  such as `append`, `col_names`, or `quote`.

## Value

Invisibly returns `path`.

## Details

If column names are not already clean, `write_clean_csv()` applies
[`janitor::clean_names()`](https://sfirke.github.io/janitor/reference/clean_names.html)
before writing and emits a warning listing the affected columns.

## Examples

``` r
# \donttest{
sample_path <- system.file("templates", "sample.csv", package = "toolero")
data <- read_clean_csv(sample_path)

# Write to a temp file
out <- tempfile(fileext = ".csv")
write_clean_csv(data, out)
#> ✔ Wrote 344 rows and 8 columns to /tmp/RtmpAGqFVO/file4fed2d0461de.csv.

# Overwrite an existing file
write_clean_csv(data, out, overwrite = TRUE)
#> ✔ Wrote 344 rows and 8 columns to /tmp/RtmpAGqFVO/file4fed2d0461de.csv.

# Dirty names are cleaned automatically with a warning
dirty <- data.frame("First Name" = "Jane", "Last Name" = "Doe",
                    check.names = FALSE)
write_clean_csv(dirty, tempfile(fileext = ".csv"))
#> Warning: Column names were not clean -- applying `janitor::clean_names()` before
#> writing. Affected columns: "First Name" and "Last Name"
#> ✔ Wrote 1 row and 2 columns to /tmp/RtmpAGqFVO/file4fed37bcceec.csv.
# }
```
