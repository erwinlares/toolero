# Resolve relative paths from the project root

Internal helper, the one place the package's path rule is implemented: a
relative path is read as relative to the project root, wherever the code
happens to be running. `NULL` stays `NULL`. Absolute paths (including
`~`), URLs, `NA` and empty strings pass through untouched. Everything
else is joined to `root`. The helper is vectorised and keeps the names
of `path`, so a named vector of folders still carries its labels. A
value that is not a character vector comes back untouched, for the
caller's own validation to reject. `..` is not interpreted and `./` is
not stripped: use an absolute path to opt out of the rule. The one
tidy-up is a bare `"."`, the default of several arguments, which means
the root itself and so becomes `root`, not `root/.`.

## Usage

``` r
.resolve_from_project_root(path, root = NULL)
```

## Arguments

- path:

  Character vector or `NULL`.

- root:

  Character or `NULL`. The project root. Defaults to
  [`.project_root()`](https://erwinlares.github.io/toolero/reference/dot-project_root.md),
  which is only evaluated when at least one value needs it.

## Value

`NULL`, or a character vector the same length and with the same names as
`path`.

## Details

The helper does not look at the file system and never falls back to
anything. Callers that *write* use it as is. Callers that *read* use
[`.resolve_input_from_project_root()`](https://erwinlares.github.io/toolero/reference/dot-resolve_input_from_project_root.md),
which adds the migration fallback.
