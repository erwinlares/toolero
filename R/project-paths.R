# R/project-paths.R

#' Paths in toolero
#'
#' The one rule every toolero function follows when it is given a file or
#' folder path. This is the single place the rule is written down; the help
#' page of each function that takes a path shows the same section.
#'
#' @section Paths:
#' A relative path is read from the project root, not from the working
#' directory. So `save_output(fit, "output/fit.rds", saveRDS)` writes into
#' the project's own `output/` folder whether you call it from the project
#' root, from a document under `reports/`, or from a job on an HTCondor
#' execute node. You never need to wrap a path in `here::here()`. Doing so
#' still works, because `here::here()` returns an absolute path and
#' absolute paths are used as given.
#'
#' The project root is found afresh on every call, in this order:
#'
#' 1. The job's scratch directory, when `_CONDOR_SCRATCH_DIR` names one.
#'    HTCondor sets that variable itself, inside every job.
#' 2. The nearest folder above the working directory that carries a
#'    project marker: the `.here` file [init_project()] writes, an `.Rproj`
#'    file, a package `DESCRIPTION`, or a version control folder such as
#'    `.git`.
#' 3. The working directory, when neither of the above applies.
#'
#' Absolute paths (including those starting with `~`, or a drive letter
#' on Windows) and URLs such as `https://` or `s3://` are used as given.
#' `..` and `./` are not interpreted, so `"../data/x.csv"` means the folder
#' above the root; write an absolute path to leave the project. A bare
#' `"."` means the root itself.
#'
#' Functions that read are forgiving about older code. A relative path that
#' does not exist at the project root but does exist relative to the
#' working directory is read from there, and a message says so. Functions
#' that write never guess: a relative path is always written under the
#' root.
#'
#' A few arguments are deliberately left alone:
#'
#' * [init_project()] reads `path`, `config` and `use_rprofile` from the
#'   working directory, because the project does not exist yet and so has
#'   no root.
#' * Under `Rscript`, [resolve_input_path()] reads the command line
#'   argument as given. Run `Rscript` from the project root or pass an
#'   absolute path.
#' * Arguments passed on through `...` to another function reach it
#'   untouched.
#' * Where a default is "beside the input" ([qmd_to_r()] and
#'   [generate_kb_xml()]), the output follows wherever the input was read
#'   from.
#'
#' Two limits are worth knowing. A project nested inside another project is
#' not supported: the nearest marker wins, which can surprise you when you
#' work from the outer one. And on an execute node `~` and `$HOME` cannot
#' be trusted (`$HOME` can be the submit node's path), so prefer relative
#' paths in job scripts.
#'
#' @name project-paths
#' @keywords internal
NULL
