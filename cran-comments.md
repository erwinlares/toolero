## R CMD check results

0 errors | 0 warnings | 1 note

* checking for future file timestamps ... NOTE
  unable to verify current time
  
  This NOTE is environmental — it occurs because the machine running the check 
  cannot reach an internet time server. It does not appear on CRAN's servers.

## Windows

Checked with `devtools::check_win_devel()`. Result: 1 NOTE (same timestamp 
note as above).

## rhub

Checked with `rhub::rhub_check()` on linux and windows platforms. Both passed 
cleanly. macOS platform was skipped due to a rhub infrastructure issue 
(macos-13 runner no longer available on GitHub Actions).

## Downstream dependencies

There are no downstream dependencies for this package.
