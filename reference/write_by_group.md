# Split a data frame by one or more grouping columns and write each group to a CSV file

Splits a data frame by one or more grouping columns and writes each
group to a separate CSV file. Optionally writes a manifest file listing
the output files, their group values, and row counts.

## Usage

``` r
write_by_group(
  data,
  group_col,
  output_dir = NULL,
  manifest = FALSE,
  drop_na = TRUE
)
```

## Arguments

- data:

  A data frame or tibble to split and save.

- group_col:

  A character vector. The name(s) of the column(s) to group by. A single
  column name behaves exactly as in previous versions. When more than
  one column is supplied, groups are formed from the combinations of
  values actually present in the data (not the full cross-product of
  possible values).

- output_dir:

  A string or `NULL`. Path to the directory where output files will be
  written. Created if it does not exist. If `NULL`, the user must supply
  a path explicitly.

- manifest:

  A logical. Whether to write a `manifest.csv` file to `output_dir`
  listing the output files, group values, and row counts. Defaults to
  `FALSE`.

- drop_na:

  A logical. If `TRUE` (default), rows with a missing value in any
  grouping column are dropped before splitting, and a message reports
  how many rows were dropped and from which column(s). If `FALSE`,
  missing values are treated as their own group instead of being
  dropped.

## Value

Invisibly returns `output_dir`.

## Details

Output filenames are derived from the group values of `group_col`. Each
value is sanitized independently: converted to lowercase, spaces and
special characters replaced with `-`, consecutive dashes collapsed, and
leading/trailing dashes stripped. When `group_col` has more than one
element, the sanitized values are joined with `--` in the order supplied
(e.g. `group_col = c("species", "sex")` on an Adelie male produces
`adelie--male.csv`). Because a single sanitized value can never itself
contain two consecutive dashes, `--` is an unambiguous separator between
columns.

If `manifest = TRUE`, a `manifest.csv` is written to `output_dir`. For a
single grouping column, the manifest schema is unchanged from previous
versions: `group_value`, `n_rows`, `file_path`. For multiple grouping
columns, the manifest additionally includes one column per grouping
variable (holding the raw, unsanitized value), inserted before
`group_value`, which becomes a human-readable composite of the raw
values joined by `" | "` (e.g. `"Adelie | male"`).

Note: `output_dir` has no default value. Always supply an explicit path
to avoid writing files to unexpected locations. Use
[`tempdir()`](https://rdrr.io/r/base/tempfile.html) for temporary output
during testing or exploration.

Note on group iteration order: groups are split on the sanitized,
character-coerced composite key, so iteration order follows the sort
order of that key rather than the original column's native type. For
single-column grouping this can differ from previous versions when
`group_col` is numeric with values of differing digit length (e.g.
`9, 10, 11` sorts numerically in earlier versions but lexicographically
as `10, 11, 9` here) or when case affects locale-specific sort order.
File contents and manifest row counts are unaffected – only the order in
which groups are written and reported.

## Examples

``` r
# \donttest{
# Split a small data frame by group and write to a temp directory
data <- data.frame(
  species = c("Adelie", "Adelie", "Gentoo"),
  mass    = c(3750, 3800, 5000)
)
write_by_group(data, group_col = "species", output_dir = tempdir())
#> ✔ Written "Adelie" (2 rows) to /tmp/RtmpKCylSI/adelie.csv
#> ✔ Written "Gentoo" (1 rows) to /tmp/RtmpKCylSI/gentoo.csv

# Same but also write a manifest
write_by_group(data, group_col = "species",
               output_dir = tempdir(), manifest = TRUE)
#> ✔ Written "Adelie" (2 rows) to /tmp/RtmpKCylSI/adelie.csv
#> ✔ Written "Gentoo" (1 rows) to /tmp/RtmpKCylSI/gentoo.csv
#> ✔ Manifest written to /tmp/RtmpKCylSI/manifest.csv

# Group by more than one column
data2 <- data.frame(
  species = c("Adelie", "Adelie", "Gentoo"),
  sex     = c("male", "female", "male"),
  mass    = c(3750, 3550, 5000)
)
write_by_group(data2, group_col = c("species", "sex"),
               output_dir = tempdir(), manifest = TRUE)
#> ✔ Written "Adelie | female" (1 rows) to /tmp/RtmpKCylSI/adelie--female.csv
#> ✔ Written "Adelie | male" (1 rows) to /tmp/RtmpKCylSI/adelie--male.csv
#> ✔ Written "Gentoo | male" (1 rows) to /tmp/RtmpKCylSI/gentoo--male.csv
#> ✔ Manifest written to /tmp/RtmpKCylSI/manifest.csv
# }
```
