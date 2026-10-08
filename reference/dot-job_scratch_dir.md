# The scratch directory of a batch job, when there is one

Internal helper. HTCondor starts every job in its own scratch directory
and names it in the `_CONDOR_SCRATCH_DIR` environment variable, which
HTCondor sets itself; nobody has to set it. The directory is different
for every job and is where transferred inputs arrive and where
`transfer_output_files` are collected from, so on an execute node it is
the only sensible project root. `$HOME` is not: on an execute node it
can be the submit node's home path, which does not exist there.

## Usage

``` r
.job_scratch_dir()
```

## Value

A single character string (the absolute, symlink-resolved directory), or
`NULL` when the variable is unset, empty, or names a directory that does
not exist.
