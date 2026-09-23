# Render one CFF author entry

Internal helper used by
[`generate_citation()`](https://erwinlares.github.io/toolero/reference/generate_citation.md)
to render a single `authors:` list item from one entry of a profile's
`author:` block (or from a generic placeholder when no profile was
supplied).

## Usage

``` r
.cff_author_block(author)
```

## Arguments

- author:

  A named list, typically one element of a profile's `author:` field,
  with any of `name`, `affiliation`, `orcid`, `email`. Missing fields
  are simply omitted from the rendered block.

## Value

A character vector of YAML lines, indented as a single `authors:`
sequence item.
