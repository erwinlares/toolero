# CRAN submission comments -- toolero 0.4.0

## Resubmission note

This is a resubmission. The previous version (0.3.0) was accepted on
April 25, 2026. The gap between submissions reflects the CRAN resubmission
policy; we have waited approximately [X] months before submitting again.

## Changes since 0.3.0

- Added `arborize()` for rendering syntactic trees as PNG images via
  Quarto and the Typst lingotree package
- Added Palmer Penguins dataset attribution in `create_qmd()` template
  and documentation
- Updated DESCRIPTION to reflect full function inventory and declare
  Quarto CLI as a system requirement
- [append new items here as v0.4.0 work continues]

## System requirements

This package requires Quarto CLI (>= 1.4), available at <https://quarto.org>.
This dependency is declared in the SystemRequirements field of DESCRIPTION.

## Test environments

- macOS aarch64 (local), R 4.x.x        [update before submission]
- GitHub Actions: macOS-latest (release)
- GitHub Actions: windows-latest (release)
- GitHub Actions: ubuntu-latest (devel)
- GitHub Actions: ubuntu-latest (release)
- GitHub Actions: ubuntu-latest (oldrel-1)
- win-builder: R-devel                   [run before submission]

## R CMD check results

0 errors | 0 warnings | 0 notes

## Downstream dependencies

There are no reverse dependencies on CRAN.
