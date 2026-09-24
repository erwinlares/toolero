# Fill in a license template

Internal helper backing
[`generate_license()`](https://erwinlares.github.io/toolero/reference/generate_license.md).
Returns the full text of one of a small set of common license templates,
with the holder and year substituted in.

## Usage

``` r
.license_text(license, holder, year)
```

## Arguments

- license:

  A character string. One of `"MIT"`, `"CC0"`, `"GPL-3"`.

- holder:

  A character string. The copyright holder.

- year:

  A character string. The copyright year.

## Value

A character vector, one element per line.
