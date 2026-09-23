# R/check-project.R

#' Check a project for toolero conventions
#'
#' `check_project()` audits a project directory and reports whether it follows
#' the structure and conventions that `init_project()` creates. It is useful
#' both for projects initialized with `init_project()` and for existing
#' projects that were created independently.
#'
#' @param path Character. Path to the project directory. Defaults to `"."`
#'   (the current working directory).
#' @param config Character or `NULL`. Path to a YAML configuration file
#'   produced by [generate_project_config()]. When supplied, the `folders:`
#'   list in the file replaces the standard toolero folder set for the folder
#'   checks. When `NULL` (the default) and the project carries a
#'   `_toolero.yml`, that file is used instead -- there is no need to hand
#'   `check_project()` the same config on every call. Non-folder hygiene
#'   checks always run regardless.
#' @param error `r lifecycle::badge("deprecated")` Logical. Previously
#'   controlled whether the function printed a cli report (`TRUE`) or
#'   returned a tibble visibly without printing (`FALSE`). Deprecated in
#'   v0.5.0 -- the cli report now always prints and the tibble is always
#'   returned invisibly. Assign the result to access it programmatically:
#'   `out <- check_project()`.
#'
#' @return A tibble with columns `check`, `status`, and `message`, returned
#'   invisibly. Assign the result to use it programmatically.
#'
#' @details
#' Each check records one of four status values: `"pass"` (the expected
#' artifact was found), `"fail"` (a required artifact is missing),
#' `"warn"` (a recommended artifact is missing or a problematic file was
#' found), or `"info"` (a file was found that warrants attention but is
#' not necessarily a problem).
#'
#' README detection is case-insensitive and extension-agnostic: any file
#' whose stem matches `readme` (in any capitalization) counts, regardless
#' of extension or the absence of one. [init_project()] uses the same
#' detection when deciding whether it would overwrite an existing README.
#'
#' @section Where the folder set comes from:
#' Three sources, in order of precedence.
#'
#' An explicit `config` argument wins. Folders it declares and the project
#' lacks are reported as `"fail"`: the caller named a file and that file
#' states what the project should look like.
#'
#' Failing that, a `_toolero.yml` at the project root is used. [init_project()]
#' writes one recording the structure it actually created, so a folder listed
#' there and missing from disk means something removed it. That is also a
#' `"fail"`.
#'
#' Failing both, the built-in standard set is used -- `data-raw/`, `data/`,
#' `R/`, `scripts/`, `output/figures/`, `output/tables/`, and `reports/`.
#' Missing folders here are `"warn"`, not `"fail"`: nobody declared anything,
#' so the standard set is a suggestion rather than a contract.
#'
#' A `_toolero.yml` that exists but cannot be parsed is reported as a failing
#' check and the audit continues against the built-in set. A `config` that
#' cannot be parsed is an error, since the caller asked for that file
#' specifically.
#'
#' @section The renv checks:
#' Beyond the presence of `renv.lock`, two checks guard the failure mode that
#' costs the most to discover late: a lockfile that does not describe the
#' analysis, which produces a container image that builds cleanly and then
#' cannot run.
#'
#' A `.renvignore` excluding `.qmd` files is reported, and the advice is to
#' remove the entry. It stops `renv` from seeing the `library()` calls in a
#' project whose Quarto document is the source of truth. That the document
#' will eventually be purled to a `.R` file does not make up for it: the
#' snapshot you containerize from may be taken before the purl, and the
#' `.qmd` is the file being maintained either way. Versions of
#' `init_project()` before v0.5.0 wrote one; projects created by those
#' versions still carry it.
#'
#' A `renv.lock` recording no packages is reported only when the project also
#' has `.R` or `.qmd` source files. A newly scaffolded project legitimately
#' has an empty lockfile -- [renv::scaffold()] does no dependency discovery,
#' because there is nothing yet to discover -- so the pairing is what makes
#' the observation worth printing.
#'
#' @section Stale purled scripts:
#' Every `.qmd` under `path` whose header declares `purl: true` (see
#' [create_qmd()]'s `use_purl` argument) gets its own row, comparing it
#' against the `.R` script `R/purl.R` is expected to have derived from it.
#' Missing entirely, or older than the `.qmd` it was purled from, is
#' reported as `"warn"`: the `.qmd` is the source of truth, so an `R/`
#' script older than the document it came from means an edit was made and
#' not yet re-rendered, and a container or cluster job that bakes in the
#' `.R` file would run the old analysis without any error to say so.
#' Documents never opted into purl produce no row -- nothing to check.
#'
#' @seealso [init_project()], [generate_project_config()]
#'
#' @examples
#' # Audit the current working directory
#' \donttest{
#' check_project()
#' }
#'
#' # Audit a specific project directory
#' \donttest{
#' project_dir <- withr::local_tempdir()
#' check_project(path = project_dir)
#' }
#'
#' # Audit against a custom folder structure
#' \donttest{
#' project_dir <- withr::local_tempdir()
#' config_path <- file.path(tempdir(), "my-config.yml")
#' generate_project_config("my-config.yml", path = tempdir())
#' check_project(path = project_dir, config = config_path)
#' }
#'
#' # Access results programmatically
#' \donttest{
#' project_dir <- withr::local_tempdir()
#' out <- check_project(path = project_dir)
#' }
#' @export
check_project <- function(path   = ".",
                          config = NULL,
                          error  = TRUE) {

    # -- deprecation -------------------------------------------------------
    if (!isTRUE(error)) {
        lifecycle::deprecate_warn(
            when    = "0.5.0",
            what    = "check_project(error)",
            details = paste0(
                "The cli report now always prints and the tibble is always returned ",
                "invisibly. To access results programmatically, assign the output: ",
                "`out <- check_project()`."
            )
        )
    }

    # -- 1. Validate path --------------------------------------------------
    if (!fs::dir_exists(path)) {
        cli::cli_abort("Directory {.path {path}} does not exist.")
    }
    results <- list()

    manifest_name <- .project_yml_name()
    manifest_path <- fs::path(path, manifest_name)
    has_manifest  <- fs::file_exists(manifest_path)

    # -- 2. Resolve the folder set and conventions -------------------------
    # Precedence: explicit config > the project's own manifest > built-in
    # default. The source decides how a missing folder is reported: a
    # declaration that is not met is a failure, an unmet suggestion is not.
    manifest_error <- NULL

    if (!is.null(config)) {
        # An explicit config is the caller naming a file, so a malformed one
        # is an error rather than a finding.
        resolved      <- .read_config_file(config, arg = "config")
        folder_source <- "config"

    } else if (has_manifest) {
        # The project's own manifest is something check_project() went
        # looking for. Reporting that it is broken is more useful than
        # aborting the audit over it, so the failure becomes a row and the
        # folder checks fall back to the built-in set.
        resolved <- tryCatch(
            .read_config_file(manifest_path, arg = "path"),
            error = function(cnd) {
                manifest_error <<- conditionMessage(cnd)
                NULL
            }
        )

        folder_source <- if (is.null(resolved)) "default" else "manifest"

    } else {
        resolved      <- NULL
        folder_source <- "default"
    }

    if (is.null(resolved)) {
        resolved <- list(
            folders     = .default_folders(),
            conventions = .default_conventions()
        )
    }

    folder_list <- resolved$folders
    conventions <- resolved$conventions

    # -- 3. Check for the project manifest ---------------------------------
    if (!is.null(manifest_error)) {
        results[["toolero_yml"]] <- .check_result(
            check   = manifest_name,
            status  = "fail",
            message = .cli_escape(paste0(
                "Found ", manifest_name, " but could not read it: ",
                manifest_error,
                " -- auditing against the standard folder set instead"
            ))
        )
    } else if (has_manifest) {
        results[["toolero_yml"]] <- .check_result(
            check   = manifest_name,
            status  = "pass",
            message = .cli_escape(paste0("Found ", manifest_name))
        )
    } else {
        results[["toolero_yml"]] <- .check_result(
            check   = manifest_name,
            status  = "warn",
            message = paste0(
                "No ", manifest_name, " found -- create one with ",
                "{.code generate_project_config(\"", manifest_name,
                "\")} and edit it to match this project"
            )
        )
    }

    # -- 4. Report conventions only when they differ from the defaults -----
    # Silence when they match. A reader who sees a conventions row knows
    # something in this project resolves differently from every other one.
    default_conventions <- .default_conventions()

    changed <- names(default_conventions)[vapply(
        names(default_conventions),
        function(key) !identical(conventions[[key]], default_conventions[[key]]),
        logical(1L)
    )]

    if (length(changed) > 0L) {
        results[["conventions"]] <- .check_result(
            check   = "conventions",
            status  = "info",
            message = .cli_escape(paste0(
                "Non-default conventions: ",
                paste0(changed, " = ", unlist(conventions[changed]),
                       collapse = ", ")
            ))
        )
    }

    # -- 5. Check for .Rproj file ------------------------------------------
    rproj_files <- fs::dir_ls(path, glob = "*.Rproj", all = FALSE, type = "file")
    if (length(rproj_files) > 0L) {
        results[["rproj"]] <- .check_result(
            check   = ".Rproj file",
            status  = "pass",
            message = .cli_escape(glue::glue("Found {fs::path_file(rproj_files[1])}"))
        )
    } else {
        results[["rproj"]] <- .check_result(
            check   = ".Rproj file",
            status  = "fail",
            message = "No .Rproj file found -- use {.fn usethis::create_project} to initialize one"
        )
    }

    # -- 6. Check for renv.lock --------------------------------------------
    lockfile <- fs::path(path, "renv.lock")
    has_lock <- fs::file_exists(lockfile)

    if (has_lock) {
        results[["renv"]] <- .check_result(
            check   = "renv.lock",
            status  = "pass",
            message = "Found renv.lock"
        )
    } else {
        results[["renv"]] <- .check_result(
            check   = "renv.lock",
            status  = "fail",
            message = "No renv.lock found -- use {.fn renv::init} to get started"
        )
    }

    # -- 7. Check that the lockfile describes the analysis -----------------
    # Only meaningful once the project has code in it. A freshly scaffolded
    # project has an empty lockfile by design.
    if (has_lock && .renv_lock_is_bare(lockfile) &&
        .project_has_sources(path, folder_list)) {
        results[["renv_packages"]] <- .check_result(
            check   = "renv.lock packages",
            status  = "warn",
            message = paste0(
                "renv.lock records no packages, but this project has R or ",
                "Quarto source files -- run {.fn renv::snapshot} before ",
                "sharing or containerizing, or the environment will not ",
                "reproduce"
            )
        )
    }

    # -- 8. Check for a .renvignore that hides Quarto documents ------------
    if (.renvignore_excludes_qmd(path)) {
        results[["renvignore"]] <- .check_result(
            check   = ".renvignore",
            status  = "warn",
            message = paste0(
                ".renvignore excludes .qmd files -- renv cannot see the ",
                "{.code library()} calls in your Quarto source, so packages ",
                "used only there are missing from renv.lock. Remove the .qmd ",
                "entry; purling to .R later is not a substitute, since the ",
                "snapshot you containerize from may be taken before that ",
                "happens. Written by {.fn init_project} before v0.5.0"
            )
        )
    }

    # -- 9. Check for git --------------------------------------------------
    if (fs::dir_exists(fs::path(path, ".git"))) {
        results[["git"]] <- .check_result(
            check   = "git repository",
            status  = "pass",
            message = "git repository initialized"
        )
    } else {
        results[["git"]] <- .check_result(
            check   = "git repository",
            status  = "fail",
            message = "No git repository found -- use {.fn usethis::use_git} to initialize one"
        )
    }

    # -- 10. Check for .gitignore ------------------------------------------
    if (fs::file_exists(fs::path(path, ".gitignore"))) {
        results[["gitignore"]] <- .check_result(
            check   = ".gitignore",
            status  = "pass",
            message = "Found .gitignore"
        )
    } else {
        results[["gitignore"]] <- .check_result(
            check   = ".gitignore",
            status  = "warn",
            message = "No .gitignore found -- consider adding one to avoid committing unwanted files"
        )
    }

    # -- 11. Check folders -------------------------------------------------
    # A declared folder that is absent is a conformance failure, whether the
    # declaration came from a config the caller named or from the manifest
    # the project carries. The built-in set is a convention, so its absences
    # are advisory.
    folders_are_declared <- folder_source %in% c("config", "manifest")
    missing_status       <- if (folders_are_declared) "fail" else "warn"

    declared_by <- switch(
        folder_source,
        config   = "your config",
        manifest = manifest_name,
        "the standard set"
    )

    for (folder in folder_list) {
        key <- gsub("/", "_", folder, fixed = TRUE)

        if (fs::dir_exists(fs::path(path, folder))) {
            results[[key]] <- .check_result(
                check   = paste0(folder, "/"),
                status  = "pass",
                message = .cli_escape(paste0("Found ", folder, "/"))
            )
        } else {
            msg <- if (folders_are_declared) {
                .cli_escape(paste0(
                    "Folder ", folder, "/ is declared in ", declared_by,
                    " but not found -- create it or update the declaration"
                ))
            } else {
                .standard_folder_message(folder)
            }

            results[[key]] <- .check_result(
                check   = paste0(folder, "/"),
                status  = missing_status,
                message = msg
            )
        }
    }

    # -- 12. Check for README ----------------------------------------------
    readme <- .find_readme(path)

    if (!is.null(readme)) {
        results[["readme"]] <- .check_result(
            check   = "README",
            status  = "pass",
            message = .cli_escape(paste0("Found ", fs::path_file(readme)))
        )
    } else {
        results[["readme"]] <- .check_result(
            check   = "README",
            status  = "warn",
            message = "No README found -- consider adding one to document the project"
        )
    }

    # -- 13. Check for .RData ----------------------------------------------
    if (fs::file_exists(fs::path(path, ".RData"))) {
        results[[".rdata"]] <- .check_result(
            check   = ".RData",
            status  = "warn",
            message = ".RData found -- consider deleting it to avoid loading stale session data"
        )
    }

    # -- 14. Check for .Rhistory -------------------------------------------
    if (fs::file_exists(fs::path(path, ".Rhistory"))) {
        results[[".rhistory"]] <- .check_result(
            check   = ".Rhistory",
            status  = "warn",
            message = ".Rhistory found -- consider adding it to .gitignore"
        )
    }

    # -- 15. Check for .Rprofile -------------------------------------------
    if (fs::file_exists(fs::path(path, ".Rprofile"))) {
        results[[".rprofile"]] <- .check_result(
            check   = ".Rprofile",
            status  = "info",
            message = ".Rprofile found -- ensure customizations are documented for collaborators"
        )
    }

    # -- 16. Check for .Renviron -------------------------------------------
    if (fs::file_exists(fs::path(path, ".Renviron"))) {
        results[[".renviron"]] <- .check_result(
            check   = ".Renviron",
            status  = "info",
            message = ".Renviron found -- ensure it is listed in .gitignore to avoid leaking credentials"
        )
    }

    # -- 16b. Check for stale purled scripts --------------------------------
    # One row per .qmd stamped purl: true, so the report shows every
    # tracked document's status individually rather than one aggregate
    # verdict. Documents never opted into purl (no header, or purl: false)
    # produce no row at all -- nothing to check.
    purled_qmds <- .find_purled_qmds(path, folder_list)

    for (i in seq_along(purled_qmds)) {
        qmd_path <- purled_qmds[[i]]
        rel_qmd  <- fs::path_rel(qmd_path, start = path)
        r_path   <- .purl_output_path(qmd_path, path)

        key <- paste0("purl_", i)

        if (!fs::file_exists(r_path)) {
            results[[key]] <- .check_result(
                check   = paste0("purl: ", rel_qmd),
                status  = "warn",
                message = .cli_escape(paste0(
                    fs::path_rel(r_path, start = path), " does not exist yet -- ",
                    "render ", rel_qmd, " or run qmd_to_r() to produce it"
                ))
            )
        } else if (fs::file_info(qmd_path)$modification_time >
                   fs::file_info(r_path)$modification_time) {
            results[[key]] <- .check_result(
                check   = paste0("purl: ", rel_qmd),
                status  = "warn",
                message = .cli_escape(paste0(
                    fs::path_rel(r_path, start = path), " is older than ", rel_qmd,
                    " -- re-render or re-run qmd_to_r() so the derived script ",
                    "reflects the latest edits"
                ))
            )
        } else {
            results[[key]] <- .check_result(
                check   = paste0("purl: ", rel_qmd),
                status  = "pass",
                message = .cli_escape(paste0(
                    fs::path_rel(r_path, start = path), " is up to date with ", rel_qmd
                ))
            )
        }
    }

    # -- 17. Assemble tibble -----------------------------------------------
    out <- tibble::tibble(
        check   = unname(vapply(results, `[[`, character(1L), "check")),
        status  = unname(vapply(results, `[[`, character(1L), "status")),
        message = unname(vapply(results, `[[`, character(1L), "message"))
    )

    # -- 18. Print and return ----------------------------------------------
    .print_check_project(out)
    invisible(out)
}

# -- Internal helpers ----------------------------------------------------------

#' @keywords internal
.check_result <- function(check, status, message) {
    list(
        check   = check,
        status  = as.character(status),
        message = as.character(message)
    )
}

#' Does a lockfile record no packages?
#'
#' Internal helper used by [check_project()]. Returns `TRUE` only when the
#' lockfile parses and records no packages other than `renv` itself.
#'
#' `renv` is discounted because [renv::scaffold()] installs it into the
#' project library and records it, so the lockfile of a freshly scaffolded
#' project is not literally empty. What matters is whether anything the
#' *analysis* depends on is in there.
#'
#' An unparseable lockfile returns `FALSE`: that is a different problem and
#' this helper should not report it as this one.
#'
#' @param lockfile Character. Path to a `renv.lock` file.
#'
#' @return A single logical.
#'
#' @keywords internal
.renv_lock_is_bare <- function(lockfile) {
    parsed <- tryCatch(
        jsonlite::read_json(lockfile),
        error = function(cnd) NULL
    )

    if (is.null(parsed)) {
        return(FALSE)
    }

    packages <- parsed[["Packages"]]

    if (is.null(packages) || length(packages) == 0L) {
        return(TRUE)
    }

    length(setdiff(names(packages), "renv")) == 0L
}

#' Does the project contain R or Quarto source files?
#'
#' Internal helper used by [check_project()] to decide whether an empty
#' lockfile is worth reporting.
#'
#' Searches the project root without recursing, plus each declared folder
#' with recursion. Deliberately not a recursive sweep of the whole project:
#' `renv/library` holds the sources of every installed package, which would
#' be both slow to walk and wrong to count as the project's own code.
#'
#' @param path Character. Path to a project directory.
#' @param folders Character vector. Folders declared for this project.
#'
#' @return A single logical.
#'
#' @keywords internal
.project_has_sources <- function(path, folders) {
    pattern <- "[.](R|r|[Qq]md|[Rr]md)$"

    root  <- as.character(fs::path(path))
    nests <- as.character(fs::path(path, folders))

    if (length(nests) > 0L) {
        nests <- nests[fs::dir_exists(nests)]
    }

    found_in <- function(dir, recurse) {
        hits <- fs::dir_ls(
            dir,
            type    = "file",
            recurse = recurse,
            regexp  = pattern,
            fail    = FALSE
        )
        length(hits) > 0L
    }

    if (found_in(root, recurse = FALSE)) {
        return(TRUE)
    }

    for (dir in nests) {
        if (found_in(dir, recurse = TRUE)) {
            return(TRUE)
        }
    }

    FALSE
}

#' Find every .qmd stamped purl: true
#'
#' Internal helper used by [check_project()] to locate the documents its
#' stale-purl check needs to look at. Searches the project root without
#' recursing, plus each declared folder with recursion, the same shape
#' [.project_has_sources()] uses and for the same reason: a full recursive
#' sweep would walk `renv/library`, which is slow and holds no documents of
#' the project's own.
#'
#' A `.qmd`'s own header is read with `.split_yaml_header()` and parsed with
#' `yaml::yaml.load()` rather than matched with a regular expression,
#' because `.inject_purl_yaml()` always writes a real YAML boolean and this
#' should agree with however a reader would parse it, not with a pattern
#' that happens to work today.
#'
#' @param path Character. Path to a project directory.
#' @param folders Character vector. Folders declared for this project.
#'
#' @return A character vector of full paths to `.qmd` files whose header
#'   declares `purl: true`, possibly empty.
#'
#' @keywords internal
.find_purled_qmds <- function(path, folders) {
    pattern <- "[.][Qq]md$"

    root  <- as.character(fs::path(path))
    nests <- as.character(fs::path(path, folders))

    if (length(nests) > 0L) {
        nests <- nests[fs::dir_exists(nests)]
    }

    candidates <- fs::dir_ls(root, type = "file", recurse = FALSE, regexp = pattern, fail = FALSE)

    for (dir in nests) {
        candidates <- c(
            candidates,
            fs::dir_ls(dir, type = "file", recurse = TRUE, regexp = pattern, fail = FALSE)
        )
    }

    candidates <- unique(candidates)

    is_purled <- vapply(candidates, function(qmd_path) {
        content <- tryCatch(readr::read_file(qmd_path), error = function(cnd) NA_character_)
        if (is.na(content)) {
            return(FALSE)
        }

        parts <- .split_yaml_header(content)
        if (is.null(parts)) {
            return(FALSE)
        }

        header <- tryCatch(
            yaml::yaml.load(paste(parts$header, collapse = "\n")),
            error = function(cnd) NULL
        )

        isTRUE(header[["purl"]])
    }, logical(1L))

    unname(candidates[is_purled])
}

#' Expected purl output path for a .qmd
#'
#' Internal helper used by [check_project()]. Mirrors the convention
#' `R/purl.R` itself follows: a document's derived script lives under `R/`
#' at the same path, relative to the project root, that the document itself
#' occupies, so two documents sharing a filename in different directories
#' (e.g. a directory-per-post convention using `index.qmd`) map to
#' different output paths.
#'
#' @param qmd_path Character. Full path to a `.qmd` file.
#' @param path Character. Path to the project root.
#'
#' @return A single character string: the full path where the purled `.R`
#'   script is expected.
#'
#' @keywords internal
.purl_output_path <- function(qmd_path, path) {
    rel_qmd <- fs::path_rel(qmd_path, start = path)
    rel_r   <- fs::path_ext_set(rel_qmd, "R")
    fs::path(path, "R", rel_r)
}

#' Does a .renvignore exclude Quarto documents?
#'
#' Internal helper used by [check_project()]. Matches any entry ending in
#' `.qmd`, which covers `*.qmd`, `**/*.qmd`, and a bare `analysis.qmd`.
#'
#' @param path Character. Path to a project directory.
#'
#' @return A single logical.
#'
#' @keywords internal
.renvignore_excludes_qmd <- function(path) {
    renvignore <- fs::path(path, ".renvignore")

    if (!fs::file_exists(renvignore)) {
        return(FALSE)
    }

    entries <- trimws(readLines(renvignore, warn = FALSE))
    entries <- entries[nzchar(entries) & !startsWith(entries, "#")]

    any(grepl("[.]qmd$", entries, ignore.case = TRUE))
}

#' @keywords internal
.print_check_project <- function(results) {
    cli::cli_h1("Project check")

    for (i in seq_len(nrow(results))) {
        status  <- results$status[i]
        message <- results$message[i]

        if (status == "pass") {
            cli::cli_alert_success(message)
        } else if (status == "warn") {
            cli::cli_alert_warning(message)
        } else if (status == "fail") {
            cli::cli_alert_danger(message)
        } else if (status == "info") {
            cli::cli_alert_info(message)
        }
    }
}
