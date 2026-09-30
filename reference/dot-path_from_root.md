# Express a file path relative to the project root, when it is inside it

Internal helper used by
[`save_output()`](https://erwinlares.github.io/toolero/reference/save_output.md)
to record `file_path` in the accumulator. A path inside `root` is
returned relative to it (`"output/fit.rds"`), whether it was given as
absolute (from
[`here::here()`](https://here.r-lib.org/reference/here.html)) or
relative to a working directory somewhere below the root. A path outside
`root` is returned exactly as given, since there is no project-relative
form to offer.

## Usage

``` r
.path_from_root(file_path, root)
```

## Arguments

- file_path:

  Character. The path as given to
  [`save_output()`](https://erwinlares.github.io/toolero/reference/save_output.md).
  Its parent directory must already exist.

- root:

  Character. The project root, as returned by
  [`.project_root()`](https://erwinlares.github.io/toolero/reference/dot-project_root.md).

## Value

A single character string.
