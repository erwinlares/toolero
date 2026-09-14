# Tests for init_project() and generate_project_config()
# Organized by: standard structure, project manifest, config file,
#               custom_folders, branding, use_readme, renv,
#               generate_project_config(), internal helpers

# -- Shared helpers ------------------------------------------------------------

# Standard folders as defined in .default_folders()
standard_folders <- c(
    "data-raw", "data", "R", "scripts",
    "output/figures", "output/tables", "reports"
)

# Build a minimal project using plain fs calls only -- no usethis, no
# init_project(). Used wherever a test only needs a directory that looks
# like an existing project without triggering the full init pipeline.
make_project <- function(root, name = "proj") {
    dir <- fs::path(root, name)
    fs::dir_create(dir)
    dir
}

# Write a minimal valid toolero YAML config into a directory.
# Returns the full path to the written file.
write_config <- function(root, folders, filename = "test-config.yml",
                         conventions = NULL) {
    lines <- c(
        "folders:",
        paste0("  - ", folders)
    )
    if (!is.null(conventions)) {
        lines <- c(
            lines,
            "conventions:",
            paste0("  ", names(conventions), ": ", unlist(conventions))
        )
    }
    dest <- fs::path(root, filename)
    writeLines(lines, dest)
    dest
}

# Read the manifest init_project() wrote into a project.
read_manifest <- function(project) {
    yaml::read_yaml(fs::path(project, "_toolero.yml"))
}

# File-level temp dir. Scoped to this test file so helpers that receive it
# as an argument don't evict it when their own call frame exits.
tmp <- withr::local_tempdir()


# -- 1. Standard folder structure ----------------------------------------------

test_that("init_project() creates all standard folders", {
    proj <- fs::path(tmp, "std-01")
    init_project(proj, use_renv = FALSE, use_git = FALSE)

    purrr::walk(standard_folders, \(folder) {
        expect_true(
            fs::dir_exists(fs::path(proj, folder)),
            info = paste("missing:", folder)
        )
    })
})

test_that("init_project() creates R/ as part of the standard set", {
    proj <- fs::path(tmp, "std-02")
    init_project(proj, use_renv = FALSE, use_git = FALSE)

    expect_true(fs::dir_exists(fs::path(proj, "R")))
})

# The .Rproj file is written by usethis::create_project() to the resolved
# symlink path (/private/var/... on macOS), not the /var/... path that
# withr::local_tempdir() returns. Verifying usethis internals is out of
# scope for toolero's test suite -- directory creation is covered by std-01.

test_that("init_project() accepts path as a named argument", {
    proj <- fs::path(tmp, "std-03")
    init_project(path = proj, use_renv = FALSE, use_git = FALSE)
    expect_true(fs::dir_exists(proj))
})

test_that("init_project() invisibly returns the absolute path", {
    proj <- fs::path(tmp, "std-04")
    result <- init_project(proj, use_renv = FALSE, use_git = FALSE)
    expect_equal(result, fs::path_abs(proj))
})

test_that("init_project() creates output/ parent when nested folders are made", {
    proj <- fs::path(tmp, "std-05")
    init_project(proj, use_renv = FALSE, use_git = FALSE)
    expect_true(fs::dir_exists(fs::path(proj, "output")))
})


# -- 2. Project manifest (_toolero.yml) ----------------------------------------

test_that("init_project() writes _toolero.yml at the project root", {
    proj <- fs::path(tmp, "man-01")
    init_project(proj, use_renv = FALSE, use_git = FALSE)

    expect_true(fs::file_exists(fs::path(proj, "_toolero.yml")))
})

test_that("the manifest carries schema_version, folders, and conventions", {
    proj <- fs::path(tmp, "man-02")
    init_project(proj, use_renv = FALSE, use_git = FALSE)

    manifest <- read_manifest(proj)

    expect_equal(manifest[["schema_version"]], 1L)
    expect_true(!is.null(manifest[["folders"]]))
    expect_true(!is.null(manifest[["conventions"]]))
})

test_that("the manifest records the default folder set", {
    proj <- fs::path(tmp, "man-03")
    init_project(proj, use_renv = FALSE, use_git = FALSE)

    expect_equal(
        as.character(unlist(read_manifest(proj)[["folders"]])),
        standard_folders
    )
})

test_that("the manifest records the default conventions", {
    proj <- fs::path(tmp, "man-04")
    init_project(proj, use_renv = FALSE, use_git = FALSE)

    conventions <- read_manifest(proj)[["conventions"]]

    expect_equal(conventions[["output_dir"]], "output")
    expect_equal(conventions[["script_dir"]], "R")
    expect_equal(conventions[["split_dir"]], "data/jobs")
})

test_that("the manifest records the resolved set, not the defaults", {
    proj <- fs::path(tmp, "man-05")
    init_project(proj,
                 custom_folders = c("models", "-reports"),
                 use_renv = FALSE, use_git = FALSE)

    folders <- as.character(unlist(read_manifest(proj)[["folders"]]))

    expect_true("models" %in% folders)
    expect_false("reports" %in% folders)
})

test_that("the manifest records a config-derived folder set", {
    proj        <- fs::path(tmp, "man-06")
    custom_set  <- c("raw", "processed", "notebooks")
    config_path <- write_config(tmp, custom_set, "man-06.yml")

    init_project(proj, config = config_path, use_renv = FALSE, use_git = FALSE)

    expect_equal(
        as.character(unlist(read_manifest(proj)[["folders"]])),
        custom_set
    )
})

test_that("conventions declared in a config reach the manifest", {
    proj        <- fs::path(tmp, "man-07")
    config_path <- write_config(
        tmp, c("data", "results"), "man-07.yml",
        conventions = list(output_dir = "results")
    )

    init_project(proj, config = config_path, use_renv = FALSE, use_git = FALSE)

    conventions <- read_manifest(proj)[["conventions"]]

    expect_equal(conventions[["output_dir"]], "results")
    # unspecified keys fall back to the defaults
    expect_equal(conventions[["script_dir"]], "R")
})

test_that("an unrecognized convention key warns and is dropped", {
    proj        <- fs::path(tmp, "man-08")
    config_path <- write_config(
        tmp, c("data"), "man-08.yml",
        conventions = list(nonsense_dir = "somewhere")
    )

    expect_warning(
        init_project(proj, config = config_path,
                     use_renv = FALSE, use_git = FALSE),
        regexp = "unrecognized convention"
    )

    expect_null(read_manifest(proj)[["conventions"]][["nonsense_dir"]])
})

test_that("the manifest records assets/ when branding is enabled", {
    proj <- fs::path(tmp, "man-09")
    init_project(proj, branding = TRUE, use_renv = FALSE, use_git = FALSE)

    expect_true("assets" %in% as.character(unlist(read_manifest(proj)[["folders"]])))
})

test_that("the manifest omits assets/ when branding is off", {
    proj <- fs::path(tmp, "man-10")
    init_project(proj, branding = "none", use_renv = FALSE, use_git = FALSE)

    expect_false("assets" %in% as.character(unlist(read_manifest(proj)[["folders"]])))
})

test_that("a manifest written by init_project() is usable as a config", {
    source_proj <- fs::path(tmp, "man-11a")
    init_project(source_proj,
                 custom_folders = "models",
                 use_renv = FALSE, use_git = FALSE)

    target_proj <- fs::path(tmp, "man-11b")
    init_project(target_proj,
                 config = fs::path(source_proj, "_toolero.yml"),
                 use_renv = FALSE, use_git = FALSE)

    expect_equal(
        as.character(unlist(read_manifest(source_proj)[["folders"]])),
        as.character(unlist(read_manifest(target_proj)[["folders"]]))
    )
    expect_true(fs::dir_exists(fs::path(target_proj, "models")))
})

test_that("init_project() refuses to overwrite an existing manifest", {
    proj <- make_project(tmp, "man-12")
    writeLines("schema_version: 1", fs::path(proj, "_toolero.yml"))

    expect_error(
        init_project(proj, use_readme = FALSE, use_renv = FALSE, use_git = FALSE),
        regexp = "already exists"
    )
})


# -- 3. Config file ------------------------------------------------------------

test_that("config overrides the standard structure with custom folders", {
    proj        <- fs::path(tmp, "cfg-01")
    custom_set  <- c("raw", "processed", "notebooks")
    config_path <- write_config(tmp, custom_set, "cfg-01.yml")

    init_project(proj, config = config_path, use_renv = FALSE, use_git = FALSE)

    purrr::walk(custom_set, \(folder) {
        expect_true(
            fs::dir_exists(fs::path(proj, folder)),
            info = paste("missing:", folder)
        )
    })
})

test_that("config suppresses the standard folders entirely", {
    proj        <- fs::path(tmp, "cfg-02")
    config_path <- write_config(tmp, c("notebooks"), "cfg-02.yml")

    init_project(proj, config = config_path, use_renv = FALSE, use_git = FALSE)

    # R/ is the one standard folder init_project() does not create itself.
    # usethis::create_project() calls use_directory("R") unconditionally, so
    # it is present in every project whatever the config says. Covered by
    # the test below rather than excluded silently here.
    absent <- setdiff(standard_folders, c("notebooks", "R"))
    purrr::walk(absent, \(folder) {
        expect_false(
            fs::dir_exists(fs::path(proj, folder)),
            info = paste("should not exist:", folder)
        )
    })
})

test_that("R/ survives a config that does not list it", {
    proj        <- fs::path(tmp, "cfg-02b")
    config_path <- write_config(tmp, c("notebooks"), "cfg-02b.yml")

    init_project(proj, config = config_path, use_renv = FALSE, use_git = FALSE)

    # Created by usethis, not by toolero, so neither config nor
    # custom_folders can suppress it.
    expect_true(fs::dir_exists(fs::path(proj, "R")))

    # It is not part of the resolved set, so it is not in the manifest and
    # gets no .gitkeep. A reader comparing the manifest against the
    # directory listing should find R/ in one and not the other.
    expect_false("R" %in% as.character(unlist(read_manifest(proj)[["folders"]])))
    expect_false(fs::file_exists(fs::path(proj, "R", ".gitkeep")))
})

test_that("custom_folders cannot suppress R/ either", {
    proj <- fs::path(tmp, "cfg-02c")

    init_project(proj, custom_folders = "-R", use_renv = FALSE, use_git = FALSE)

    expect_true(fs::dir_exists(fs::path(proj, "R")))
    expect_false("R" %in% as.character(unlist(read_manifest(proj)[["folders"]])))
})

test_that("a missing config file raises an error", {
    proj <- fs::path(tmp, "cfg-03")
    expect_error(
        init_project(proj, config = fs::path(tmp, "no-such-file.yml"),
                     use_renv = FALSE, use_git = FALSE),
        class = "rlang_error"
    )
})

test_that("a config file with no folders key raises an error", {
    bad_config <- fs::path(tmp, "bad-config.yml")
    writeLines("title: oops", bad_config)
    proj <- fs::path(tmp, "cfg-04")

    expect_error(
        init_project(proj, config = bad_config, use_renv = FALSE, use_git = FALSE),
        class = "rlang_error"
    )
})

test_that("config supports nested folder paths", {
    proj        <- fs::path(tmp, "cfg-05")
    config_path <- write_config(tmp, c("data", "output/figures", "output/tables"),
                                "cfg-05.yml")

    init_project(proj, config = config_path, use_renv = FALSE, use_git = FALSE)

    expect_true(fs::dir_exists(fs::path(proj, "output", "figures")))
    expect_true(fs::dir_exists(fs::path(proj, "output", "tables")))
})

test_that("a rejected config creates no project directory", {
    proj <- fs::path(tmp, "cfg-06")

    expect_error(
        init_project(proj, config = fs::path(tmp, "no-such-file.yml"),
                     use_renv = FALSE, use_git = FALSE)
    )

    expect_false(fs::dir_exists(proj))
})

test_that("a config with a blank folder name raises an error", {
    bad_config <- fs::path(tmp, "blank-folder.yml")
    writeLines(c("folders:", "  - data", "  - ''"), bad_config)
    proj <- fs::path(tmp, "cfg-07")

    expect_error(
        init_project(proj, config = bad_config, use_renv = FALSE, use_git = FALSE),
        class = "rlang_error"
    )
})

test_that("a config with duplicate folders is deduplicated with a message", {
    config_path <- write_config(tmp, c("data", "data", "scripts"), "cfg-08.yml")
    proj        <- fs::path(tmp, "cfg-08")

    expect_message(
        init_project(proj, config = config_path,
                     use_renv = FALSE, use_git = FALSE),
        regexp = "duplicate folder"
    )

    expect_equal(
        as.character(unlist(read_manifest(proj)[["folders"]])),
        c("data", "scripts")
    )
})

test_that("a config declaring a newer schema_version warns but is read", {
    future_config <- fs::path(tmp, "future.yml")
    writeLines(c("schema_version: 99", "folders:", "  - data"), future_config)
    proj <- fs::path(tmp, "cfg-09")

    expect_warning(
        init_project(proj, config = future_config,
                     use_renv = FALSE, use_git = FALSE),
        regexp = "schema version"
    )

    expect_true(fs::dir_exists(fs::path(proj, "data")))
})


# -- 4. custom_folders ---------------------------------------------------------

test_that("custom_folders adds a new folder to the standard set", {
    proj <- fs::path(tmp, "cst-01")
    init_project(proj, custom_folders = "models",
                 use_renv = FALSE, use_git = FALSE)

    expect_true(fs::dir_exists(fs::path(proj, "models")))
    expect_true(fs::dir_exists(fs::path(proj, "scripts")))
})

test_that("custom_folders with '-' suppresses a standard folder", {
    proj <- fs::path(tmp, "cst-02")
    init_project(proj, custom_folders = "-output/figures",
                 use_renv = FALSE, use_git = FALSE)

    expect_false(fs::dir_exists(fs::path(proj, "output", "figures")))
})

test_that("removing output/figures leaves output/tables intact", {
    proj <- fs::path(tmp, "cst-03")
    init_project(proj, custom_folders = "-output/figures",
                 use_renv = FALSE, use_git = FALSE)

    expect_true(fs::dir_exists(fs::path(proj, "output", "tables")))
})

test_that("removing output/figures leaves output/ parent intact", {
    proj <- fs::path(tmp, "cst-04")
    init_project(proj, custom_folders = "-output/figures",
                 use_renv = FALSE, use_git = FALSE)

    expect_true(fs::dir_exists(fs::path(proj, "output")))
})

test_that("removing both nested folders still leaves output/ parent", {
    proj <- fs::path(tmp, "cst-05")
    init_project(proj,
                 custom_folders = c("-output/figures", "-output/tables"),
                 use_renv = FALSE, use_git = FALSE)

    expect_false(fs::dir_exists(fs::path(proj, "output", "figures")))
    expect_false(fs::dir_exists(fs::path(proj, "output", "tables")))
    expect_true(fs::dir_exists(fs::path(proj, "output")))
})

test_that("custom_folders can add and remove in the same call", {
    proj <- fs::path(tmp, "cst-06")
    init_project(proj,
                 custom_folders = c("models", "-output/figures"),
                 use_renv = FALSE, use_git = FALSE)

    expect_true(fs::dir_exists(fs::path(proj, "models")))
    expect_false(fs::dir_exists(fs::path(proj, "output", "figures")))
})

test_that("custom_folders duplicate emits a message and folder still exists", {
    proj <- fs::path(tmp, "cst-07")
    expect_message(
        init_project(proj, custom_folders = "scripts",
                     use_renv = FALSE, use_git = FALSE),
        regexp = "already exist"
    )
    expect_true(fs::dir_exists(fs::path(proj, "scripts")))
})

test_that("custom_folders removal of non-existent folder emits a warning", {
    proj <- fs::path(tmp, "cst-08")
    expect_warning(
        init_project(proj, custom_folders = "-nonexistent",
                     use_renv = FALSE, use_git = FALSE),
        regexp = "ignored"
    )
})

test_that("custom_folders NULL creates no extra folders beyond standard", {
    proj <- fs::path(tmp, "cst-09")
    init_project(proj, custom_folders = NULL,
                 use_renv = FALSE, use_git = FALSE)

    created <- fs::dir_ls(proj, type = "directory", recurse = TRUE) |>
        fs::path_rel(proj) |>
        as.character()

    expect_false("models" %in% created)
})

test_that("custom_folders is applied on top of a config-derived set", {
    proj        <- fs::path(tmp, "cst-10")
    config_path <- write_config(tmp, c("data", "scripts", "output/figures"),
                                "cst-10.yml")

    init_project(proj,
                 config         = config_path,
                 custom_folders = c("models", "-output/figures"),
                 use_renv       = FALSE,
                 use_git        = FALSE)

    expect_true(fs::dir_exists(fs::path(proj, "models")))
    expect_false(fs::dir_exists(fs::path(proj, "output", "figures")))
    expect_true(fs::dir_exists(fs::path(proj, "scripts")))
})

test_that("a config-derived removal does not resurrect the parent folder", {
    proj        <- fs::path(tmp, "cst-11")
    config_path <- write_config(tmp, c("data", "output/figures"), "cst-11.yml")

    init_project(proj,
                 config         = config_path,
                 custom_folders = "-output/figures",
                 use_renv       = FALSE,
                 use_git        = FALSE)

    # A config is a complete statement of the structure, so the removal is
    # honored literally -- unlike the same removal against the default set,
    # which preserves output/ (see cst-04).
    expect_false(fs::dir_exists(fs::path(proj, "output")))
    expect_false("output" %in% as.character(unlist(read_manifest(proj)[["folders"]])))
})


# -- 5. branding ---------------------------------------------------------------

# Standardized asset filenames -- same set regardless of branding mode
standard_assets <- c("logo.png", "favicon.png", "header.html",
                     "footer.html", "styles.css")

test_that("branding = 'none' does not create assets/", {
    proj <- fs::path(tmp, "br-01")
    init_project(proj, branding = "none", use_renv = FALSE, use_git = FALSE)
    expect_false(fs::dir_exists(fs::path(proj, "assets")))
})

test_that("branding = FALSE does not create assets/", {
    proj <- fs::path(tmp, "br-02")
    init_project(proj, branding = FALSE, use_renv = FALSE, use_git = FALSE)
    expect_false(fs::dir_exists(fs::path(proj, "assets")))
})

test_that("branding = TRUE creates the assets/ directory", {
    proj <- fs::path(tmp, "br-03")
    init_project(proj, branding = TRUE, use_renv = FALSE, use_git = FALSE)
    expect_true(fs::dir_exists(fs::path(proj, "assets")))
})

test_that("branding = TRUE copies all five standardized generic files", {
    proj <- fs::path(tmp, "br-04")
    init_project(proj, branding = TRUE, use_renv = FALSE, use_git = FALSE)

    purrr::walk(standard_assets, \(f) {
        expect_true(
            fs::file_exists(fs::path(proj, "assets", f)),
            info = paste("missing:", f)
        )
    })
})

test_that("branding = 'uw-madison' creates the assets/ directory", {
    proj <- fs::path(tmp, "br-05")
    init_project(proj, branding = "uw-madison", use_renv = FALSE, use_git = FALSE)
    expect_true(fs::dir_exists(fs::path(proj, "assets")))
})

test_that("branding = 'uw-madison' copies all five standardized files", {
    proj <- fs::path(tmp, "br-06")
    init_project(proj, branding = "uw-madison", use_renv = FALSE, use_git = FALSE)

    purrr::walk(standard_assets, \(f) {
        expect_true(
            fs::file_exists(fs::path(proj, "assets", f)),
            info = paste("missing:", f)
        )
    })
})

test_that("branding = 'uw-madison' and branding = TRUE produce identically named files", {
    proj_uw      <- fs::path(tmp, "br-07a")
    proj_generic <- fs::path(tmp, "br-07b")
    init_project(proj_uw,      branding = "uw-madison", use_renv = FALSE, use_git = FALSE)
    init_project(proj_generic, branding = TRUE,          use_renv = FALSE, use_git = FALSE)

    uw_files      <- fs::path_file(fs::dir_ls(fs::path(proj_uw,      "assets")))
    generic_files <- fs::path_file(fs::dir_ls(fs::path(proj_generic, "assets")))

    expect_equal(sort(uw_files), sort(generic_files))
})

test_that("branding rejects invalid values with an informative error", {
    proj <- fs::path(tmp, "br-08")
    expect_error(
        init_project(proj, branding = "rci", use_renv = FALSE, use_git = FALSE),
        class = "rlang_error"
    )
})

test_that("init_project() refuses to overwrite existing branding files", {
    proj <- make_project(tmp, "br-14")
    fs::dir_create(fs::path(proj, "assets"))
    writeLines("custom", fs::path(proj, "assets", "styles.css"))

    expect_error(
        init_project(proj, branding = TRUE, use_readme = FALSE,
                     use_renv = FALSE, use_git = FALSE),
        regexp = "already exist"
    )

    # the caller's own file is untouched
    expect_equal(readLines(fs::path(proj, "assets", "styles.css")), "custom")
})

# -- deprecated uw_branding ----------------------------------------------------

test_that("uw_branding = TRUE emits a deprecation warning", {
    proj <- fs::path(tmp, "br-09")
    expect_warning(
        init_project(proj, uw_branding = TRUE, use_renv = FALSE, use_git = FALSE),
        regexp = "uw_branding"
    )
})

test_that("uw_branding = TRUE maps to 'uw-madison' -- copies all five standardized files", {
    proj <- fs::path(tmp, "br-10")
    suppressWarnings(
        init_project(proj, uw_branding = TRUE, use_renv = FALSE, use_git = FALSE)
    )

    purrr::walk(standard_assets, \(f) {
        expect_true(
            fs::file_exists(fs::path(proj, "assets", f)),
            info = paste("missing:", f)
        )
    })
})

test_that("uw_branding = TRUE does not map to generic -- logo.png is UW content", {
    proj_deprecated <- fs::path(tmp, "br-11a")
    proj_generic    <- fs::path(tmp, "br-11b")

    suppressWarnings(
        init_project(proj_deprecated, uw_branding = TRUE,
                     use_renv = FALSE, use_git = FALSE)
    )
    init_project(proj_generic, branding = TRUE,
                 use_renv = FALSE, use_git = FALSE)

    # UW and generic logos should differ in content -- same filename,
    # different bytes -- confirming the deprecation mapping went to
    # "uw-madison" rather than silently falling back to generic.
    uw_logo      <- readBin(fs::path(proj_deprecated, "assets", "logo.png"),
                            "raw", n = 1000L)
    generic_logo <- readBin(fs::path(proj_generic,    "assets", "logo.png"),
                            "raw", n = 1000L)

    expect_false(identical(uw_logo, generic_logo))
})

test_that("uw_branding = FALSE emits a deprecation warning", {
    proj <- fs::path(tmp, "br-12")
    expect_warning(
        init_project(proj, uw_branding = FALSE, use_renv = FALSE, use_git = FALSE),
        regexp = "uw_branding"
    )
})

test_that("uw_branding = FALSE maps to 'none' -- no assets/ created", {
    proj <- fs::path(tmp, "br-13")
    suppressWarnings(
        init_project(proj, uw_branding = FALSE, use_renv = FALSE, use_git = FALSE)
    )
    expect_false(fs::dir_exists(fs::path(proj, "assets")))
})


# -- 6. use_readme ---------------------------------------------------------

test_that("use_readme defaults to TRUE -- README.md is created when not supplied", {
    proj <- fs::path(tmp, "rm-01")
    init_project(proj, use_renv = FALSE, use_git = FALSE)

    expect_true(fs::file_exists(fs::path(proj, "README.md")))
})

test_that("use_readme = TRUE creates README.md at the project's top level", {
    proj <- fs::path(tmp, "rm-02")
    init_project(proj, use_readme = TRUE, use_renv = FALSE, use_git = FALSE)

    expect_true(fs::file_exists(fs::path(proj, "README.md")))
    expect_false(fs::file_exists(fs::path(proj, "README.txt")))
})

test_that("use_readme = FALSE creates no README file", {
    proj <- fs::path(tmp, "rm-03")
    init_project(proj, use_readme = FALSE, use_renv = FALSE, use_git = FALSE)

    expect_false(fs::file_exists(fs::path(proj, "README.md")))
    expect_false(fs::file_exists(fs::path(proj, "README.txt")))
})

test_that("use_readme = 'plain' creates README.txt, not README.md", {
    proj <- fs::path(tmp, "rm-04")
    init_project(proj, use_readme = "plain", use_renv = FALSE, use_git = FALSE)

    expect_true(fs::file_exists(fs::path(proj, "README.txt")))
    expect_false(fs::file_exists(fs::path(proj, "README.md")))
})

test_that("README.md content matches the toolero template exactly", {
    proj <- fs::path(tmp, "rm-05")
    init_project(proj, use_readme = TRUE, use_renv = FALSE, use_git = FALSE)

    template <- system.file("templates", "readme-template.md", package = "toolero")
    expect_identical(
        readLines(fs::path(proj, "README.md")),
        readLines(template)
    )
})

test_that("README.txt content matches the toolero template exactly", {
    proj <- fs::path(tmp, "rm-06")
    init_project(proj, use_readme = "plain", use_renv = FALSE, use_git = FALSE)

    template <- system.file("templates", "readme-template.md", package = "toolero")
    expect_identical(
        readLines(fs::path(proj, "README.txt")),
        readLines(template)
    )
})

test_that("README.md and README.txt carry identical content -- only the extension differs", {
    proj_md  <- fs::path(tmp, "rm-07a")
    proj_txt <- fs::path(tmp, "rm-07b")
    init_project(proj_md,  use_readme = TRUE,    use_renv = FALSE, use_git = FALSE)
    init_project(proj_txt, use_readme = "plain", use_renv = FALSE, use_git = FALSE)

    expect_identical(
        readLines(fs::path(proj_md,  "README.md")),
        readLines(fs::path(proj_txt, "README.txt"))
    )
})

test_that("use_readme rejects invalid values with an informative error", {
    proj <- fs::path(tmp, "rm-08")
    expect_error(
        init_project(proj, use_readme = "text", use_renv = FALSE, use_git = FALSE),
        class = "rlang_error"
    )
})

test_that("init_project() errors informatively when README.md already exists at the destination", {
    proj <- make_project(tmp, "rm-09")
    writeLines("pre-existing", fs::path(proj, "README.md"))

    expect_error(
        init_project(proj, use_readme = TRUE, use_renv = FALSE, use_git = FALSE),
        regexp = "already exists"
    )
})

test_that("init_project() errors informatively when README.txt already exists at the destination", {
    proj <- make_project(tmp, "rm-10")
    writeLines("pre-existing", fs::path(proj, "README.txt"))

    expect_error(
        init_project(proj, use_readme = "plain", use_renv = FALSE, use_git = FALSE),
        regexp = "already exists"
    )
})

test_that("README detection matches check_project() across casing and extension", {
    variants <- c("readme.txt", "ReadMe.MD", "README", "readme.org")

    for (i in seq_along(variants)) {
        proj <- make_project(tmp, paste0("rm-11-", i))
        writeLines("pre-existing", fs::path(proj, variants[i]))

        expect_error(
            init_project(proj, use_readme = TRUE,
                         use_renv = FALSE, use_git = FALSE),
            regexp = "already exists",
            info   = variants[i]
        )
    }
})

test_that("a file merely starting with readme does not block the README", {
    proj <- make_project(tmp, "rm-12")
    writeLines("not a readme", fs::path(proj, "readme-old.md"))

    init_project(proj, use_readme = TRUE, use_renv = FALSE, use_git = FALSE)

    expect_true(fs::file_exists(fs::path(proj, "README.md")))
})

test_that("use_readme = FALSE ignores an existing README", {
    proj <- make_project(tmp, "rm-13")
    writeLines("pre-existing", fs::path(proj, "README.md"))

    expect_no_error(
        init_project(proj, use_readme = FALSE,
                     use_renv = FALSE, use_git = FALSE)
    )
})

test_that("a rejected call leaves no scaffolding behind", {
    proj <- make_project(tmp, "rm-14")
    writeLines("pre-existing", fs::path(proj, "README.md"))

    expect_error(
        init_project(proj, use_readme = TRUE, use_renv = FALSE, use_git = FALSE)
    )

    # preconditions are checked before anything is created
    expect_false(fs::file_exists(fs::path(proj, "_toolero.yml")))
    expect_false(fs::dir_exists(fs::path(proj, "data-raw")))
    expect_length(fs::dir_ls(proj, glob = "*.Rproj"), 0L)
})


# -- 7. renv -------------------------------------------------------------------

test_that("init_project() no longer writes a .renvignore", {
    # renv::scaffold() is mocked so the test stays fast. What is being
    # asserted is toolero's own behavior around the call, not renv's.
    local_mocked_bindings(
        scaffold = function(...) invisible(NULL),
        .package = "renv"
    )

    proj <- fs::path(tmp, "renv-01")
    init_project(proj, use_renv = TRUE, use_git = FALSE)

    expect_false(fs::file_exists(fs::path(proj, ".renvignore")))
})

test_that("init_project() uses renv::scaffold(), not renv::init()", {
    # renv::init() loads the new project into the CALLING session, repointing
    # .libPaths() at an almost-empty library. scaffold() does not.
    called <- character(0)

    local_mocked_bindings(
        scaffold = function(...) {
            called <<- c(called, "scaffold")
            invisible(NULL)
        },
        init = function(...) {
            called <<- c(called, "init")
            invisible(NULL)
        },
        .package = "renv"
    )

    proj <- fs::path(tmp, "renv-04")
    init_project(proj, use_renv = TRUE, use_git = FALSE)

    expect_equal(called, "scaffold")
})

test_that("init_project() leaves the caller's library paths alone", {
    # The regression this guards against: renv::init() activated the new
    # project in the calling session, so every package the caller had
    # available disappeared until they restarted R.
    skip_on_cran()

    before <- .libPaths()

    proj <- fs::path(tmp, "renv-03")
    init_project(proj, use_renv = TRUE, use_git = FALSE)

    expect_equal(.libPaths(), before)
})

test_that("use_renv = FALSE creates no renv scaffolding", {
    proj <- fs::path(tmp, "renv-02")
    init_project(proj, use_renv = FALSE, use_git = FALSE)

    expect_false(fs::file_exists(fs::path(proj, ".renvignore")))
    expect_false(fs::dir_exists(fs::path(proj, "renv")))
})


# -- 8. generate_project_config() ----------------------------------------------

test_that("generate_project_config() creates a file at the given path", {
    dest <- generate_project_config("test-config.yml", path = tmp,
                                    overwrite = TRUE)
    expect_true(fs::file_exists(dest))
})

test_that("generate_project_config() returns the destination path invisibly", {
    dest <- generate_project_config("return-test.yml", path = tmp,
                                    overwrite = TRUE)
    expect_equal(dest, fs::path_abs(fs::path(tmp, "return-test.yml")))
})

test_that("generate_project_config() errors if filename is missing", {
    expect_error(
        generate_project_config(path = tmp),
        class = "rlang_error"
    )
})

test_that("generate_project_config() errors if file exists and overwrite = FALSE", {
    generate_project_config("overwrite-test.yml", path = tmp, overwrite = TRUE)
    expect_error(
        generate_project_config("overwrite-test.yml", path = tmp,
                                overwrite = FALSE),
        class = "rlang_error"
    )
})

test_that("generate_project_config() overwrites when overwrite = TRUE", {
    generate_project_config("ow-true.yml", path = tmp, overwrite = TRUE)
    expect_no_error(
        generate_project_config("ow-true.yml", path = tmp, overwrite = TRUE)
    )
})

test_that("generate_project_config() normalizes extension to .yml", {
    dest <- generate_project_config("no-extension", path = tmp, overwrite = TRUE)
    expect_equal(fs::path_ext(dest), "yml")
})

test_that("generate_project_config() produces valid YAML with a folders key", {
    dest <- generate_project_config("valid-yaml.yml", path = tmp,
                                    overwrite = TRUE)
    parsed <- yaml::read_yaml(dest)
    expect_true(!is.null(parsed[["folders"]]))
    expect_true(length(parsed[["folders"]]) > 0L)
})

test_that("generate_project_config() writes the same schema as the manifest", {
    dest   <- generate_project_config("schema.yml", path = tmp, overwrite = TRUE)
    parsed <- yaml::read_yaml(dest)

    expect_equal(parsed[["schema_version"]], 1L)
    expect_equal(as.character(unlist(parsed[["folders"]])), standard_folders)
    expect_equal(parsed[["conventions"]][["output_dir"]], "output")
    expect_equal(parsed[["conventions"]][["script_dir"]], "R")
    expect_equal(parsed[["conventions"]][["split_dir"]], "data/jobs")
})

test_that("generate_project_config() output matches what init_project() records", {
    dest <- generate_project_config("parity.yml", path = tmp, overwrite = TRUE)
    proj <- fs::path(tmp, "parity-proj")
    init_project(proj, use_renv = FALSE, use_git = FALSE)

    from_generator <- yaml::read_yaml(dest)
    from_manifest  <- read_manifest(proj)

    expect_equal(from_generator[["folders"]],     from_manifest[["folders"]])
    expect_equal(from_generator[["conventions"]], from_manifest[["conventions"]])
})

test_that("generate_project_config() retains its explanatory comments", {
    dest  <- generate_project_config("comments.yml", path = tmp, overwrite = TRUE)
    lines <- readLines(dest)

    expect_true(any(grepl("^# toolero project configuration", lines)))
    expect_true(any(grepl("check_project", lines, fixed = TRUE)))
})

test_that("generate_project_config() output is usable by init_project()", {
    dest <- generate_project_config("roundtrip.yml", path = tmp,
                                    overwrite = TRUE)
    proj <- fs::path(tmp, "roundtrip-proj")
    init_project(proj, config = dest, use_renv = FALSE, use_git = FALSE)

    purrr::walk(standard_folders, \(folder) {
        expect_true(
            fs::dir_exists(fs::path(proj, folder)),
            info = paste("missing:", folder)
        )
    })
})


# -- 9. Internal helpers -------------------------------------------------------

test_that(".default_folders() and .default_conventions() are stable", {
    expect_equal(.default_folders(), standard_folders)
    expect_named(.default_conventions(),
                 c("output_dir", "script_dir", "split_dir"))
})

test_that(".substitute_block() replaces exactly one placeholder line", {
    template <- c("a:", "{{x}}", "b:")
    expect_equal(
        .substitute_block(template, "{{x}}", c("  - one", "  - two")),
        c("a:", "  - one", "  - two", "b:")
    )
})

test_that(".substitute_block() errors when the placeholder is missing", {
    expect_error(
        .substitute_block(c("a:", "b:"), "{{x}}", "  - one"),
        class = "rlang_error"
    )
})

test_that(".find_readme() returns NULL for a directory with none", {
    dir <- make_project(tmp, "fr-01")
    expect_null(.find_readme(dir))
})

test_that(".find_readme() returns NULL for a non-existent directory", {
    expect_null(.find_readme(fs::path(tmp, "no-such-directory")))
})

test_that(".find_readme() matches across casing and extension", {
    variants <- c("README.md", "readme", "Readme.pdf", "README.tex")

    for (i in seq_along(variants)) {
        dir <- make_project(tmp, paste0("fr-02-", i))
        writeLines("", fs::path(dir, variants[i]))

        expect_equal(
            fs::path_file(.find_readme(dir)),
            variants[i],
            info = variants[i]
        )
    }
})

test_that(".find_readme() ignores a directory named readme", {
    dir <- make_project(tmp, "fr-03")
    fs::dir_create(fs::path(dir, "readme"))
    expect_null(.find_readme(dir))
})

test_that(".find_readme() ignores a double-extension readme", {
    dir <- make_project(tmp, "fr-04")
    writeLines("", fs::path(dir, "readme.tar.gz"))
    expect_null(.find_readme(dir))
})

test_that(".package_template() errors informatively for a missing template", {
    expect_error(
        .package_template("no-such-template.yml"),
        regexp = "no-such-template.yml"
    )
})

test_that(".package_template() finds the project manifest template", {
    expect_true(fs::file_exists(.package_template("_toolero.yml")))
})


# -- 10. The active usethis project --------------------------------------------

test_that("use_git() operates on the new project, not the caller's", {
    # The regression this guards against: usethis::create_project() restores
    # the caller's active project when it returns, so use_git() ran against
    # the calling session's repository -- initializing, staging and committing
    # there instead of in the project just created.
    seen <- NULL

    local_mocked_bindings(
        use_git = function(...) {
            seen <<- usethis::proj_get()
            invisible(TRUE)
        },
        .package = "usethis"
    )

    proj <- fs::path(tmp, "git-01")
    init_project(proj, use_renv = FALSE, use_git = TRUE)

    # path_real() resolves the /var -> /private/var symlink on macOS
    expect_equal(fs::path_real(seen), fs::path_real(proj))
})

test_that("init_project() restores the caller's active project", {
    before <- tryCatch(usethis::proj_get(), error = function(e) NULL)

    proj <- fs::path(tmp, "git-02")
    init_project(proj, use_renv = FALSE, use_git = FALSE)

    after <- tryCatch(usethis::proj_get(), error = function(e) NULL)

    expect_equal(before, after)
})

test_that("the caller's active project is restored even when the call fails", {
    before <- tryCatch(usethis::proj_get(), error = function(e) NULL)

    proj <- make_project(tmp, "git-03")
    writeLines("pre-existing", fs::path(proj, "README.md"))

    expect_error(
        init_project(proj, use_readme = TRUE, use_renv = FALSE, use_git = FALSE)
    )

    after <- tryCatch(usethis::proj_get(), error = function(e) NULL)

    expect_equal(before, after)
})


# -- 11. .gitkeep in empty folders ---------------------------------------------

test_that("every empty scaffolded folder gets a .gitkeep", {
    proj <- fs::path(tmp, "keep-01")
    init_project(proj, use_renv = FALSE, use_git = FALSE)

    purrr::walk(standard_folders, \(folder) {
        expect_true(
            fs::file_exists(fs::path(proj, folder, ".gitkeep")),
            info = paste("missing .gitkeep in:", folder)
        )
    })
})

test_that(".gitkeep is written for folders added via custom_folders", {
    proj <- fs::path(tmp, "keep-02")
    init_project(proj, custom_folders = "models",
                 use_renv = FALSE, use_git = FALSE)

    expect_true(fs::file_exists(fs::path(proj, "models", ".gitkeep")))
})

test_that("assets/ gets no .gitkeep because branding files fill it", {
    proj <- fs::path(tmp, "keep-03")
    init_project(proj, branding = TRUE, use_renv = FALSE, use_git = FALSE)

    expect_true(fs::dir_exists(fs::path(proj, "assets")))
    expect_false(fs::file_exists(fs::path(proj, "assets", ".gitkeep")))
})

test_that("a parent folder holding subfolders gets no .gitkeep", {
    proj <- fs::path(tmp, "keep-04")
    init_project(proj, custom_folders = "-output/figures",
                 use_renv = FALSE, use_git = FALSE)

    # output/ is preserved as a parent and holds output/tables, so it is
    # tracked through its child rather than through a placeholder
    expect_true(fs::dir_exists(fs::path(proj, "output")))
    expect_false(fs::file_exists(fs::path(proj, "output", ".gitkeep")))
    expect_true(fs::file_exists(fs::path(proj, "output", "tables", ".gitkeep")))
})

test_that("an emptied parent folder does get a .gitkeep", {
    proj <- fs::path(tmp, "keep-05")
    init_project(proj,
                 custom_folders = c("-output/figures", "-output/tables"),
                 use_renv = FALSE, use_git = FALSE)

    expect_true(fs::file_exists(fs::path(proj, "output", ".gitkeep")))
})

test_that("a suppressed folder gets neither a directory nor a .gitkeep", {
    proj <- fs::path(tmp, "keep-06")
    init_project(proj, custom_folders = "-reports",
                 use_renv = FALSE, use_git = FALSE)

    expect_false(fs::dir_exists(fs::path(proj, "reports")))
    expect_false(fs::file_exists(fs::path(proj, "reports", ".gitkeep")))
})

test_that(".gitkeep files are empty", {
    proj <- fs::path(tmp, "keep-07")
    init_project(proj, use_renv = FALSE, use_git = FALSE)

    expect_equal(
        as.numeric(fs::file_info(fs::path(proj, "data", ".gitkeep"))$size),
        0
    )
})

test_that(".add_gitkeep() ignores directories that do not exist", {
    expect_equal(
        .add_gitkeep(fs::path(tmp, "no-such-directory")),
        character(0)
    )
})

test_that(".add_gitkeep() skips a directory holding only a hidden file", {
    dir <- make_project(tmp, "keep-08")
    fs::file_create(fs::path(dir, ".hidden"))

    expect_equal(.add_gitkeep(dir), character(0))
    expect_false(fs::file_exists(fs::path(dir, ".gitkeep")))
})
