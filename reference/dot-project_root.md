# Find the project root from a directory

Internal helper used by
[`resolve_input_path()`](https://erwinlares.github.io/toolero/reference/resolve_input_path.md),
[`save_output()`](https://erwinlares.github.io/toolero/reference/save_output.md),
and
[`generate_manifest()`](https://erwinlares.github.io/toolero/reference/generate_manifest.md).
Walks up from `path` looking for any marker in
[`.project_root_criterion()`](https://erwinlares.github.io/toolero/reference/dot-project_root_criterion.md)
and returns the first directory that has one. When none is found,
returns `path` itself: that is what happens on an HTCondor execute node,
where no marker is uploaded, so the job's scratch directory stands in
for the project root and `output/` means the same thing there as it does
on the laptop.

## Usage

``` r
.project_root(path = ".")
```

## Arguments

- path:

  Character. The directory to start from. Defaults to the working
  directory.

## Value

A single character string: the absolute, symlink-resolved path to the
project root.

## Details

Unlike [`here::here()`](https://here.r-lib.org/reference/here.html),
which fixes the root once when the `here` package is loaded, this looks
every time it is called. A function in a package cannot assume the
session has stayed in one project, and the test suite changes directory
between tests.
