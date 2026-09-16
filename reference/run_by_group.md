# Apply a function to each group in a manifest or named list

`run_by_group()` applies a function to each subset of a dataset and
collects the results. Subsets can be supplied in two ways: as files
listed in a manifest produced by
[`write_by_group()`](https://erwinlares.github.io/toolero/reference/write_by_group.md),
or as a named list of data frames already in memory. When the function
returns tabular output (a data frame or tibble), the results are
automatically unnested into a flat tibble with a group-id column. When
the function returns non-tabular output (a model, a plot, a file path),
the results are returned as a nested tibble with a group-id column and a
`results` list-column.

## Usage

``` r
run_by_group(
  manifest = NULL,
  .f,
  ...,
  groups = NULL,
  .id = "group_id",
  .read_fn = read_clean_csv,
  workers = 1L,
  seed = NULL,
  verbose = FALSE
)
```

## Arguments

- manifest:

  A character string, data frame, or `NULL`. If a string, the path to a
  manifest CSV produced by `write_by_group(manifest = TRUE)`. Must
  contain a `group_value` and a `file_path` column. If a data frame,
  used directly. If `groups` is supplied, `manifest` is ignored with a
  warning and may be omitted entirely.

- .f:

  A function to apply to each subset. Must accept a data frame as its
  first argument. Additional arguments can be passed via `...`.

- ...:

  Additional arguments passed to `.f` on every call. Forwarded
  unevaluated when running sequentially, so `.f` receives them exactly
  as it would from a direct call and tidy evaluation works. Materialized
  when `workers > 1`, which parallel execution requires. See the section
  on passing arguments below.

- groups:

  A named list of data frames, or `NULL` (the default). When supplied,
  `manifest` is ignored and `.f` is applied directly to each list
  element. All elements must be data frames with identical column names
  and column types – consistent with subsets produced by
  [`write_by_group()`](https://erwinlares.github.io/toolero/reference/write_by_group.md).
  If the list is unnamed, groups are assigned fallback names `group_1`,
  `group_2`, etc. with a warning.

- .id:

  A character string. Name of the column that identifies each group in
  the output. Defaults to `"group_id"`.

- .read_fn:

  A function used to read each subset file when `manifest` is used.
  Defaults to
  [`read_clean_csv()`](https://erwinlares.github.io/toolero/reference/read_clean_csv.md).
  Ignored when `groups` is supplied.

- workers:

  A positive integer, or `NULL`. Number of parallel R sessions to use.
  When `1L` (the default) or `NULL`, subsets are processed sequentially
  with [`purrr::map()`](https://purrr.tidyverse.org/reference/map.html);
  `NULL` is accepted as a way of saying "do not parallelize" and is
  treated as `1L`. When greater than `1`, subsets are processed in
  parallel with
  [`furrr::future_map()`](https://furrr.futureverse.org/reference/future_map.html).
  Requires the `furrr` and `future` packages. The maximum allowed value
  is `max(1L, parallelly::availableCores() - 1L)` to reserve one core
  for the main R session. A good starting value is the number of groups
  or that core ceiling, whichever is smaller.

- seed:

  An integer or `NULL`. Random seed for reproducible parallel execution.
  Only relevant when `workers > 1` and `.f` involves randomness (e.g.
  simulations, bootstrapping). When `NULL` (the default), no seed
  management is applied. Ignored when `workers = 1L`.

- verbose:

  Logical. If `TRUE`, prints a progress message before processing each
  group. When `workers > 1`, per-group progress is replaced by a single
  summary message showing the worker count. Defaults to `FALSE`.

## Value

A tibble. If `.f` returns tabular output, the tibble is flat with a
`.id` column prepended. If `.f` returns non-tabular output, the tibble
has two columns: `.id` and `results` (a list-column).

## The split-apply pattern

`run_by_group()` is the apply half of the split-apply workflow in
toolero. The split half is
[`write_by_group()`](https://erwinlares.github.io/toolero/reference/write_by_group.md),
which partitions a data frame by a grouping column and writes one file
per group along with a manifest.

    # Split to disk
    write_by_group(penguins, group_col = "species",
                   output_dir = "data/jobs", manifest = TRUE)

    # Apply from disk via manifest
    results <- run_by_group(
      manifest = "data/jobs/manifest.csv",
      .f       = my_analysis
    )

    # Apply from memory via named list
    subsets <- penguins |>
      dplyr::group_split(species) |>
      setNames(c("Adelie", "Chinstrap", "Gentoo"))

    results <- run_by_group(
      groups = subsets,
      .f     = my_analysis
    )

The split is done once. The apply step can be run many times as you
iterate on the analysis function.

## What .f receives and returns

`.f` receives a single data frame as its first argument. It can return
anything, but the return type must be consistent across all groups.
Consistency is evaluated by bucket: either all groups return a data
frame (tabular) or none do (non-tabular). Mixed returns cause an error
identifying which groups returned unexpected types.

Common return types and their output shape:

- A one-row tibble of summary statistics – unnested into a flat table

- A multi-row tibble (e.g. model coefficients) – unnested with the group
  ID repeated per row

- A model object – returned as a list-column

- A ggplot object – returned as a list-column

- A file path – returned as a list-column

## Passing arguments through to `.f`

Most arguments need nothing special. A number, a string, a logical, a
file path, a function: these are ordinary values, and they reach `.f` in
both modes exactly as you would expect. `run_by_group()` imposes no
requirement on how `.f` is written.

    scale_group <- function(data, multiplier) {
      dplyr::summarise(data, total = sum(x) * multiplier)
    }

    run_by_group(groups = subsets, .f = scale_group, multiplier = 10)

One case is different, and only one: an argument that is a bare *column
name*. A symbol like `flipper_length_mm` has no meaning until it meets
the data, so a function that accepts one has to capture it rather than
evaluate it, which is what `{{ }}` does. That is a property of how `.f`
is written rather than anything `run_by_group()` asks for – calling such
a function directly has the same requirement.

    plot_group <- function(data, x, y) {
      ggplot2::ggplot(data, ggplot2::aes(x = {{ x }}, y = {{ y }})) +
        ggplot2::geom_point()
    }

    run_by_group(
      groups = subsets,
      .f     = plot_group,
      x      = flipper_length_mm,
      y      = body_mass_g
    )

Run sequentially, which is the default, `...` is forwarded
*unevaluated*, so `flipper_length_mm` stays a symbol until `{{ }}`
captures it inside `plot_group()` and evaluates it against the group's
data. Versions before 0.5.0 evaluated `...` in `run_by_group()`'s own
frame, where that symbol means nothing, so the call above failed with
`object 'flipper_length_mm' not found` before `plot_group()` was
reached.

If you would rather not write `.f` that way, pass the column name as a
string and index with it. A string is an ordinary value, so it needs no
tidy evaluation and works in both modes:

    plot_group <- function(data, x, y) {
      ggplot2::ggplot(data, ggplot2::aes(x = .data[[x]], y = .data[[y]])) +
        ggplot2::geom_point()
    }

    run_by_group(
      groups = subsets,
      .f     = plot_group,
      x      = "flipper_length_mm",
      y      = "body_mass_g"
    )

**Bare column names do not survive `workers > 1`.** Parallel execution
sends the work to separate R sessions, which means every argument has to
be materialized and serialized first. An argument whose value exists
only inside the data mask `.f` builds has nothing to serialize, so it
cannot make the trip. `run_by_group()` reports this directly rather than
letting it surface from inside `future`'s globals inspection. Ordinary
values, strings included, are unaffected.

The portable form for a bare column name moves it inside `.f`, which
works in both modes:

    run_by_group(
      groups  = subsets,
      .f      = \(d) plot_group(d, x = flipper_length_mm, y = body_mass_g),
      workers = 4
    )

Two smaller consequences of forwarding rather than forcing, both
matching what a direct call to `.f` does, and both sequential-only: an
argument with a side effect is evaluated at most once for the whole call
rather than once per group, and an argument `.f` never touches is never
evaluated at all.

## Examples

``` r
# \donttest{
sample_path <- system.file("templates", "sample.csv", package = "toolero")
penguins <- read_clean_csv(sample_path)

# Split the data to disk
tmp <- tempdir()
write_by_group(penguins, group_col = "species",
               output_dir = tmp, manifest = TRUE)
#> ✔ Written "Adelie" (152 rows) to /tmp/RtmprEtJYE/adelie.csv
#> ✔ Written "Gentoo" (124 rows) to /tmp/RtmprEtJYE/gentoo.csv
#> ✔ Written "Chinstrap" (68 rows) to /tmp/RtmprEtJYE/chinstrap.csv
#> ✔ Manifest written to /tmp/RtmprEtJYE/manifest.csv

# Define an analysis function
summarise_species <- function(data) {
  dplyr::summarise(data,
    n            = dplyr::n(),
    mean_mass    = mean(body_mass_g, na.rm = TRUE),
    mean_flipper = mean(flipper_length_mm, na.rm = TRUE)
  )
}

# Apply via manifest -- returns a flat tibble
results <- run_by_group(
  manifest = file.path(tmp, "manifest.csv"),
  .f       = summarise_species
)

# Apply via named list in memory
subsets <- penguins |>
  dplyr::group_split(species) |>
  setNames(c("Adelie", "Chinstrap", "Gentoo"))

results <- run_by_group(
  groups = subsets,
  .f     = summarise_species
)

# Apply a function that returns a model -- returns a nested tibble
fit_model <- function(data) {
  lm(body_mass_g ~ flipper_length_mm, data = data)
}

models <- run_by_group(
  manifest = file.path(tmp, "manifest.csv"),
  .f       = fit_model
)

# Parallel execution using available cores
workers <- max(1L, parallelly::availableCores() - 1L)

results <- run_by_group(
  manifest = file.path(tmp, "manifest.csv"),
  .f       = summarise_species,
  workers  = workers
)

# Reproducible parallel execution with a fixed seed
random_summary <- function(data) {
  tibble::tibble(val = sample(seq_len(nrow(data)), 1))
}

results <- run_by_group(
  manifest = file.path(tmp, "manifest.csv"),
  .f       = random_summary,
  workers  = workers,
  seed     = 1234
)
# }
```
