#' Initialize a new R project with a standard folder structure
#'
#' `init_project()` creates a new R project at the given path with an
#' opinionated folder structure suited for research workflows. It optionally
#' initializes `renv` for package management and git for version control, and
#' records the structure it resolved in a project manifest at the project
#' root.
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
#'   `"-output/figures"`) suppress creation of that folder. When removing from
#'   the built-in default set, only the named leaf is suppressed -- parent
#'   directories are preserved, so `"-output/figures"` still leaves an
#'   `output/` folder behind. When removing from a set supplied via `config`,
#'   parents are not preserved: a config is an explicit and complete statement
#'   of the structure, so nothing is added back that the author did not ask
#'   for. Duplicates of existing folders generate a message and are skipped.
#'   References to non-existent folders via `"-"` generate a warning.
#'   Defaults to `NULL`.
#' @param config A character string. Path to a YAML project config file
#'   produced by [generate_project_config()]. When supplied, the folder list
#'   in the config replaces the built-in standard structure entirely, and any
#'   `conventions:` it declares override the defaults key by key.
#'   `custom_folders` is still applied on top of the config-derived set.
#'   Defaults to `NULL`.
#' @param open Logical. If `TRUE`, opens the new project in RStudio after
#'   creation. Defaults to `FALSE`.
#' @param branding Character or logical. Controls whether an `assets/`
#'   folder is created and populated. `TRUE` populates it with generic
#'   placeholder branding files (`logo.png`, `favicon.png`, `header.html`,
#'   `footer.html`, `styles.css`). `"uw-madison"` populates it with
#'   UW-Madison RCI branding files under the same standardized names.
#'   `"none"` or `FALSE` creates no `assets/` folder. Defaults to `"none"`.
#'   When branding is enabled, `assets/` joins the project's folder set and is
#'   recorded in the project manifest alongside every other folder, so
#'   downstream packages can find the branding files without being told about
#'   them separately. Note that `favicon.png` is included in the asset set but
#'   is not automatically wired into Quarto output -- favicons are a
#'   website-project option set in `_quarto.yml` rather than a per-document
#'   HTML option.
#' @param uw_branding `r lifecycle::badge("deprecated")` Use `branding`
#'   instead. `uw_branding = TRUE` now maps to `branding = "uw-madison"`;
#'   `uw_branding = FALSE` maps to `branding = "none"`.
#' @param use_readme Logical or character. Controls whether a README file is
#'   created at the project root. `TRUE` creates `README.md` from the
#'   generalist toolero template. `FALSE` creates no README file. `"plain"`
#'   creates `README.txt` with the same generalist content as `README.md` --
#'   only the extension differs, not the content. Defaults to `TRUE`.
#'
#' @section The project manifest:
#' `r lifecycle::badge("experimental")`
#'
#' `init_project()` writes `_toolero.yml` to the project root, recording the
#' folder set it resolved and the naming conventions in force. The file
#' records the *resolved* structure, never the inputs that produced it, so a
#' project built from a `config`, one built with `custom_folders`, and one
#' built from the defaults all produce the same shape of file and a reader
#' never has to replay anything to learn what the project looks like.
#'
#' It exists because the structure is configurable. [check_project()] can
#' audit a customized project without being handed the same config again, and
#' `containr` and `submitr` can resolve where code, data, and outputs live
#' rather than assuming. Commit the file: it describes the project, not the
#' machine it was created on.
#'
#' The format is experimental and may gain keys before it settles. The
#' `schema_version` field exists so that a reader can tell whether it
#' understands what it is holding.
#'
#' @section Dependency discovery and `renv`:
#' When `use_renv = TRUE`, `init_project()` calls [renv::init()] and stops
#' there. Earlier versions additionally wrote a `.renvignore` containing
#' `*.qmd` and took a second snapshot. Both are gone as of v0.5.0.
#'
#' The `.renvignore` excluded `.qmd` files from `renv`'s dependency
#' discovery, which meant that a project whose `library()` calls live in its
#' Quarto source -- the arrangement this package recommends -- could snapshot
#' a lockfile with none of the analysis packages in it, and
#' `containr::generate_dockerfile()` would then build an image that could not
#' run the analysis. Note that at the moment the file was written there were
#' no `.qmd` files in the project yet, so it never affected the snapshot
#' taken at creation time; its only effect was on every snapshot the user
#' took afterwards.
#'
#' Take a snapshot yourself once the project has code in it, and before
#' containerizing:
#'
#' ```r
#' renv::snapshot()
#' ```
#'
#' @importFrom yaml read_yaml
#' @importFrom lifecycle deprecated is_present deprecate_warn
#' @return Called for its side effects. Invisibly returns `path`.
#' @seealso [check_project()], [generate_project_config()]
#' @export
#'
#' @examples
#' \dontrun{
#' init_project(path = file.path(tempdir(), "project1"),
#'              use_renv = FALSE, use_git = FALSE)
#'
#' # Generic placeholder branding
#' init_project(path = file.path(tempdir(), "project2"),
#'              branding = TRUE, use_renv = FALSE, use_git = FALSE)
#'
#' # UW-Madison RCI branding
#' init_project(path = file.path(tempdir(), "project2b"),
#'              branding = "uw-madison", use_renv = FALSE, use_git = FALSE)
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
#'
#' # Plain-text README instead of Markdown (same content, README.txt)
#' init_project(path = file.path(tempdir(), "project5"),
#'              use_readme = "plain", use_renv = FALSE, use_git = FALSE)
#'
#' # Skip the README entirely
#' init_project(path = file.path(tempdir(), "project6"),
#'              use_readme = FALSE, use_renv = FALSE, use_git = FALSE)
#' }

init_project <- function(path,
                         use_renv       = TRUE,
                         use_git        = TRUE,
                         custom_folders = NULL,
                         config         = NULL,
                         open           = FALSE,
                         branding       = "none",
                         uw_branding    = deprecated(),
                         use_readme     = TRUE) {

    # =======================================================================
    # Preconditions. Everything that can fail is checked before anything is
    # created, so a rejected call leaves no half-built project behind.
    # =======================================================================

    # -- 1. Normalize path early, before usethis shifts the active project ---
    path <- fs::path_abs(path)

    # -- 2. Absorb deprecated uw_branding into branding ----------------------
    # Explicit mapping, not a passthrough: old TRUE meant "UW files," which
    # is new branding = "uw-madison", NOT new branding = TRUE (generic).
    if (lifecycle::is_present(uw_branding)) {
        lifecycle::deprecate_warn(
            when = "0.4.0",
            what = "init_project(uw_branding = )",
            with = "init_project(branding = )"
        )
        branding <- if (isTRUE(uw_branding)) "uw-madison" else "none"
    }

    # -- 3. Validate branding ------------------------------------------------
    valid_branding <- list(TRUE, FALSE, "none", "uw-madison")
    if (!any(vapply(valid_branding, identical, logical(1L), y = branding))) {
        cli::cli_abort(
            "{.arg branding} must be {.val TRUE}, {.val FALSE}, {.val none}, or {.val uw-madison}, not {.val {branding}}."
        )
    }

    use_branding <- isTRUE(branding) || identical(branding, "uw-madison")

    # -- 4. Validate use_readme ----------------------------------------------
    valid_readme <- list(TRUE, FALSE, "plain")
    if (!any(vapply(valid_readme, identical, logical(1L), y = use_readme))) {
        cli::cli_abort(
            "{.arg use_readme} must be {.val TRUE}, {.val FALSE}, or {.val plain}, not {.val {use_readme}}."
        )
    }

    use_any_readme <- isTRUE(use_readme) || identical(use_readme, "plain")

    # -- 5. Resolve the folder set and conventions ---------------------------
    # Done up front so a malformed config fails before the project directory
    # is created. A config replaces the folder set entirely and may override
    # conventions key by key; custom_folders is applied on top of whichever
    # base set was chosen.
    from_config <- !is.null(config)

    if (from_config) {
        parsed       <- .read_config_file(config, arg = "config")
        base_folders <- parsed$folders
        conventions  <- parsed$conventions

        cli::cli_inform("Using project structure from {.path {config}}.")
    } else {
        base_folders <- .default_folders()
        conventions  <- .default_conventions()
    }

    # A config is an explicit and complete statement of the structure, so a
    # removal is honored exactly as written. The built-in default set is a
    # convention rather than a declaration, so removing output/figures there
    # still leaves output/ behind.
    final_folders <- .resolve_custom_folders(
        base_folders,
        custom_folders,
        preserve_parents = !from_config
    )

    # Branding puts files in assets/, so assets/ is part of the structure and
    # belongs in the manifest with everything else.
    if (use_branding && !"assets" %in% final_folders) {
        final_folders <- c(final_folders, "assets")
    }

    # -- 6. Check for artifacts this call would overwrite --------------------
    # init_project() scaffolds new projects and does not overwrite work that
    # is already there. Checked before creating anything.
    if (fs::dir_exists(path)) {

        if (use_any_readme) {
            existing_readme <- .find_readme(path)

            if (!is.null(existing_readme)) {
                cli::cli_abort(c(
                    "A README file already exists in {.path {path}}.",
                    "x" = "Found {.file {fs::path_file(existing_readme)}}.",
                    "i" = "{.fn init_project} is designed to scaffold new projects
                           and does not overwrite an existing README.",
                    "i" = "Pass {.code use_readme = FALSE} to skip it."
                ))
            }
        }

        manifest_path <- fs::path(path, .project_yml_name())

        if (fs::file_exists(manifest_path)) {
            cli::cli_abort(c(
                "A {.file {.project_yml_name()}} file already exists in {.path {path}}.",
                "i" = "{.fn init_project} is designed to scaffold new projects and
                       does not overwrite an existing project manifest.",
                "i" = "Run {.fn check_project} to audit the existing project instead."
            ))
        }

        if (use_branding) {
            assets_dir     <- fs::path(path, "assets")
            standard_names <- .branding_asset_names()
            clashes        <- standard_names[
                fs::file_exists(fs::path(assets_dir, standard_names))
            ]

            if (length(clashes) > 0L) {
                cli::cli_abort(c(
                    "Branding files already exist in {.path {assets_dir}}.",
                    "x" = "{.val {clashes}}",
                    "i" = "{.fn init_project} does not overwrite existing branding.",
                    "i" = "Pass {.code branding = \"none\"} to leave them alone."
                ))
            }
        }
    }

    # =======================================================================
    # Creation. Past this point the call is committed.
    # =======================================================================

    # -- 7. Create the RStudio project ---------------------------------------
    # usethis::create_project() sets the active usethis project to the new
    # path and leaves it there. use_git() below relies on that, so the switch
    # is deliberate for the duration of this call, but it is restored on exit
    # rather than left pointing somewhere the caller did not ask for.
    old_project <- tryCatch(usethis::proj_get(), error = function(e) NULL)

    withr::defer({
        if (is.null(old_project)) {
            try(usethis::proj_set(NULL), silent = TRUE)
        } else {
            try(usethis::proj_set(old_project, force = TRUE), silent = TRUE)
        }
    })

    usethis::create_project(path, open = FALSE)

    # -- 8. Create folders ---------------------------------------------------
    purrr::walk(final_folders, \(folder) {
        fs::dir_create(fs::path(path, folder), recurse = TRUE)
    })

    # -- 9. Copy branding files into assets/ ---------------------------------
    if (use_branding) {

        assets_dir <- fs::path(path, "assets")
        fs::dir_create(assets_dir)

        prefix <- if (identical(branding, "uw-madison")) "uw" else "generic"

        purrr::walk(.branding_asset_names(), \(name) {
            src <- system.file(
                "assets", paste0(prefix, "-", name),
                package  = "toolero",
                mustWork = TRUE
            )
            fs::file_copy(src, fs::path(assets_dir, name))
        })
    }
    # branding = "none" or FALSE: no assets/ folder created

    # -- 10. Create README file ----------------------------------------------
    if (use_any_readme) {

        readme_src <- system.file(
            "templates", "readme-template.md",
            package  = "toolero",
            mustWork = TRUE
        )

        readme_name <- if (identical(use_readme, "plain")) "README.txt" else "README.md"

        fs::file_copy(readme_src, fs::path(path, readme_name))
    }
    # use_readme = FALSE: no README file created

    # -- 11. Write the project manifest --------------------------------------
    # Records the resolved structure, not the inputs that produced it. This
    # is what check_project() audits against and what containr and submitr
    # read instead of assuming a layout.
    .write_project_yml(
        dest        = fs::path(path, .project_yml_name()),
        folders     = final_folders,
        conventions = conventions
    )

    cli::cli_alert_success(
        "Recorded project structure in {.file {.project_yml_name()}}"
    )

    # -- 12. Initialize renv -------------------------------------------------
    # No .renvignore and no second snapshot -- see the "Dependency discovery
    # and renv" section of this function's documentation for why both were
    # removed in v0.5.0.
    if (use_renv) {
        renv::init(project = path, restart = FALSE)
    }

    # -- 13. Initialize git --------------------------------------------------
    if (use_git) usethis::use_git(message = "initial commit")

    # -- 14. Open the project in RStudio -------------------------------------
    if (open) usethis::proj_activate(path)

    invisible(path)
}


# -- Helper: the standardized branding filenames ------------------------------

#' Standardized branding asset filenames
#'
#' Internal helper returning the five filenames that every branding mode
#' produces in a project's `assets/` directory. Both `branding = TRUE` and
#' `branding = "uw-madison"` write these exact names, differing only in
#' content, so that [create_qmd()] and `containr` can reference them without
#' knowing which mode was used.
#'
#' @return A character vector of filenames.
#'
#' @keywords internal
.branding_asset_names <- function() {
    c("logo.png", "favicon.png", "header.html", "footer.html", "styles.css")
}


# -- Helper: resolve additions and removals from custom_folders ---------------

#' Apply custom_folders additions and removals to a base folder set
#'
#' Internal helper backing [init_project()]'s `custom_folders` argument.
#'
#' @param base_folders Character vector. The folder set to modify.
#' @param custom_folders Character vector or `NULL`. Bare names add; names
#'   prefixed with `"-"` remove.
#' @param preserve_parents Logical. When `TRUE` (the default), removing a
#'   nested folder such as `"output/figures"` keeps its parent `"output"` in
#'   the set. When `FALSE`, the removal is honored exactly as written and no
#'   parent is added back. [init_project()] passes `FALSE` when the base set
#'   came from a `config`, since a config is a complete statement of the
#'   intended structure.
#'
#' @return A character vector.
#'
#' @keywords internal
.resolve_custom_folders <- function(base_folders,
                                    custom_folders,
                                    preserve_parents = TRUE) {

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

    result <- base_folders[!base_folders %in% removals]

    # For any removed nested path (e.g. "output/figures"), preserve the parent
    # ("output") so it is still created even if all children are suppressed --
    # unless the caller asked for the removal to be honored literally.
    if (preserve_parents) {
        nested_removals <- removals[grepl("/", removals, fixed = TRUE)]
        if (length(nested_removals) > 0L) {
            implicit_parents <- unique(fs::path_dir(nested_removals))
            missing_parents  <- implicit_parents[!implicit_parents %in% result]
            if (length(missing_parents) > 0L) {
                result <- c(result, missing_parents)
            }
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
#' folder structure and naming conventions. Edit the file to define a custom
#' project layout, then pass its path to [init_project()] via the `config`
#' argument.
#'
#' The file uses the same schema as the `_toolero.yml` that [init_project()]
#' writes into a project, so a config you author by hand and a manifest a
#' project carries are the same kind of document. The only difference is who
#' wrote it.
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
#' @seealso [init_project()], [check_project()]
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

    # -- 1. Validate filename ------------------------------------------------
    if (missing(filename) || is.null(filename)) {
        cli::cli_abort(
            "{.arg filename} must be supplied, e.g. {.code filename = \"my-project.yml\"}."
        )
    }

    # Normalize extension to .yml
    if (!fs::path_ext(filename) %in% c("yml", "yaml")) {
        filename <- fs::path_ext_set(filename, "yml")
    }

    # -- 2. Resolve destination path -----------------------------------------
    dest <- fs::path_abs(fs::path(path, filename))

    # -- 3. Guard against overwriting ----------------------------------------
    if (fs::file_exists(dest) && !overwrite) {
        cli::cli_abort(
            c("{.path {dest}} already exists.",
              "i" = "Use {.code overwrite = TRUE} to replace it.")
        )
    }

    # -- 4. Write the config file --------------------------------------------
    # Same writer, same schema, same template as the manifest init_project()
    # writes into a project. The folder list and conventions come from the
    # package defaults rather than from literal text, so adding a folder to
    # the standard set is a one-line change in .default_folders().
    .write_project_yml(
        dest        = dest,
        folders     = .default_folders(),
        conventions = .default_conventions()
    )

    cli::cli_alert_success("Created {.path {dest}}")
    cli::cli_inform(
        c("i" = "Edit {.path {dest}} to define your custom folder structure,",
          " " = "  then pass it to {.fn init_project} via {.code config = \"{dest}\"}.",
          "i" = "For easy reuse across projects, consider moving this file to {.path {fs::path_home()}}.")
    )

    invisible(dest)
}
