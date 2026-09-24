# Generate a personal defaults file for create_qmd()

Writes a YAML skeleton, pre-filled with placeholders and explanatory
comments, covering the author information and formatting preferences
that tend to be identical across every document you create with
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md).
Edit the result with your own values, then pass its path to
`create_qmd(header_defaults = )` instead of retyping the same author
block and format options on every call.

## Usage

``` r
generate_profile(filename, path = fs::path_home(), overwrite = FALSE)
```

## Arguments

- filename:

  Character. Name of the file to write, e.g. `"profile.yml"` or a
  personal name like `"erwinlares.yml"`. Must be supplied explicitly –
  there is no default, so that keeping more than one profile (a personal
  one and a work one, say) under different filenames is a normal thing
  to do, not a workaround.

- path:

  Character. Directory to write the file into. Defaults to the user's
  home directory
  ([`fs::path_home()`](https://fs.r-lib.org/reference/path_expand.html)),
  not `"."` – unlike
  [`generate_project_config()`](https://erwinlares.github.io/toolero/reference/generate_project_config.md),
  this file's whole purpose is being reusable across every project
  rather than tied to one, so it belongs somewhere that outlives any
  single project directory. Pass `path = "."` if you'd rather keep a
  copy inside a specific project instead.

- overwrite:

  Logical. When `FALSE` (default), an existing file at the destination
  is an error rather than being replaced.

## Value

The path to the written file, invisibly.

## Details

The written file has two sections. Personal information becomes the
document's `author:` block: name, affiliation, ORCID, email, and a
website URL, the fields Quarto's default HTML title block already knows
how to render. Document settings covers the recurring, non-personal
choices
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
doesn't otherwise remember for you: `date`/ `date-modified`,
`categories`, `lang`, `execute` options for quiet and reproducible
rendering, and a `format: html:` block of layout preferences. Neither
section touches `css`, `include-before-body`, or `include-after-body` –
those are
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)'s
`use_style` argument's job, reading from a project's own `assets/`
folder, and a profile that also tried to set them would collide with a
specific project's branding rather than complementing it.

The file is a plain copy of the packaged template, not a form filled in
programmatically – this function does not prompt for values. Open the
written file, replace the placeholder values with your own, and delete
any key you don't want pre-filled;
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
leaves a deleted key's template placeholder untouched.

A phone number and mailing address are deliberately not among the
placeholders. Documents built from this file are the kind that tend to
get rendered to HTML and published, and neither belongs in something
public.

## See also

[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md),
whose `header_defaults` argument reads the file this writes;
[`generate_citation()`](https://erwinlares.github.io/toolero/reference/generate_citation.md),
which can also draw on it.

## Examples

``` r
# \donttest{
generate_profile("my-profile.yml", path = tempdir())
#> ✔ Wrote /tmp/RtmpSbfULX/my-profile.yml.
#> ℹ Open it and replace the placeholder values with your own.
#> ℹ Then pass it to `create_qmd()` as `header_defaults =
#>   "/tmp/RtmpSbfULX/my-profile.yml"`.
# }
```
