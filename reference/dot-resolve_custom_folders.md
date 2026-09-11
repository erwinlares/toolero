# Apply custom_folders additions and removals to a base folder set

Internal helper backing
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)'s
`custom_folders` argument.

## Usage

``` r
.resolve_custom_folders(base_folders, custom_folders, preserve_parents = TRUE)
```

## Arguments

- base_folders:

  Character vector. The folder set to modify.

- custom_folders:

  Character vector or `NULL`. Bare names add; names prefixed with `"-"`
  remove.

- preserve_parents:

  Logical. When `TRUE` (the default), removing a nested folder such as
  `"output/figures"` keeps its parent `"output"` in the set. When
  `FALSE`, the removal is honored exactly as written and no parent is
  added back.
  [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
  passes `FALSE` when the base set came from a `config`, since a config
  is a complete statement of the intended structure.

## Value

A character vector.
