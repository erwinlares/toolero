# Split a data frame by one or more grouping columns and write each group to a CSV file

Splits a data frame by one or more grouping columns and writes each
group to a separate CSV file. Optionally writes a job manifest listing
the output files, their group values, and row counts.

## Usage

``` r
write_by_group(
  data,
  group_col,
  output_dir = NULL,
  manifest = FALSE,
  drop_na = TRUE,
  prefix = NULL
)
```

## Arguments

- data:

  A data frame or tibble to split and save.

- group_col:

  A character vector. The name(s) of the column(s) to group by. When
  more than one column is supplied, groups are formed from the
  combinations of values actually present in the data (not the full
  cross-product of possible values).

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

- prefix:

  A string or `NULL`. An optional namespace prepended to every output
  filename, sanitized the same way group values are and joined with a
  single `-`. `prefix = "data"` grouping on one column turns `a.csv`
  into `data-a.csv`; grouping on two turns `a--female.csv` into
  `data-a--female.csv`. Defaults to `NULL`, which leaves filenames
  unchanged. Placed last in the signature so that adding it does not
  shift any existing positional argument.

## Value

Invisibly returns `output_dir`.

## Details

Output filenames are derived from the group values of `group_col`. Each
value is sanitized independently: converted to lowercase, runs of
non-alphanumeric characters replaced with a single `-`, and
leading/trailing dashes stripped. When `group_col` has more than one
element, the sanitized values are joined with `--` in the order
supplied, so `group_col = c("species", "sex")` on an Adelie male
produces `adelie--male.csv`. A `prefix`, if supplied, is sanitized the
same way and joined to the front with a single `-`.

## Why the separators differ

Because a run of non-alphanumeric characters collapses to exactly one
dash, a sanitized value can contain a single `-` but never two in a row.
That is what makes `--` safe between columns: it can only ever appear
where this function put it.

The alternative would lose data rather than merely look untidy. Joined
with a single dash, the groups `("a-b", "c")` and `("a", "b-c")` both
produce the key `a-b-c`, and since the split is performed on that key
the two groups would be merged into one file and reported as one
manifest row. Joined with `--` they are `a-b--c` and `a--b-c`, and stay
distinct.

`prefix` is joined with a single `-` instead, because it is constant
across every file in a call and so cannot create a collision: prepending
the same string to two keys leaves them exactly as distinct as they
were. It is a namespace for the whole split rather than another field of
the group, and reads better as one.

## The job manifest

If `manifest = TRUE`, a `manifest.csv` is written to `output_dir`. This
is the *job manifest*: a list of inputs to a computation that has not
happened yet, and the file consumed by
[`run_by_group()`](https://erwinlares.github.io/toolero/reference/run_by_group.md)
and by `submitr::htc_gen_submit()` in multiple-job mode. It is a
different document from the *project manifest* that
[`generate_manifest()`](https://erwinlares.github.io/toolero/reference/generate_manifest.md)
writes, which records outputs from a computation that already has.

The schema is one column per grouping variable, holding the raw
unsanitized value, followed by `group_value`, `n_rows`, and `file_path`.
Grouping on one column therefore produces a manifest whose first column
repeats `group_value` exactly. That redundancy is deliberate: one schema
with a varying column count is easier to read, validate and rely on than
two schemas selected by how many columns you happened to group on.

`group_value` is a human-readable composite of the raw values joined by
`" | "`, so `"Adelie | male"` for two columns and simply `"Adelie"` for
one.

## Row order

Groups are written, and manifest rows recorded, in order of first
appearance in `data`. This matters downstream: `submitr` writes its
`subdatasets.csv` in manifest order, HTCondor assigns `ProcId` in that
order, and log filenames are reconstructed from position, so manifest
row order is the mapping from a job number back to a group.

## Missing values

With `drop_na = TRUE` (the default), rows with a missing value in any
grouping column are removed before splitting and a message reports how
many.

With `drop_na = FALSE`, missing values are coerced to the string `"NA"`
so that they form their own group rather than being dropped silently by
[`split()`](https://rdrr.io/r/base/split.html). A column that also
contains a literal `"NA"` value – North America, Not Applicable, a
country code – would then have two semantically different groups
collapse into one file. Rather than merge them, `write_by_group()`
aborts and names the column.

Note: `output_dir` has no default value. Always supply an explicit path
to avoid writing files to unexpected locations. Use
[`tempdir()`](https://rdrr.io/r/base/tempfile.html) for temporary output
during testing or exploration.

## See also

[`run_by_group()`](https://erwinlares.github.io/toolero/reference/run_by_group.md),
the apply half of this pair.

## Examples

``` r
# \donttest{
# Split a small data frame by group and write to a temp directory
data <- data.frame(
  species = c("Adelie", "Adelie", "Gentoo"),
  mass    = c(3750, 3800, 5000)
)
write_by_group(data, group_col = "species", output_dir = tempdir())
#> ✔ Written "Adelie" (2 rows) to /tmp/RtmpLTsR81/adelie.csv
#> ✔ Written "Gentoo" (1 rows) to /tmp/RtmpLTsR81/gentoo.csv

# Same but also write a job manifest
write_by_group(data, group_col = "species",
               output_dir = tempdir(), manifest = TRUE)
#> ✔ Written "Adelie" (2 rows) to /tmp/RtmpLTsR81/adelie.csv
#> ✔ Written "Gentoo" (1 rows) to /tmp/RtmpLTsR81/gentoo.csv
#> ✔ Manifest written to /tmp/RtmpLTsR81/manifest.csv

# Namespace the filenames -- adelie.csv becomes penguins-adelie.csv
write_by_group(data, group_col = "species", prefix = "penguins",
               output_dir = tempdir())
#> ✔ Written "Adelie" (2 rows) to /tmp/RtmpLTsR81/penguins-adelie.csv
#> ✔ Written "Gentoo" (1 rows) to /tmp/RtmpLTsR81/penguins-gentoo.csv

# Group by more than one column
data2 <- data.frame(
  species = c("Adelie", "Adelie", "Gentoo"),
  sex     = c("male", "female", "male"),
  mass    = c(3750, 3550, 5000)
)
write_by_group(data2, group_col = c("species", "sex"),
               output_dir = tempdir(), manifest = TRUE)
#> ✔ Written "Adelie | male" (1 rows) to /tmp/RtmpLTsR81/adelie--male.csv
#> ✔ Written "Adelie | female" (1 rows) to /tmp/RtmpLTsR81/adelie--female.csv
#> ✔ Written "Gentoo | male" (1 rows) to /tmp/RtmpLTsR81/gentoo--male.csv
#> ✔ Manifest written to /tmp/RtmpLTsR81/manifest.csv
# }
```
