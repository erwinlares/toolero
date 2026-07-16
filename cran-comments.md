# CRAN submission comments -- toolero 0.4.0

## Resubmission note

This is a resubmission. The previous version (0.3.0) was accepted on
April 25, 2026. As of this submission, approximately 11 weeks (about
2.7 months) have elapsed since that acceptance.

## Changes since 0.3.0

New features:

- `run_by_group()`: the apply half of the split-apply workflow. Accepts
  a manifest produced by `write_by_group(manifest = TRUE)` or a named
  list, applies a user function to each group, and supports parallel
  execution via furrr/future.
- `write_by_group()`: now accepts multiple grouping columns (previously
  single-column only), with a `drop_na` argument controlling how missing
  grouping values are handled.
- `read_clean_csv()`: added `na`, `drop_na`, and `summary` arguments.
- `write_clean_csv()`, `check_project()`, `qmd_to_r()`, and
  `generate_project_config()`: new exported functions supporting the
  package's project-scaffolding and split-apply-submit workflow.
- `arborize()`: renders syntactic trees as PNG via Quarto and Typst.
- Palmer Penguins dataset attribution added to the `create_qmd()`
  template and documentation.

Breaking changes (all documented in NEWS.md with migration guidance):

- `init_project()`: revised standard folder structure; `extra_folders`
  renamed to `custom_folders` with new select-like syntax.
- `create_qmd()`: styling is now controlled exclusively via the new
  `use_style` argument rather than being copied automatically.

See NEWS.md for the complete, itemized changelog.

## System requirements

This package requires Quarto CLI (>= 1.4), available at <https://quarto.org>.
This dependency is declared in the SystemRequirements field of DESCRIPTION.
`arborize()` additionally depends on the Typst packages `@preview/syntree`
and `@preview/lingotree`, which are not pre-cached on CRAN's check machines.
Tests exercising this rendering path are guarded with `skip_on_cran()` and
`skip_on_ci()` accordingly; this is a deliberate test-environment guard, not
a gap in coverage -- the same tests run locally and in our own CI where
Typst is available.

## Test environments

- macOS aarch64 (local): R 4.6.1 (2026-06-24), macOS Tahoe 26.5.1
- R-hub v2: linux (R-devel)
- R-hub v2: macos (R-devel)
- R-hub v2: macos-arm64 (R-devel)
- R-hub v2: windows (R-devel)

All R-hub v2 checks completed successfully. windows (R-devel) covers the
same ground win-builder would; win-builder was not run separately.

## R CMD check results

0 errors | 0 warnings | 0 notes

## Downstream dependencies

There are no reverse dependencies on CRAN. containr and submitr, the other
packages in the same suite, do not yet depend on toolero (containr's
dependency on toolero is planned for a future release, once both are on
CRAN).
