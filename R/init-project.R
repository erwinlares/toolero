#' Initialize a new R project with a standard folder structure
#'
#' `init_project()` creates a new R project at the given path with an
#' opinionated folder structure suited for research workflows. It optionally
#' initializes `renv` for package management and git for version control.
#'
#' @param file_path A character string with the path and name of the new
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
#' \dontrun{
#' # Create a project with the standard folder structure
#' init_project("~/Documents/my-project")
#'
#' # Create a project with UW-Madison RCI branding files
#' init_project("~/Documents/my-project", uw_branding = TRUE)
#'
#' # Create a project with an additional folder
#' init_project("~/Documents/my-project", extra_folders = c("notebooks"))
#'
#' # Create a project without renv or git
#' init_project("~/Documents/my-project", use_renv = FALSE, use_git = FALSE)
#' }
init_project <- function(file_path,
                         use_renv = TRUE,
                         use_git = TRUE,
                         extra_folders = NULL,
                         open = TRUE,
                         uw_branding = FALSE) {

    # 1. create the RStudio project
    usethis::create_project(file_path, open = FALSE)

    # 2. create standard folders
    standard_folders <- c("data", "data-raw", "images", "plots",
                          "results", "scripts", "docs", "R")
    purrr::walk(standard_folders,
                \(folder) fs::dir_create(glue::glue("{file_path}/{folder}")))

    # 3. create any extra folders
    if (!is.null(extra_folders)) {
        purrr::walk(extra_folders,
                    \(folder) fs::dir_create(glue::glue("{file_path}/{folder}")))
    }

    # 4. copy UW-Madison RCI branding files into assets/
    if (uw_branding) {
        assets_dir <- file.path(file_path, "assets")
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
    if (use_renv) renv::init(project = file_path, restart = FALSE)

    # 6. initialize git
    if (use_git) usethis::use_git(message = "initial commit")

    # 7. open the project in RStudio
    if (open) usethis::proj_activate(file_path)
}
