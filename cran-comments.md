## Resubmission

This is a resubmission addressing feedback from Benjamin Altmann. Changes made:

* Removed redundant "in R" from the package title
* Replaced `\dontrun{}` with `\donttest{}` throughout
* Removed default write paths in `create_qmd()` and `write_by_group()`;
  both now default to `NULL` and require an explicit path
* Replaced non-ASCII characters in `R/create_qmd.R`
* Documented the new `interactive_fn` argument in `detect_execution_context()`
* Added `Depends: R (>= 4.2.0)` to reflect use of the pipe placeholder
  syntax introduced in R 4.2.0

New functions added since the previous submission: `detect_execution_context()`,
`create_qmd()`, and `write_by_group()`.

## R CMD check results

0 errors | 0 warnings | 0 notes

## Windows

Checked with `devtools::check_win_devel()`. Status: OK.

## rhub

Checked with `rhub::rhub_check()` on linux, macos-arm64, and windows platforms.

## Downstream dependencies

There are no downstream dependencies for this package.
