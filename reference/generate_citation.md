# Generate a CITATION.cff file

Writes a Citation File Format (`CITATION.cff`) skeleton, optionally
pre-filled with author information from a profile written by
[`generate_profile()`](https://erwinlares.github.io/toolero/reference/generate_profile.md),
so a project's citation metadata doesn't mean retyping the same name,
affiliation, and ORCID a third time.

## Usage

``` r
generate_citation(
  filename = "CITATION.cff",
  path = ".",
  profile = NULL,
  overwrite = FALSE
)
```

## Arguments

- filename:

  Character. Name of the file to write. Defaults to `"CITATION.cff"`,
  the name tools that read this format expect; changing it means those
  tools will not find the file automatically.

- path:

  Character. Directory to write the file into. Defaults to `"."` (the
  current working directory), matching the rest of the family's
  project-scaffolding functions.

- profile:

  Character or `NULL`. Path to a profile file, typically one written by
  [`generate_profile()`](https://erwinlares.github.io/toolero/reference/generate_profile.md).
  When supplied, every entry in the profile's `author:` block becomes an
  author entry in the generated file. When `NULL` (the default), a
  single generic placeholder author is written instead.

- overwrite:

  Logical. When `FALSE` (default), an existing file at the destination
  is an error rather than being replaced.

## Value

The path to the written file, invisibly.

## Details

`title`, `version`, `repository-code`, `url`, and `license` are project
facts a personal profile has no way to know, so they are left as
placeholders (some commented out) regardless of `profile`.
`date-released` is filled in with today's date, since that much is
always knowable at generation time; edit it later if the actual release
date differs.

The given-names/family-names split needed by the Citation File Format is
done by splitting a profile's single `name` field on its last space,
which is right for the ordinary case and wrong for some real names.
Review the generated file's `given-names`/`family-names` fields before
relying on them, especially for a multi-word family name.

## See also

[`generate_profile()`](https://erwinlares.github.io/toolero/reference/generate_profile.md),
the function that writes the file this one can read from.

## Examples

``` r
# \donttest{
generate_citation(path = tempdir())
#> ✔ Wrote /tmp/RtmpU20TFH/CITATION.cff.
#> ℹ Wrote a placeholder author -- edit /tmp/RtmpU20TFH/CITATION.cff directly, or
#>   supply `profile`.
#> ℹ Fill in title and, when they're true of this project, the commented-out
#>   fields.

profile_file <- tempfile(fileext = ".yml")
writeLines(
  paste(
    'author:',
    '  - name: "Erwin Lares"',
    '    affiliation: "RCI, UW-Madison"',
    '    orcid: "0000-0002-3284-828X"',
    sep = "\n"
  ),
  profile_file
)
generate_citation(path = tempdir(), profile = profile_file, overwrite = TRUE)
#> ✔ Wrote /tmp/RtmpU20TFH/CITATION.cff.
#> ℹ Author information came from /tmp/RtmpU20TFH/file1ab0753be5b1.yml --
#>   double-check the given-names/family-names split.
#> ℹ Fill in title and, when they're true of this project, the commented-out
#>   fields.
# }
```
