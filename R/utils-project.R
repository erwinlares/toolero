# R/utils-project.R
#
# Shared internals describing a toolero project: the default folder set, the
# default conventions, the reader and writer for the project manifest
# (_toolero.yml), the config-file reader, and README detection.
#
# These exist so that init_project(), generate_project_config(), and
# check_project() agree on one definition of each fact rather than carrying
# their own copy. Adding a folder to the standard set, or a key to the
# conventions block, should require editing exactly one function in this file.


#' Name of the project manifest file
#'
#' Internal helper returning the filename `init_project()` writes to the
#' project root and `check_project()` looks for. Centralized so the name
#' appears once rather than in every function that touches it.
#'
#' @return A single character string.
#'
#' @keywords internal
.project_yml_name <- function() {
    "_toolero.yml"
}


#' Schema version of the project manifest
#'
#' Internal helper returning the schema version this version of toolero
#' writes and understands. This is a schema version, not a package version:
#' it increments only when the shape of `_toolero.yml` changes, which is
#' expected to be rare, and it lets a reader decide whether it can parse a
#' file rather than guessing from the package that wrote it.
#'
#' @return A single integer.
#'
#' @keywords internal
.project_yml_schema_version <- function() {
    1L
}


#' The standard toolero folder set
#'
#' Internal helper returning the default project structure. Single source of
#' truth for [init_project()], [generate_project_config()], and
#' [check_project()].
#'
#' `R/` holds the `.R` script derived from the project's `.qmd` source,
#' whether that derivation happens through [qmd_to_r()] or through the
#' post-render hook scaffolded by [create_qmd()]. `scripts/` holds
#' hand-written, human-maintained scripts. The distinction matters because
#' downstream packages resolve the derived script by convention.
#'
#' @return A character vector of folder paths, relative to the project root.
#'
#' @keywords internal
.default_folders <- function() {
    c(
        "data-raw",
        "data",
        "R",
        "scripts",
        "output/figures",
        "output/tables",
        "reports"
    )
}


#' The standard toolero naming conventions
#'
#' Internal helper returning the default convention set recorded in
#' `_toolero.yml`. These are the names that other packages in the family
#' resolve rather than hardcode.
#'
#' @return A named list of single character strings.
#'
#' @keywords internal
.default_conventions <- function() {
    list(
        output_dir = "output",
        script_dir = "R",
        split_dir  = "data/jobs"
    )
}


#' Locate a template shipped with the package
#'
#' Internal helper wrapping [system.file()] for files under
#' `inst/templates/`. It exists for the error message rather than the lookup:
#' `system.file(mustWork = TRUE)` reports "no file found" when the package is
#' installed and "Can't find package file." under [pkgload::load_all()],
#' neither of which says which file was missing or where it was expected.
#' During development that is the difference between a five-second fix and a
#' traceback.
#'
#' @param name Character. Filename within `inst/templates/`.
#'
#' @return The full path to the template.
#'
#' @keywords internal
.package_template <- function(name) {
    path <- system.file("templates", name, package = "toolero")

    if (!nzchar(path) || !file.exists(path)) {
        cli::cli_abort(c(
            "Could not find the packaged template {.file {name}}.",
            "i" = "Expected it at {.path inst/templates/{name}} in the toolero
                   source tree.",
            "i" = "If you are developing toolero, confirm the file exists and
                   re-run {.fn devtools::load_all}."
        ))
    }

    path
}


#' Substitute a block placeholder in a template
#'
#' Internal helper used by [.write_project_yml()]. Replaces the single line
#' matching `placeholder` with the lines in `replacement`, preserving
#' everything around it. Plain line substitution rather than a YAML round
#' trip, so the template's explanatory comments survive intact.
#'
#' @param lines Character vector. The template, one element per line.
#' @param placeholder Character. The placeholder token, matched against the
#'   trimmed line.
#' @param replacement Character vector. Lines to insert in its place.
#'
#' @return A character vector.
#'
#' @keywords internal
.substitute_block <- function(lines, placeholder, replacement) {
    idx <- which(trimws(lines) == placeholder)

    if (length(idx) != 1L) {
        cli::cli_abort(c(
            "The project template is malformed.",
            "x" = "Expected exactly one {.val {placeholder}} line, found {length(idx)}.",
            "i" = "This is an internal error -- please report it at
                   {.url https://github.com/erwinlares/toolero/issues}."
        ))
    }

    c(lines[seq_len(idx - 1L)], replacement, lines[-seq_len(idx)])
}


#' Write a project manifest
#'
#' Internal helper that renders `inst/templates/_toolero.yml` with a folder
#' list and a conventions block and writes the result to `dest`. Used by both
#' [init_project()], which writes the resolved structure of a project it has
#' just created, and [generate_project_config()], which writes the defaults
#' as a starting point for hand editing. One writer, one format.
#'
#' @param dest Character. Full path of the file to write.
#' @param folders Character vector. Folder paths relative to the project root.
#' @param conventions Named list of single character strings.
#'
#' @return `dest`, invisibly.
#'
#' @keywords internal
.write_project_yml <- function(dest,
                               folders     = .default_folders(),
                               conventions = .default_conventions()) {

    template <- readLines(.package_template(.project_yml_name()), warn = FALSE)

    folder_block <- paste0("  - ", folders)

    convention_block <- paste0(
        "  ",
        names(conventions),
        ": ",
        vapply(conventions, as.character, character(1L), USE.NAMES = FALSE)
    )

    out <- .substitute_block(template, "{{folders}}", folder_block)
    out <- .substitute_block(out, "{{conventions}}", convention_block)

    writeLines(out, dest)

    invisible(dest)
}


#' Read a project manifest from a project directory
#'
#' Internal helper returning the parsed contents of `_toolero.yml` at the
#' root of `path`, or `NULL` when the project does not have one. A project
#' created before this file existed is a normal case, not an error, so the
#' absence is reported as `NULL` and callers decide what to do about it.
#'
#' @param path Character. Path to a project directory.
#'
#' @return A named list, or `NULL`.
#'
#' @keywords internal
.read_project_yml <- function(path) {
    manifest_path <- fs::path(path, .project_yml_name())

    if (!fs::file_exists(manifest_path)) {
        return(NULL)
    }

    yaml::read_yaml(manifest_path)
}


#' Read and validate a project configuration file
#'
#' Internal helper that parses a project configuration file and returns its
#' folder set and conventions. The same schema serves three roles -- a
#' hand-written config passed to [init_project()], the `_toolero.yml` a
#' project carries, and the audit target for [check_project()] -- so this is
#' the one place the schema is validated.
#'
#' A file with no `schema_version` is treated as schema 1, so configs written
#' by earlier versions of toolero, which carried only a `folders:` key,
#' continue to work unchanged.
#'
#' @param config Character. Path to the YAML file.
#' @param arg Character. Name of the calling argument, used in error
#'   messages.
#'
#' @return A named list with elements `folders` (character vector) and
#'   `conventions` (named list, defaults filled in for any key the file does
#'   not supply).
#'
#' @keywords internal
.read_config_file <- function(config, arg = "config") {

    if (!rlang::is_string(config)) {
        cli::cli_abort(c(
            "{.arg {arg}} must be a single character string.",
            "x" = "Received {.obj_type_friendly {config}} of length {length(config)}."
        ))
    }

    if (!fs::file_exists(config)) {
        cli::cli_abort(c(
            "Config file not found at {.file {config}}.",
            "i" = "Generate one with {.fn generate_project_config}."
        ))
    }

    parsed <- yaml::read_yaml(config)

    # -- schema version ------------------------------------------------------
    # supported_schema is bound to a local rather than interpolated directly:
    # cli >= 3.4.0 reads a `{}` expression starting with a dot as a style
    # name, so `{.val {.project_yml_schema_version()}}` is a parse error.
    supported_schema <- .project_yml_schema_version()
    declared_schema  <- parsed[["schema_version"]]

    if (!is.null(declared_schema)) {
        declared_schema <- suppressWarnings(as.integer(declared_schema))

        if (is.na(declared_schema)) {
            cli::cli_abort(c(
                "The {.field schema_version} in {.file {config}} is not a number.",
                "i" = "This version of toolero writes and reads schema
                       {.val {supported_schema}}."
            ))
        }

        if (declared_schema > supported_schema) {
            cli::cli_warn(c(
                "!" = "{.file {config}} declares schema version
                       {.val {declared_schema}}, newer than the
                       {.val {supported_schema}} this version of
                       toolero understands.",
                "i" = "Reading it anyway. Upgrade toolero if the structure
                       does not come out as expected."
            ))
        }
    }

    # -- folders -------------------------------------------------------------
    declared <- parsed[["folders"]]

    if (is.null(declared) || length(declared) == 0L) {
        cli::cli_abort(c(
            "The config file at {.file {config}} has no {.field folders} entry.",
            "i" = "The file should contain a {.field folders:} list with one
                   folder per line.",
            "i" = "Run {.fn generate_project_config} to produce a valid template."
        ))
    }

    if (!is.atomic(declared)) {
        cli::cli_abort(c(
            "The {.field folders} entry in {.file {config}} must be a flat list
             of folder names.",
            "i" = "List one folder per line, without nested keys or values."
        ))
    }

    folders <- as.character(declared)

    if (anyNA(folders) || any(!nzchar(trimws(folders)))) {
        cli::cli_abort(c(
            "The {.field folders} entry in {.file {config}} contains an empty or
             missing folder name.",
            "i" = "Remove blank entries and re-run."
        ))
    }

    folders <- trimws(folders)

    if (anyDuplicated(folders) > 0L) {
        duplicated_folders <- unique(folders[duplicated(folders)])
        cli::cli_inform(c(
            "i" = "Ignoring {length(duplicated_folders)} duplicate folder name{?s}
                   in the config: {.val {duplicated_folders}}."
        ))
        folders <- unique(folders)
    }

    # -- conventions ---------------------------------------------------------
    # Defaults are filled in for any key the file does not supply, so a
    # config written before conventions existed still yields a complete set.
    conventions <- .default_conventions()
    declared_conventions <- parsed[["conventions"]]

    if (!is.null(declared_conventions)) {
        if (!is.list(declared_conventions) ||
            is.null(names(declared_conventions)) ||
            any(!nzchar(names(declared_conventions)))) {
            cli::cli_abort(c(
                "The {.field conventions} entry in {.file {config}} must be a
                 set of named values.",
                "i" = "For example: {.code output_dir: output}."
            ))
        }

        unknown <- setdiff(names(declared_conventions), names(conventions))
        if (length(unknown) > 0L) {
            cli::cli_warn(c(
                "!" = "Ignoring {length(unknown)} unrecognized convention{?s} in
                       {.file {config}}: {.val {unknown}}.",
                "i" = "Recognized conventions are {.val {names(conventions)}}."
            ))
        }

        known <- intersect(names(declared_conventions), names(conventions))
        for (key in known) {
            conventions[[key]] <- as.character(declared_conventions[[key]])
        }
    }

    list(
        folders     = folders,
        conventions = conventions
    )
}


#' Place a .gitkeep in each empty directory
#'
#' Internal helper used by [init_project()] to keep a scaffolded folder
#' structure under version control.
#'
#' git tracks files, not directories, so a project consisting of empty
#' folders commits as nothing at all: the opening commit carries the files at
#' the project root and none of the layout, and a clone arrives with the
#' structure missing. A zero-byte `.gitkeep` in each otherwise empty folder is
#' the conventional remedy -- git has no opinion about the name, it simply
#' needs a file to track.
#'
#' Only empty directories get one. A folder that already has content, such as
#' `assets/` after branding files have been copied in, is tracked on the
#' strength of that content and does not need a placeholder.
#'
#' @param dirs Character vector of directory paths.
#'
#' @return The paths written, invisibly.
#'
#' @keywords internal
.add_gitkeep <- function(dirs) {
    existing <- dirs[fs::dir_exists(dirs)]

    if (length(existing) == 0L) {
        return(invisible(character(0)))
    }

    is_empty <- vapply(
        existing,
        function(dir) length(fs::dir_ls(dir, all = TRUE)) == 0L,
        logical(1L),
        USE.NAMES = FALSE
    )

    if (!any(is_empty)) {
        return(invisible(character(0)))
    }

    keeps <- fs::path(existing[is_empty], ".gitkeep")
    fs::file_create(keeps)

    invisible(as.character(keeps))
}


#' Find a README file in a project directory
#'
#' Internal helper locating a README regardless of capitalization or
#' extension. Any file whose stem matches `readme` counts: `README.md`,
#' `readme`, `Readme.pdf`, and `README.tex` all match. A directory named
#' `readme` does not, nor does `readme-old.md`, nor a double extension such
#' as `readme.tar.gz`.
#'
#' Shared by [init_project()], which refuses to write a README over one that
#' already exists, and [check_project()], which reports whether the project
#' has one. Before this helper existed the two disagreed: `check_project()`
#' matched any variant while `init_project()` checked one exact filename, so
#' a project holding `readme.txt` would quietly acquire a second `README.md`
#' beside it.
#'
#' @param path Character. Path to a project directory.
#'
#' @return The full path to the first matching file, or `NULL` when the
#'   directory holds none or does not exist.
#'
#' @keywords internal
.find_readme <- function(path) {
    if (!fs::dir_exists(path)) {
        return(NULL)
    }

    files <- fs::dir_ls(path, all = TRUE, type = "file")

    if (length(files) == 0L) {
        return(NULL)
    }

    hits <- grepl(
        "^readme(\\.[^.]*)?$",
        fs::path_file(files),
        ignore.case = TRUE
    )

    if (!any(hits)) {
        return(NULL)
    }

    as.character(files[which(hits)[1L]])
}
