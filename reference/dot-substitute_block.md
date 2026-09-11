# Substitute a block placeholder in a template

Internal helper used by
[`.write_project_yml()`](https://erwinlares.github.io/toolero/reference/dot-write_project_yml.md).
Replaces the single line matching `placeholder` with the lines in
`replacement`, preserving everything around it. Plain line substitution
rather than a YAML round trip, so the template's explanatory comments
survive intact.

## Usage

``` r
.substitute_block(lines, placeholder, replacement)
```

## Arguments

- lines:

  Character vector. The template, one element per line.

- placeholder:

  Character. The placeholder token, matched against the trimmed line.

- replacement:

  Character vector. Lines to insert in its place.

## Value

A character vector.
