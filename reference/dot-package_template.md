# Locate a template shipped with the package

Internal helper wrapping
[`system.file()`](https://rdrr.io/r/base/system.file.html) for files
under `inst/templates/`. It exists for the error message rather than the
lookup: `system.file(mustWork = TRUE)` reports "no file found" when the
package is installed and "Can't find package file." under
[`pkgload::load_all()`](https://pkgload.r-lib.org/reference/load_all.html),
neither of which says which file was missing or where it was expected.
During development that is the difference between a five-second fix and
a traceback.

## Usage

``` r
.package_template(name)
```

## Arguments

- name:

  Character. Filename within `inst/templates/`.

## Value

The full path to the template.
