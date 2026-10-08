# Find the project root from a directory

Internal helper behind every relative path in the package. The order is:

## Usage

``` r
.project_root(path = ".")
```

## Arguments

- path:

  Character. The directory to start from when looking for a marker.
  Defaults to the working directory. Ignored when a job scratch
  directory is in effect.

## Value

A single character string: the absolute, symlink-resolved path to the
project root.

## Details

1.  The job's scratch directory, when `_CONDOR_SCRATCH_DIR` names one
    (see
    [`.job_scratch_dir()`](https://erwinlares.github.io/toolero/reference/dot-job_scratch_dir.md)).
    On an HTCondor execute node it wins over everything else, so the
    answer does not depend on a transferred marker file or on what
    happens to sit above the scratch directory.

2.  The first directory, walking up from `path`, that has any marker in
    [`.project_root_criterion()`](https://erwinlares.github.io/toolero/reference/dot-project_root_criterion.md).

3.  `path` itself, when no marker is found.

Unlike [`here::here()`](https://here.r-lib.org/reference/here.html),
which fixes the root once when the `here` package is loaded, this looks
every time it is called. A function in a package cannot assume the
session has stayed in one project, and the test suite changes directory
between tests.
