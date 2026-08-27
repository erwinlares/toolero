# Save an object and record it in the project accumulator

`save_output()` writes `object` to `file_path` via
`.f(object, file_path, ...)`, then – when `manifest = TRUE` (the
default) – appends a row to the project-level accumulator at
`output_dir/accumulator.csv` recording what was saved, how, and whether
the write succeeded. The accumulator is the working file later consumed
by
[`generate_manifest()`](https://erwinlares.github.io/toolero/reference/generate_manifest.md),
which deduplicates it and reshapes it into `project-manifest.json`.

## Usage

``` r
save_output(
  object,
  file_path,
  .f,
  ...,
  manifest = TRUE,
  note = NULL,
  output_dir = "output"
)
```

## Arguments

- object:

  The object to save.

- file_path:

  Character. A single destination path for `object`. Its parent
  directory is created if it does not already exist, and the creation is
  reported.

- .f:

  A function used to perform the save, called as
  `.f(object, file_path, ...)`. Supply the function itself (for example
  `saveRDS`, `ggplot2::ggsave`), not a call and not a string. Avoid
  reassignment indirection (`my_fn <- ggsave; .f = my_fn`) – the
  accumulator records the name exactly as written at the call site, so
  this records `"my_fn"` rather than `"ggsave"`. Anonymous functions are
  recorded as `"anonymous function: ..."` with the body collapsed to a
  single truncated line.

- ...:

  Additional arguments passed to `.f`.

- manifest:

  Logical. When `TRUE` (default), append a row to the accumulator. When
  `FALSE`, `object` is still saved via `.f`, but nothing is recorded.

- note:

  Character or `NULL`. An optional free-text note recorded alongside
  this row.

- output_dir:

  Character. Directory containing (or to contain) the accumulator.
  Defaults to `"output"`.

## Value

`object`, invisibly. Called for its side effects.

## Details

The call to `.f` is wrapped in a narrowly-scoped
[`tryCatch()`](https://rdrr.io/r/base/conditions.html) – only the
`.f(object, file_path, ...)` call itself, not the rest of
`save_output()`'s body. On failure, a row is still appended recording
`status = "failure"` and the caught message, after which the original
condition is rethrown unmodified. Its class, message, and call are
preserved as caught, so downstream handlers behave as though `.f()` had
been called directly. This is the one place in the package where the
`cli` convention is deliberately not followed:
[`cli::cli_abort()`](https://cli.r-lib.org/reference/cli_abort.html)
would construct a new condition and discard the original class.

`r_class` records `class(object)` as a single pipe-separated field,
captured before the write, since class cannot be reliably recovered from
the file afterward. Timestamps are recorded in UTC with millisecond
precision so that they sort lexicographically –
[`generate_manifest()`](https://erwinlares.github.io/toolero/reference/generate_manifest.md)
relies on this when keeping the latest row per `file_path`.

## See also

[`generate_manifest()`](https://erwinlares.github.io/toolero/reference/generate_manifest.md)

## Examples

``` r
output_dir <- withr::local_tempdir()

save_output(
  object = mtcars,
  file_path = fs::path(output_dir, "mtcars.rds"),
  .f = saveRDS,
  note = "Unmodified example data.",
  output_dir = output_dir
)
#> ℹ Created the directory /tmp/RtmpBGe5Yq/file4fba5344d849 to hold mtcars.rds.
```
