#' Check a project for toolero conventions
#'
#' `check_project()` audits a project directory and reports whether it follows
#' the structure and conventions that `init_project()` creates. It is useful
#' both for projects initialized with `init_project()` and for existing
#' projects that were created independently.
#'
#' @param path A character string with the path to the project directory.
#'   Defaults to `"."` (the current working directory).
#' @param error Logical. If `TRUE` (the default), prints a formatted cli
#'   report and returns the results invisibly. If `FALSE`, returns a tibble
#'   with columns `check`, `status`, and `message` without printing.
#'
#' @return A tibble with columns `check`, `status`, and `message`. Returned
#'   invisibly when `error = TRUE`, visibly when `error = FALSE`.
#' @export
#'
#' @examples
#' # Audit the current working directory
#' \donttest{
#' check_project()
#' }
#'
#' # Audit a specific project directory
#' \dontrun{
#' check_project(path = "path/to/project")
#' }
check_project <- function(
        path  = ".",
        error = TRUE) {

    # -- 1. Validate path -------------------------------------------------------
    if (!fs::dir_exists(path)) {
        cli::cli_abort(
            "Directory {.path {path}} does not exist."
        )
    }

    results <- list()

    # -- 2. Check for .Rproj file -----------------------------------------------
    rproj_files <- fs::dir_ls(path, glob = "*.Rproj", all = FALSE)
    if (length(rproj_files) > 0) {
        results[["rproj"]] <- .check_result(
            check   = ".Rproj file",
            status  = "pass",
            message = paste0("Found ", fs::path_file(rproj_files[1]))
        )
    } else {
        results[["rproj"]] <- .check_result(
            check   = ".Rproj file",
            status  = "fail",
            message = "No .Rproj file found -- use {.fn usethis::create_project} to initialize one"
        )
    }

    # -- 3. Check for renv.lock -------------------------------------------------
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

    # -- 4. Check for git -------------------------------------------------------
    git_dir <- fs::path(path, ".git")
    if (fs::dir_exists(git_dir)) {
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

    # -- 5. Check for .gitignore ------------------------------------------------
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

    # -- 6. Check for standard folders ------------------------------------------
    folders <- list(
        list(key = "data_raw", folder = "data-raw", status = "warn",
             message = "No data-raw/ folder found -- consider adding one for raw input data"),
        list(key = "data",     folder = "data",     status = "warn",
             message = "No data/ folder found -- consider adding one for cleaned data"),
        list(key = "docs",     folder = "docs",     status = "warn",
             message = "No docs/ folder found -- consider adding one for documentation")
    )

    for (f in folders) {
        if (fs::dir_exists(fs::path(path, f$folder))) {
            results[[f$key]] <- .check_result(
                check   = glue::glue("{f$folder}/"),
                status  = "pass",
                message = glue::glue("Found {f$folder}/")
            )
        } else {
            results[[f$key]] <- .check_result(
                check   = glue::glue("{f$folder}/"),
                status  = f$status,
                message = f$message
            )
        }
    }

    # -- 7. Check for R/ or scripts/ --------------------------------------------
    has_r       <- fs::dir_exists(fs::path(path, "R"))
    has_scripts <- fs::dir_exists(fs::path(path, "scripts"))

    if (has_r || has_scripts) {
        found <- paste(c(if (has_r) "R/", if (has_scripts) "scripts/"), collapse = " and ")
        results[["code"]] <- .check_result(
            check   = "code folder",
            status  = "pass",
            message = glue::glue("Found {found}")
        )
    } else {
        results[["code"]] <- .check_result(
            check   = "code folder",
            status  = "warn",
            message = "No R/ or scripts/ folder found -- consider adding one for analysis code"
        )
    }

    # -- 8. Check for README ----------------------------------------------------
    readme_files <- c("README.md", "README.Rmd", "README.qmd")
    has_readme   <- any(fs::file_exists(fs::path(path, readme_files)))

    if (has_readme) {
        results[["readme"]] <- .check_result(
            check   = "README",
            status  = "pass",
            message = "Found README"
        )
    } else {
        results[["readme"]] <- .check_result(
            check   = "README",
            status  = "warn",
            message = "No README found -- consider adding one to document the project"
        )
    }

    # -- 9. Check for .RData ----------------------------------------------------
    if (fs::file_exists(fs::path(path, ".RData"))) {
        results[[".rdata"]] <- .check_result(
            check   = ".RData",
            status  = "warn",
            message = ".RData found -- consider deleting it to avoid loading stale session data"
        )
    }

    # -- 10. Check for .Rhistory ------------------------------------------------
    if (fs::file_exists(fs::path(path, ".Rhistory"))) {
        results[[".rhistory"]] <- .check_result(
            check   = ".Rhistory",
            status  = "warn",
            message = ".Rhistory found -- consider adding it to .gitignore"
        )
    }

    # -- 11. Check for .Rprofile ------------------------------------------------
    if (fs::file_exists(fs::path(path, ".Rprofile"))) {
        results[[".rprofile"]] <- .check_result(
            check   = ".Rprofile",
            status  = "info",
            message = ".Rprofile found -- ensure customizations are documented for collaborators"
        )
    }

    # -- 12. Check for .Renviron ------------------------------------------------
    if (fs::file_exists(fs::path(path, ".Renviron"))) {
        results[[".renviron"]] <- .check_result(
            check   = ".Renviron",
            status  = "info",
            message = ".Renviron found -- ensure it is listed in .gitignore to avoid leaking credentials"
        )
    }

    # -- 13. Assemble tibble ----------------------------------------------------
    out <- tibble::tibble(
        check   = unname(vapply(results, `[[`, character(1), "check")),
        status  = unname(vapply(results, `[[`, character(1), "status")),
        message = unname(vapply(results, `[[`, character(1), "message"))

    )

    # -- 14. Print or return ----------------------------------------------------
    if (isTRUE(error)) {
        .print_check_project(out)
        invisible(out)
    } else {
        out
    }
}


# -- Internal helpers ----------------------------------------------------------

.check_result <- function(check, status, message) {
    list(
        check   = check,
        status  = status,
        message = message
    )
}

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
