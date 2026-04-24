# Contributing to toolero

## Function naming philosophy

Function names follow a strict verb convention based on what the
function primarily does:

- `init_()` — one-time scaffolding of a workspace or environment. Runs
  once, creates a persistent structure, gets out of the way. Example:
  [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md).

- `create_()` — produces a specific file or artifact the user will
  author or edit directly. May be called multiple times in the same
  project. Example:
  [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md).

- `generate_()` — derives or assembles an output from inputs that
  already exist. A transformation is happening. Example:
  `generate_dockerfile()`,
  [`generate_kb_xml()`](https://erwinlares.github.io/toolero/reference/generate_kb_xml.md).

- `read_()` — loads data into the R session. Nothing is written to disk.
  Example:
  [`read_clean_csv()`](https://erwinlares.github.io/toolero/reference/read_clean_csv.md).

- `write_()` — persists data or results from the session to disk. The
  complement to `read_()`. Example:
  [`write_by_group()`](https://erwinlares.github.io/toolero/reference/write_by_group.md).

## File naming convention

- R source files use dashes: `create-qmd.R`, `write-by-group.R`
- R functions and objects use underscores:
  [`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md),
  [`write_by_group()`](https://erwinlares.github.io/toolero/reference/write_by_group.md)

## Internal helpers

Internal helpers that are not exported follow the `.function_name()`
convention with a leading dot. Example: `.validate_file_arg()`.
