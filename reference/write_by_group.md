# Split a data frame by a grouping column and write each group to a CSV file

Splits a data frame by a single grouping column and writes each group to
a separate CSV file. Optionally writes a manifest file listing the
output files, their group values, and row counts.

## Usage

``` r
write_by_group(data, group_col, output_dir = NULL, manifest = FALSE)
```

## Arguments

- data:

  A data frame or tibble to split and save.

- group_col:

  A string. The name of the column to group by.

- output_dir:

  A string or `NULL`. Path to the directory where output files will be
  written. Created if it does not exist. If `NULL`, the user must supply
  a path explicitly.

- manifest:

  A logical. Whether to write a `manifest.csv` file to `output_dir`
  listing the output files, group values, and row counts. Defaults to
  `FALSE`.

## Value

Invisibly returns `output_dir`.

## Details

Output filenames are derived from the group values of `group_col`.
Values are sanitized before use as filenames: converted to lowercase,
spaces and special characters replaced with `_`, consecutive underscores
collapsed, and leading/trailing underscores stripped.

If `manifest = TRUE`, a `manifest.csv` is written to `output_dir`
containing three columns: `group_value`, `n_rows`, and `file_path`.

Note: `output_dir` has no default value. Always supply an explicit path
to avoid writing files to unexpected locations. Use
[`tempdir()`](https://rdrr.io/r/base/tempfile.html) for temporary output
during testing or exploration.

## Examples

``` r
# \donttest{
# Split a small data frame by group and write to a temp directory
data <- data.frame(
  species = c("Adelie", "Adelie", "Gentoo"),
  mass    = c(3750, 3800, 5000)
)
write_by_group(data, group_col = "species", output_dir = tempdir())
#> ✔ Written "Adelie" (2 rows) to /tmp/RtmptlSgFg/adelie.csv
#> ✔ Written "Gentoo" (1 rows) to /tmp/RtmptlSgFg/gentoo.csv

# Same but also write a manifest
write_by_group(data, group_col = "species",
               output_dir = tempdir(), manifest = TRUE)
#> ✔ Written "Adelie" (2 rows) to /tmp/RtmptlSgFg/adelie.csv
#> ✔ Written "Gentoo" (1 rows) to /tmp/RtmptlSgFg/gentoo.csv
#> ✔ Manifest written to /tmp/RtmptlSgFg/manifest.csv
# }
```
