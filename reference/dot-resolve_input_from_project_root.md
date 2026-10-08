# Resolve relative input paths from the project root, with a fallback

Internal helper for functions that *read*. It applies
[`.resolve_from_project_root()`](https://erwinlares.github.io/toolero/reference/dot-resolve_from_project_root.md),
then makes one exception for documents written before the root rule: a
relative path that does not exist at the project root but does exist
relative to the working directory is used as typed, and the caller is
told so. The fallback never applies to a path that exists at the root,
to an absolute path, or to a URL, and writers never use it, since
guessing could put a file in the wrong place.

## Usage

``` r
.resolve_input_from_project_root(path, root = NULL)
```

## Arguments

- path:

  Character vector or `NULL`.

- root:

  Character or `NULL`. The project root. Defaults to
  [`.project_root()`](https://erwinlares.github.io/toolero/reference/dot-project_root.md).

## Value

`NULL`, or a character vector the same length and with the same names as
`path`.
