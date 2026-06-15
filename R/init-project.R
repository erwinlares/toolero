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
#' @param custom_folders A character vector of folder names to add to or remove
#'   from the project structure after the base set is resolved. Bare names
#'   (e.g., `"models"`) add a folder. Names prefixed with `"-"` (e.g.,
#'   `"-output/figures"`) suppress creation of that folder. When removing,
#'   only the named leaf is suppressed -- parent directories are unaffected.
#'   Duplicates of existing folders generate a message and are skipped.
#'   References to non-existent folders via `"-"` generate a warning.
#'   Defaults to `NULL`.
#' @param config A character string. Path to a YAML project config file
#'   produced by [generate_project_config()]. When supplied, the folder list
#'   in the config replaces the built-in standard structure entirely.
#'   `custom_folders` is still applied on top of the config-derived set.
#'   Defaults to `NULL`.
#' @param open Logical. If `TRUE`, opens the new project in RStudio after
#'   creation. Defaults to `FALSE`.
#' @param uw_branding Logical. If `TRUE`, creates an `assets/` folder and
#'   populates it with UW-Madison RCI branding files (`styles.css`,
#'   `header.html`, `rci-banner.png`). Defaults to `FALSE`.
#' @importFrom yaml read_yaml
#' @return Called for its side effects. Invisibly returns `path`.
#' @export
#'
#' @examples
#' \dontrun{
#' init_project(path = file.path(tempdir(), "project1"),
#'              use_renv = FALSE, use_git = FALSE)
#'
#' init_project(path = file.path(tempdir(), "project2"),
#'              uw_branding = TRUE, use_renv = FALSE, use_git = FALSE)
#'
#' # Add a folder and suppress one from the standard set
#' init_project(path = file.path(tempdir(), "project3"),
#'              custom_folders = c("models", "-output/figures"),
#'              use_renv = FALSE, use_git = FALSE)
#'
#' # Drive structure entirely from a config file
#' init_project(path = file.path(tempdir(), "project4"),
#'              config = "~/linguistics-project.yml",
#'              use_renv = FALSE, use_git = FALSE)
#' }

init_project <- function(path,
                         use_renv       = TRUE,
                         use_git        = TRUE,
                         custom_folders = NULL,
                         config         = NULL,
                         open           = FALSE,
                         uw_branding    = FALSE) {

    # -- 1. Normalize path early, before usethis shifts the active project ------
    path <- fs::path_abs(path)

    withr::with_dir(getwd(), {

        # -- 2. Create the RStudio project --------------------------------------
        usethis::create_project(path, open = FALSE)

        # -- 3. Resolve the base folder set: config or standard -----------------
        if (!is.null(config)) {

            if (!fs::file_exists(config)) {
                cli::cli_abort(
                    "Config file {.path {config}} does not exist."
                )
            }

            parsed <- yaml::read_yaml(config)

            if (is.null(parsed[["folders"]]) ||
                length(parsed[["folders"]]) == 0L) {
                cli::cli_abort(
                    c("Config file {.path {config}} has no {.field folders} key.",
                      "i" = "Run {.fn generate_project_config} to produce a valid template.")
                )
            }

            base_folders <- as.character(parsed[["folders"]])
            cli::cli_inform(
                "Using project structure from {.path {config}}."
            )

        } else {

            base_folders <- c(
                "data-raw",
                "data",
                "scripts",
                "output/figures",
                "output/tables",
                "reports"
            )

        }

        # -- 4. Apply custom_folders additions and removals ---------------------
        final_folders <- .resolve_custom_folders(base_folders, custom_folders)

        # -- 5. Create folders --------------------------------------------------
        purrr::walk(final_folders, \(folder) {
            fs::dir_create(fs::path(path, folder), recurse = TRUE)
        })

        # -- 6. Copy UW-Madison RCI branding files into assets/ ----------------
        if (uw_branding) {
            assets_dir <- fs::path(path, "assets")
            fs::dir_create(assets_dir)
            branding_files <- c("styles.css", "header.html", "rci-banner.png")
            purrr::walk(branding_files, \(f) {
                fs::file_copy(
                    system.file("assets", f, package = "toolero"),
                    fs::path(assets_dir, f)
                )
            })
        }

        # -- 7. Initialize renv ------------------------------------------------
        if (use_renv) {
            renv::init(project = path, restart = FALSE)
            writeLines("*.qmd", file.path(path, ".renvignore"))
            renv::snapshot(project = path, prompt = FALSE)
        }

        # -- 8. Initialize git -------------------------------------------------
        if (use_git) usethis::use_git(message = "initial commit")

        # -- 9. Open the project in RStudio ------------------------------------
        if (open) usethis::proj_activate(path)

    })

    invisible(path)
}


# -- Helper: resolve additions and removals from custom_folders ---------------

.resolve_custom_folders <- function(base_folders, custom_folders) {

    if (is.null(custom_folders)) return(base_folders)

    removals  <- character(0)
    additions <- character(0)

    for (entry in custom_folders) {
        if (startsWith(entry, "-")) {
            removals <- c(removals, substring(entry, 2L))
        } else {
            additions <- c(additions, entry)
        }
    }

    # Warn about removals that don't match anything in the base set
    unknown_removals <- setdiff(removals, base_folders)
    if (length(unknown_removals) > 0L) {
        cli::cli_warn(
            c("Some folders passed to {.arg custom_folders} with {.code -} are not in the project structure and will be ignored:",
              "i" = "{.val {unknown_removals}}")
        )
    }

    # Apply removals -- leaf only, parents are unaffected.
    # For any removed nested path (e.g. "output/figures"), preserve the parent
    # ("output") so it is still created even if all children are suppressed.
    result <- base_folders[!base_folders %in% removals]

    nested_removals <- removals[grepl("/", removals, fixed = TRUE)]
    if (length(nested_removals) > 0L) {
        implicit_parents <- unique(fs::path_dir(nested_removals))
        missing_parents  <- implicit_parents[!implicit_parents %in% result]
        if (length(missing_parents) > 0L) {
            result <- c(result, missing_parents)
        }
    }

    # Inform about additions that duplicate existing folders
    duplicates <- additions[additions %in% result]
    if (length(duplicates) > 0L) {
        cli::cli_inform(
            c("Some folders in {.arg custom_folders} already exist in the project structure and will be skipped:",
              "i" = "{.val {duplicates}}")
        )
    }

    # Apply additions, excluding duplicates
    new_additions <- setdiff(additions, result)
    c(result, new_additions)
}


#' Generate a project configuration file
#'
#' Writes a YAML configuration file pre-filled with the standard toolero
#' folder structure. Edit the file to define a custom project layout, then
#' pass its path to [init_project()] via the `config` argument.
#'
#' @param filename A character string. Name of the YAML file to create
#'   (e.g., `"linguistics-project.yml"`). Must be supplied explicitly.
#' @param path A character string. Directory in which to write the file.
#'   Defaults to `"."` (the current working directory). Consider using
#'   `"~"` (your home directory) so the file is easy to reference in
#'   future `init_project()` calls regardless of which project is active.
#' @param overwrite Logical. If `TRUE`, overwrites an existing file at the
#'   same location. Defaults to `FALSE`.
#'
#' @return Invisibly returns the full path to the written file.
#' @export
#'
#' @examples
#' \dontrun{
#' # Write to the current working directory
#' generate_project_config("my-project.yml")
#'
#' # Write to home directory for easy reuse across projects
#' generate_project_config("linguistics-project.yml", path = "~")
#'
#' # Overwrite an existing config
#' generate_project_config("my-project.yml", overwrite = TRUE)
#' }

generate_project_config <- function(filename, path = ".", overwrite = FALSE) {

    # -- 1. Validate filename ---------------------------------------------------
    if (missing(filename) || is.null(filename)) {
        cli::cli_abort(
            "{.arg filename} must be supplied, e.g. {.code filename = \"my-project.yml\"}."
        )
    }

    # Normalize extension to .yml
    if (!fs::path_ext(filename) %in% c("yml", "yaml")) {
        filename <- fs::path_ext_set(filename, "yml")
    }

    # -- 2. Resolve destination path -------------------------------------------
    dest <- fs::path_abs(fs::path(path, filename))

    # -- 3. Guard against overwriting ------------------------------------------
    if (fs::file_exists(dest) && !overwrite) {
        cli::cli_abort(
            c("{.path {dest}} already exists.",
              "i" = "Use {.code overwrite = TRUE} to replace it.")
        )
    }

    # -- 4. Write the config file ----------------------------------------------
    config_text <- c(
        "# toolero project configuration",
        "# -----------------------------------------------------------------------",
        "# Pass this file to init_project() via the config argument:",
        "#",
        "#   init_project(path = \"my-project\", config = \"path/to/this-file.yml\")",
        "#",
        "# Tip: store this file in your home directory (~/) so you can reference",
        "# it without a full path. You can maintain multiple configs for different",
        "# project types (e.g., linguistics-project.yml, genomics-project.yml).",
        "#",
        "# List one folder per line under 'folders:'. Nested folders such as",
        "# output/figures are supported. The config replaces the standard toolero",
        "# folder structure entirely -- list every folder you want created.",
        "# -----------------------------------------------------------------------",
        "",
        "folders:",
        "  - data-raw",
        "  - data",
        "  - scripts",
        "  - output/figures",
        "  - output/tables",
        "  - reports"
    )

    writeLines(config_text, dest)
    cli::cli_alert_success("Created {.path {dest}}")
    cli::cli_inform(
        c("i" = "Edit {.path {dest}} to define your custom folder structure,",
          " " = "  then pass it to {.fn init_project} via {.code config = \"{dest}\"}.",
          "i" = "For easy reuse across projects, consider moving this file to {.path {fs::path_home()}}.")
    )

    invisible(dest)
}
