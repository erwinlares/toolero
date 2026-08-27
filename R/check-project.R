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
#'   checks. Non-folder hygiene checks (`.Rproj`, `renv.lock`, git,
#'   `.gitignore`, README, `.RData`, `.Rhistory`, `.Rprofile`, `.Renviron`)
#'   always run regardless of the config. Defaults to `NULL` (standard
#'   toolero folders).
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
#' When `config` is `NULL`, folder checks use the standard toolero set:
#' `data-raw/`, `data/`, `scripts/`, `output/figures/`, `output/tables/`,
#' and `reports/`. Missing standard folders are reported as `"warn"`.
#'
#' When `config` is supplied, folder checks use the `folders:` list from
#' the YAML file instead. Missing config-declared folders are reported as
#' `"fail"` rather than `"warn"`, since the user explicitly declared the
#' expected structure.
#'
#' README detection is case-insensitive and extension-agnostic: any file
#' whose stem matches `readme` (in any capitalization) counts, regardless
#' of extension or the absence of one.
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

    # -- 2. Resolve folder set ---------------------------------------------
    if (!is.null(config)) {
        if (!rlang::is_string(config)) {
            cli::cli_abort(c(
                "{.arg config} must be a single character string.",
                "x" = "Received {.obj_type_friendly {config}} of length {length(config)}."
            ))
        }
        if (!fs::file_exists(config)) {
            cli::cli_abort(c(
                "Config file not found at {.file {config}}.",
                "i" = "Generate one with {.fn generate_project_config}."
            ))
        }

        config_data <- yaml::read_yaml(config)
        declared    <- config_data[["folders"]]

        if (is.null(declared) || length(declared) == 0L) {
            cli::cli_abort(c(
                "The config file at {.file {config}} has no {.field folders} entry.",
                "i" = "The file should contain a {.field folders:} list with one folder per line."
            ))
        }

        if (!is.atomic(declared)) {
            cli::cli_abort(c(
                "The {.field folders} entry in {.file {config}} must be a flat list of folder names.",
                "i" = "List one folder per line, without nested keys or values."
            ))
        }

        folder_list <- as.character(declared)

        if (anyNA(folder_list) || any(!nzchar(trimws(folder_list)))) {
            cli::cli_abort(c(
                "The {.field folders} entry in {.file {config}} contains an empty or missing folder name.",
                "i" = "Remove blank entries and re-run."
            ))
        }

        folder_list <- trimws(folder_list)

        if (anyDuplicated(folder_list) > 0L) {
            duplicated_folders <- unique(folder_list[duplicated(folder_list)])
            cli::cli_inform(c(
                "i" = "Ignoring {length(duplicated_folders)} duplicate folder name{?s} in the config: {.val {duplicated_folders}}."
            ))
            folder_list <- unique(folder_list)
        }

        folders_are_declared <- TRUE
    } else {
        folder_list <- c(
            "data-raw",
            "data",
            "scripts",
            "output/figures",
            "output/tables",
            "reports"
        )
        folders_are_declared <- FALSE
    }

    # -- 3. Check for .Rproj file ------------------------------------------
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

    # -- 4. Check for renv.lock --------------------------------------------
    if (fs::file_exists(fs::path(path, "renv.lock"))) {
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

    # -- 5. Check for git --------------------------------------------------
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

    # -- 6. Check for .gitignore -------------------------------------------
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

    # -- 7. Check folders --------------------------------------------------
    missing_status <- if (folders_are_declared) "fail" else "warn"

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
                    "Declared folder ", folder,
                    "/ not found -- create it or update your config"
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

    # -- 8. Check for README -----------------------------------------------
    all_files   <- fs::dir_ls(path, all = TRUE, type = "file")
    readme_hits <- grepl(
        "^readme(\\.[^.]*)?$",
        fs::path_file(all_files),
        ignore.case = TRUE
    )

    if (any(readme_hits)) {
        found_name <- fs::path_file(all_files[which(readme_hits)[1L]])
        results[["readme"]] <- .check_result(
            check   = "README",
            status  = "pass",
            message = .cli_escape(paste0("Found ", found_name))
        )
    } else {
        results[["readme"]] <- .check_result(
            check   = "README",
            status  = "warn",
            message = "No README found -- consider adding one to document the project"
        )
    }

    # -- 9. Check for .RData -----------------------------------------------
    if (fs::file_exists(fs::path(path, ".RData"))) {
        results[[".rdata"]] <- .check_result(
            check   = ".RData",
            status  = "warn",
            message = ".RData found -- consider deleting it to avoid loading stale session data"
        )
    }

    # -- 10. Check for .Rhistory -------------------------------------------
    if (fs::file_exists(fs::path(path, ".Rhistory"))) {
        results[[".rhistory"]] <- .check_result(
            check   = ".Rhistory",
            status  = "warn",
            message = ".Rhistory found -- consider adding it to .gitignore"
        )
    }

    # -- 11. Check for .Rprofile -------------------------------------------
    if (fs::file_exists(fs::path(path, ".Rprofile"))) {
        results[[".rprofile"]] <- .check_result(
            check   = ".Rprofile",
            status  = "info",
            message = ".Rprofile found -- ensure customizations are documented for collaborators"
        )
    }

    # -- 12. Check for .Renviron -------------------------------------------
    if (fs::file_exists(fs::path(path, ".Renviron"))) {
        results[[".renviron"]] <- .check_result(
            check   = ".Renviron",
            status  = "info",
            message = ".Renviron found -- ensure it is listed in .gitignore to avoid leaking credentials"
        )
    }

    # -- 13. Assemble tibble -----------------------------------------------
    out <- tibble::tibble(
        check   = unname(vapply(results, `[[`, character(1L), "check")),
        status  = unname(vapply(results, `[[`, character(1L), "status")),
        message = unname(vapply(results, `[[`, character(1L), "message"))
    )

    # -- 14. Print and return ----------------------------------------------
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

#' Escape cli markup in a data-derived string
#'
#' Internal helper. Messages assembled from user data -- folder names read
#' from a config file, filenames found on disk -- are passed to `cli` as
#' message templates, where braces are interpreted as inline markup. A
#' folder literally named `output/{draft}` would otherwise be evaluated as
#' an R expression and abort the report. Doubling the braces escapes them.
#'
#' Static messages containing intentional markup such as
#' `{.fn usethis::create_project}` must not pass through this helper.
#'
#' @param x A character string.
#'
#' @return The string with braces escaped for cli.
#'
#' @keywords internal
.cli_escape <- function(x) {
    x <- gsub("{", "{{", x, fixed = TRUE)
    gsub("}", "}}", x, fixed = TRUE)
}

#' Guidance for a missing standard folder
#'
#' Internal helper returning the advisory message for a folder in the
#' standard toolero set, falling back to a generic message for any folder
#' not in the lookup table.
#'
#' @param folder Character. A single folder name.
#'
#' @return A single character string.
#'
#' @keywords internal
.standard_folder_message <- function(folder) {
    known <- c(
        "data-raw"       = "No data-raw/ folder found -- consider adding one for raw input data",
        "data"           = "No data/ folder found -- consider adding one for cleaned data",
        "scripts"        = "No scripts/ folder found -- consider adding one for analysis scripts",
        "output/figures" = "No output/figures/ folder found -- consider adding one for figures",
        "output/tables"  = "No output/tables/ folder found -- consider adding one for tables",
        "reports"        = "No reports/ folder found -- consider adding one for reports"
    )

    idx <- match(folder, names(known))

    if (is.na(idx)) {
        .cli_escape(paste0("No ", folder, "/ folder found -- consider adding one"))
    } else {
        unname(known[idx])
    }
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
