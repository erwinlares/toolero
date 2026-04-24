#' Initialize a new R project with a standard folder structure
#'
#' `init_project()` creates a new R project at the given path with an
#' opinionated folder structure suited for research workflows. It optionally
#' initializes `renv` for package management and git for version control.
#'
#' @param path A character string with the path and name of the new
#'   project (e.g., `"~/Documents/my-project"`).
#' @param use_renv Logical. If `TRUE`, initializes `renv` in the new project.
#'   Defaults to `TRUE`.
#' @param use_git Logical. If `TRUE`, initializes a git repository in the new
#'   project. Defaults to `TRUE`.
#' @param extra_folders A character vector of additional folder names to create
#'   inside the project. Defaults to `NULL`.
#' @param open Logical. If `TRUE`, opens the new project in RStudio after
#'   creation. Defaults to `TRUE`.
#' @param uw_branding Logical. If `TRUE`, creates an `assets/` folder and
#'   populates it with UW-Madison RCI branding files (`styles.css`,
#'   `header.html`, `rci-banner.png`). Defaults to `FALSE`.
#'
#' @return Called for its side effects. Does not return a value.
#' @export
#'
#' @examples
#' \donttest{
#' init_project(path = file.path(tempdir(), "project1"),
#'              use_renv = FALSE, use_git = FALSE)
#'
#' init_project(path = file.path(tempdir(), "project2"),
#'              uw_branding = TRUE, use_renv = FALSE, use_git = FALSE)
#'
#' init_project(path = file.path(tempdir(), "project3"),
#'              extra_folders = c("notebooks"),
#'              use_renv = FALSE, use_git = FALSE)
#' }

init_project <- function(path,
                         use_renv = TRUE,
                         use_git = TRUE,
                         extra_folders = NULL,
                         open = FALSE,
                         uw_branding = FALSE) {

    withr::with_dir(getwd(), {

        # 1. create the RStudio project
        usethis::create_project(path, open = FALSE)

        # 2. create standard folders
        standard_folders <- c("data", "data-raw", "images", "plots",
                              "results", "scripts", "docs", "R")
        purrr::walk(standard_folders,
                    \(folder) fs::dir_create(glue::glue("{path}/{folder}")))

        # 3. create any extra folders
        if (!is.null(extra_folders)) {
            purrr::walk(extra_folders,
                        \(folder) fs::dir_create(glue::glue("{path}/{folder}")))
        }

        # 4. copy UW-Madison RCI branding files into assets/
        if (uw_branding) {
            assets_dir <- file.path(path, "assets")
            fs::dir_create(assets_dir)
            branding_files <- c("styles.css", "header.html", "rci-banner.png")
            purrr::walk(branding_files, \(f) {
                fs::file_copy(
                    system.file("extdata", f, package = "toolero"),
                    file.path(assets_dir, f)
                )
            })
        }

        # 5. initialize renv
        if (use_renv) renv::init(project = path, restart = FALSE)

        # 6. initialize git
        if (use_git) usethis::use_git(message = "initial commit")

        # 7. open the project in RStudio
        if (open) usethis::proj_activate(path)

    })
}
