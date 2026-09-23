# Normalize an ORCID to CFF's full-URL form

Internal helper used by
[`generate_citation()`](https://erwinlares.github.io/toolero/reference/generate_citation.md).
A profile written by
[`generate_profile()`](https://erwinlares.github.io/toolero/reference/generate_profile.md)
stores a bare ORCID (`"0000-0000-0000-0000"`), matching Quarto's own
author schema, but the Citation File Format expects the full URL.
Returns `orcid` unchanged if it already looks like a URL.

## Usage

``` r
.normalize_orcid(orcid)
```

## Arguments

- orcid:

  Character. A bare ORCID iD or a full ORCID URL.

## Value

A single character string, the full `https://orcid.org/...` URL.
