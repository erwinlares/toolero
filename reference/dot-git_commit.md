# Read the current git commit, if any

Internal helper used by
[`generate_manifest()`](https://erwinlares.github.io/toolero/reference/generate_manifest.md)
to record which version of the project's code was checked out when the
manifest was written. Best effort and silent: returns `NULL` whenever
`git` is not installed, `path` is not inside a git repository, or the
repository has no commits yet, rather than aborting a manifest write
over a fact that is genuinely optional.

## Usage

``` r
.git_commit(path = ".")
```

## Arguments

- path:

  Character. Directory to check, passed to `git -C`.

## Value

A single character string (the full 40-character commit SHA), or `NULL`.

## Details

Shells out to `git rev-parse HEAD` rather than depending on a git R
package, since this is the only place in toolero that needs git at all.
