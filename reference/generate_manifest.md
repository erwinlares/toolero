# Write the project manifest

`generate_manifest()` reads the accumulator written by
[`save_output()`](https://erwinlares.github.io/toolero/reference/save_output.md)
over the course of an analysis, collapses it to one row per output file,
and writes `project-manifest.json` describing every artifact the project
produced.

## Usage

``` r
generate_manifest(
  output_dir = "output",
  filename = "project-manifest.json",
  overwrite = FALSE
)
```

## Arguments

- output_dir:

  Character. Directory containing `accumulator.csv` and receiving the
  manifest. Defaults to `"output"`.

- filename:

  Character. Name of the manifest file. Defaults to
  `"project-manifest.json"`.

- overwrite:

  Logical. When `FALSE` (default), an existing manifest at that path is
  an error rather than being replaced.

## Value

The path to the manifest, invisibly.

## Details

The manifest records `execution_context` and `generated_at` once at the
top level, followed by an `artifacts` array with one entry per output
file, ordered chronologically. Context and generation time are facts
about the run as a whole rather than about any individual artifact, so
they are not repeated per entry. Package and R versions are deliberately
absent: that is `renv`'s job, and duplicating it here would create a
second record to keep in sync.

Field names are toolero's own rather than RO-Crate vocabulary. The
translation to `@id`, `dateCreated`, and the rest belongs in
`encapsulr::describe()` as a thin mapping layer, so that toolero's
public interface does not inherit a downstream package's data model.

Checksums are likewise excluded. RO-Crate defers fixity to BagIt and
OCFL, and `rocrateR::bag_rocrate()` computes `manifest-sha512.txt`
automatically at bagging time.

A missing accumulator is an error: no save was ever recorded, and an
empty manifest would present that as a finished result. An accumulator
holding no rows is different – the file exists, so the machinery was
wired up – and produces an empty manifest with a warning.

## The project manifest and the job manifest

This is the *project manifest*: a record of outputs from a computation
that has already happened. It is distinct from the *job manifest*
produced by
[`write_by_group()`](https://erwinlares.github.io/toolero/reference/write_by_group.md)
and consumed by `submitr::htc_gen_submit()`, which lists inputs to a
computation about to happen. The two are structurally different
documents that happen to share a word, which is why this one defaults to
`project-manifest.json` rather than `manifest.json`.

## See also

[`save_output()`](https://erwinlares.github.io/toolero/reference/save_output.md)

## Examples

``` r
output_dir <- withr::local_tempdir()

save_output(
  object = mtcars,
  file_path = fs::path(output_dir, "mtcars.rds"),
  .f = saveRDS,
  output_dir = output_dir
)
#> ℹ Created the directory /tmp/RtmpmVDia1/file4e752f834659 to hold mtcars.rds.

generate_manifest(output_dir = output_dir)
#> ✔ Wrote /tmp/RtmpmVDia1/file4e752f834659/project-manifest.json describing 1
#>   artifact.
```
