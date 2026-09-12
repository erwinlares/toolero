# Guidance for a missing standard folder

Internal helper returning the advisory message for a folder in the
standard toolero set, falling back to a generic message for any folder
not in the lookup table.

## Usage

``` r
.standard_folder_message(folder)
```

## Arguments

- folder:

  Character. A single folder name.

## Value

A single character string.

## Details

Lives beside
[`.default_folders()`](https://erwinlares.github.io/toolero/reference/dot-default_folders.md)
on purpose: the set and the advice for each member of it are one fact,
and keeping them in separate files is how they drift. A folder added to
[`.default_folders()`](https://erwinlares.github.io/toolero/reference/dot-default_folders.md)
without an entry here still works – it gets the generic message – but
the pairing is what makes the omission obvious.
