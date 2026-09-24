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
#'   `"-R"` is the one removal that does not take effect on disk: see
#'   `config` below. Defaults to `NULL`.
#' @param config A character string. Path to a YAML project config file
#'   produced by [generate_project_config()]. When supplied, the folder list
#'   in the config replaces the built-in standard structure entirely, and any
#'   `conventions:` it declares override the defaults key by key.
#'   `custom_folders` is still applied on top of the config-derived set.
#'   Defaults to `NULL`.
#'
#'   One folder cannot be suppressed, by a config or by `custom_folders`:
#'   `R/`. [usethis::create_project()] creates it unconditionally, so it is
#'   present in every project `init_project()` makes. A structure that
#'   leaves it out is honored everywhere else -- `R/` is absent from the
#'   project manifest, gets no `.gitkeep`, and is not audited by
#'   [check_project()] -- but the directory itself is there.
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
#' @param use_rprofile Logical. If `TRUE`, appends a block to the
#'   project's `.Rprofile` that sources `~/.Rprofile` if it exists, so a
#'   project under `renv` does not silently shadow the user's personal
#'   startup customizations. See the "Personal `.Rprofile` and renv" section
#'   below. Defaults to `FALSE`.
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
#' @section Empty folders and git:
#' Each folder `init_project()` creates that is still empty when the call
#' finishes receives a zero-byte `.gitkeep`.
#'
#' git tracks files rather than directories, so without this a scaffolded
#' structure survives nothing: the opening commit contains the files at the
#' project root and none of the layout, and a collaborator cloning the
#' repository gets a project with no folders in it. The placeholders are
#' written whether or not `use_git = TRUE`, since a project can be
#' git-initialized at any point afterwards.
#'
#' Folders that already have content are left alone -- `assets/` holds
#' branding files by then and is tracked on the strength of those.
#'
#' @section The active project:
#' `init_project()` makes the new project the active `usethis` project for the
#' duration of the call, and restores whichever project was active before when
#' it returns. Nothing is left pointing somewhere the caller did not ask for.
#'
#' This matters more than it sounds. [usethis::create_project()] sets the
#' active project only for its own duration -- it uses
#' [usethis::local_project()] internally and restores the caller's project on
#' exit when `open = FALSE`. Any step that resolves paths through the active
#' project therefore has to set it again explicitly. In v0.5.0 and earlier
#' `init_project()` did not, so with `use_git = TRUE` the `git` initialization
#' and its opening commit ran against whatever project happened to be active
#' in the calling session rather than the project just created.
#'
#' @section Dependency discovery and `renv`:
#' When `use_renv = TRUE`, `init_project()` calls [renv::scaffold()], which
#' creates `renv/library`, `renv/activate.R`, `renv/.gitignore`, an
#' `.Rprofile` that activates the project in future sessions, and an initial
#' `renv.lock`.
#'
#' Three things changed here in v0.5.0, and they are worth understanding
#' together.
#'
#' `renv::scaffold()` replaces [renv::init()]. `init()` loads the new project
#' into the *calling* session, repointing `.libPaths()` at a library that is
#' empty apart from `renv` itself -- so every package the caller had
#' available vanishes until they restart R. Its `restart` argument suppresses
#' the restart, not the activation. That is reasonable behavior for someone
#' adopting `renv` in the project they are sitting in, and the wrong behavior
#' for a function whose job is to scaffold a project somewhere else.
#' `scaffold()` builds the same infrastructure and leaves the caller's
#' session untouched.
#'
#' The `.renvignore` containing `*.qmd` is gone. It excluded Quarto documents
#' from `renv`'s dependency discovery, which meant that a project whose
#' `library()` calls live in its `.qmd` source -- the arrangement this
#' package recommends -- could snapshot a lockfile with none of the analysis
#' packages in it, and `containr::generate_dockerfile()` would then build an
#' image that could not run the analysis. At the point the file was written
#' the project contained no `.qmd` files at all, so it never affected the
#' snapshot taken at creation time; its only effect was on every snapshot the
#' user took afterwards.
#'
#' The snapshot at creation time is gone too, for the same underlying reason
#' the `.renvignore` was pointless there: a project that has just been
#' created has no code in it, so there is nothing to discover and nothing
#' worth recording. Take a snapshot yourself once the project has code, and
#' before containerizing:
#'
#' ```r
#' renv::snapshot()
#' ```
#'
#' @section Personal `.Rprofile` and renv:
#' R reads exactly one `.Rprofile` per session: the project's own if the
#' working directory has one, `~/.Rprofile` only if it does not. When
#' `use_renv = TRUE`, [renv::scaffold()] writes a project `.Rprofile`
#' containing `source("renv/activate.R")`, and from that point on the
#' user's own `~/.Rprofile` -- aliases, options, personal helper functions
#' -- is shadowed for every session opened in this project. Nothing warns
#' about this; it simply stops loading.
#'
#' `use_rprofile = TRUE` appends a guarded block to the project's
#' `.Rprofile`, after renv's own activation line, that sources
#' `~/.Rprofile` if it exists. The check happens at every session start
#' rather than being baked in once, so a `~/.Rprofile` written or edited
#' after the project is created is still picked up.
#'
#' Defaults to `FALSE` because it cuts against renv's own isolation goal: a
#' project that automatically re-sources the user's personal environment is
#' no longer fully isolated from it. It is also written generically -- the
#' block sources whichever file is at `~/.Rprofile` for whoever opens the
#' project, not a specific person's file -- so a collaborator who clones the
#' project gets the same behavior a project's original author chose, rather
#' than one tied to a specific person's home directory.
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
#'
#' # Keep loading your own ~/.Rprofile customizations under renv (the
#' # scenario this argument exists for -- renv's own generated .Rprofile
#' # would otherwise shadow ~/.Rprofile entirely)
#' init_project(path = file.path(tempdir(), "project7"),
#'              use_rprofile = TRUE, use_git = FALSE)
#' }

init_project <- function(path,
                         use_renv       = TRUE,
                         use_git        = TRUE,
                         custom_folders = NULL,
                         config         = NULL,
                         open           = FALSE,
                         branding       = "none",
                         uw_branding    = deprecated(),
                         use_readme     = TRUE,
                         use_rprofile   = FALSE) {
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

        # Bound to a local rather than interpolated directly: cli >= 3.4.0
        # reads a `{}` expression starting with a dot as a style name, so
        # `{.file {.project_yml_name()}}` is a parse error rather than a
        # nested call.
        manifest_name <- .project_yml_name()
        manifest_path <- fs::path(path, manifest_name)

        if (fs::file_exists(manifest_path)) {
            cli::cli_abort(c(
                "A {.file {manifest_name}} file already exists in {.path {path}}.",
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
    usethis::create_project(path, open = FALSE)

    # create_project() sets the active usethis project only for its own
    # duration: it uses local_project(path, force = TRUE) internally, which
    # restores the caller's project when it returns with open = FALSE. So by
    # this line the active project is whatever it was before init_project()
    # was called -- typically the package or project the user is working in.
    #
    # Anything below that resolves paths through the active project has to
    # set it again, use_git() above all. Without this, use_git() initializes,
    # stages and commits in the CALLER's repository rather than the project
    # just created, which is destructive and easy to miss because the prompt
    # it raises looks plausible.
    #
    # local_project() is scoped to this function, so the caller's project is
    # restored when init_project() returns. setwd = FALSE because every path
    # used below is absolute and changing the working directory underneath
    # the caller is a side effect nobody asked for.
    usethis::local_project(path, force = TRUE, setwd = FALSE)

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

    # -- 11. Keep the empty folders under version control --------------------
    # git tracks files, not directories, so a scaffolded structure of empty
    # folders survives nothing: the opening commit contains the files at the
    # project root and none of the layout, and a clone arrives with the
    # structure missing. That is also the most common way check_project()
    # would report a folder as failing on a project where nothing is wrong.
    #
    # Runs after everything that might populate a folder, and only writes
    # into folders that are still empty -- assets/ has branding files in it
    # by this point and does not need a placeholder.
    #
    # Unconditional rather than gated on use_git: a project can be
    # git-initialized later, and a handful of empty files is a cheap premium
    # against losing the structure.
    .add_gitkeep(fs::path(path, final_folders))

    # -- 12. Write the project manifest --------------------------------------
    # Records the resolved structure, not the inputs that produced it. This
    # is what check_project() audits against and what containr and submitr
    # read instead of assuming a layout.
    manifest_name <- .project_yml_name()

    .write_project_yml(
        dest        = fs::path(path, manifest_name),
        folders     = final_folders,
        conventions = conventions
    )

    cli::cli_alert_success(
        "Recorded project structure in {.file {manifest_name}}"
    )

    # -- 13. Set up renv -----------------------------------------------------
    # scaffold(), not init(). init() loads the project into the CALLING
    # session -- it repoints .libPaths() at the new project's empty library,
    # so every package the caller had available disappears until they restart
    # R. Its restart argument suppresses the restart, not the activation, and
    # bare = TRUE skips dependency discovery but still loads. scaffold()
    # creates the same infrastructure (renv/library, renv/activate.R,
    # .Rprofile, renv/.gitignore, renv.lock) and leaves the caller's session
    # alone, which is the right semantics when the project being set up is
    # not the one you are working in.
    #
    # Nothing is lost by skipping discovery: the project has no code in it
    # yet, so there is nothing to discover. See the "Dependency discovery and
    # renv" section of this function's documentation.
    if (use_renv) {
        renv::scaffold(project = path)
    }

    # -- 13b. Optionally preserve access to the user's own .Rprofile ---------
    # Meaningful once a project has its own .Rprofile -- which use_renv =
    # TRUE creates above, via renv::scaffold() -- since that file is the
    # only one R reads for this project and otherwise shadows ~/.Rprofile
    # entirely. See the "Personal .Rprofile and renv" section of this
    # function's documentation.
    if (use_rprofile) {
        .add_rprofile(path)
    }

    # -- 14. Initialize git --------------------------------------------------
    # Targets the project set by local_project() above, not the caller's.
    if (use_git) usethis::use_git(message = "initial commit")

    # -- 15. Open the project in RStudio -------------------------------------
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


# -- Helper: preserve access to the user's own .Rprofile ----------------------

#' Preserve access to the user's own `.Rprofile`
#'
#' Internal helper backing [init_project()]'s `use_rprofile`
#' argument. R reads exactly one `.Rprofile` per session: the one in the
#' current working directory if it exists, `~/.Rprofile` only if it does
#' not. `renv::scaffold()` writes a project-level `.Rprofile` containing
#' `source("renv/activate.R")`, so once a project is under renv, whatever
#' aliases, options, or helper functions a user keeps in `~/.Rprofile` stop
#' loading for that project -- silently, since nothing errors.
#'
#' This appends a guarded block to the project's `.Rprofile` (creating the
#' file if `use_renv = FALSE` left none behind) that sources `~/.Rprofile`
#' if it exists, after renv's own activation line so the project library is
#' set up first. The existence check happens at every session start rather
#' than once at project-creation time, so a `~/.Rprofile` written or edited
#' after the project is created is still picked up.
#'
#' @param path A character string. The project root.
#'
#' @return Called for its side effects. Returns `invisible(NULL)`.
#'
#' @keywords internal
.add_rprofile <- function(path) {

    rprofile_path <- fs::path(path, ".Rprofile")

    block <- c(
        "",
        "# Load the user's own .Rprofile, if one exists. A project's own",
        "# .Rprofile (written above by renv::scaffold(), when present) is the",
        "# only one R reads for this project -- ~/.Rprofile is otherwise",
        "# shadowed entirely. init_project(use_rprofile = TRUE) added",
        "# this block so personal aliases, options, and helper functions are",
        "# not silently lost.",
        "if (file.exists(\"~/.Rprofile\")) {",
        "  source(\"~/.Rprofile\")",
        "}"
    )

    existing <- if (fs::file_exists(rprofile_path)) {
        readLines(rprofile_path, warn = FALSE)
    } else {
        character(0)
    }

    writeLines(c(existing, block), rprofile_path)

    invisible(NULL)
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
