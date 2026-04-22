## Resubmission

This is a second resubmission addressing feedback from Konstanze Lauseker. 
Changes made:

* Replaced all remaining `\dontrun{}` with `\donttest{}` throughout
* Fixed all examples to write to `tempdir()` instead of the user's home
  filespace
* Wrapped `init_project()` body with `withr::with_dir()` to prevent side
  effects on the working directory
* Ran `devtools::document()` to ensure all `.Rd` files are in sync with
  roxygen2 source
* Rewrote `inst/templates/sample.csv` using `readr::write_csv()` to
  eliminate spurious row index column

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a resubmission to CRAN. The NOTE about "New submission" is expected.

## Windows

Checked with `devtools::check_win_devel()`. Status: OK, 1 note (new submission).

## rhub

Checked with `rhub::rhub_check()` on linux, macos-arm64, and windows platforms.

## Downstream dependencies

There are no downstream dependencies for this package.
