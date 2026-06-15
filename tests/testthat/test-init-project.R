# Tests for init_project() and generate_project_config()
# Organized by: standard structure, config file, custom_folders,
#               uw_branding, generate_project_config()

# -- Shared helpers ------------------------------------------------------------

# Standard folders as defined in init_project()
standard_folders <- c(
    "data-raw", "data", "scripts",
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
write_config <- function(root, folders, filename = "test-config.yml") {
    lines <- c(
        "folders:",
        paste0("  - ", folders)
    )
    dest <- fs::path(root, filename)
    writeLines(lines, dest)
    dest
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


# -- 2. Config file ------------------------------------------------------------

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

    # Standard folders that are not in the config should not exist
    absent <- setdiff(standard_folders, "notebooks")
    purrr::walk(absent, \(folder) {
        expect_false(
            fs::dir_exists(fs::path(proj, folder)),
            info = paste("should not exist:", folder)
        )
    })
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


# -- 3. custom_folders ---------------------------------------------------------

test_that("custom_folders adds a new folder to the standard set", {
    proj <- fs::path(tmp, "cst-01")
    init_project(proj, custom_folders = "models",
                 use_renv = FALSE, use_git = FALSE)

    expect_true(fs::dir_exists(fs::path(proj, "models")))
    # Standard folders still present
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

    # models should not be present
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


# -- 4. UW branding ------------------------------------------------------------

test_that("uw_branding = TRUE creates the assets/ directory", {
    proj <- fs::path(tmp, "uw-01")
    init_project(proj, uw_branding = TRUE, use_renv = FALSE, use_git = FALSE)
    expect_true(fs::dir_exists(fs::path(proj, "assets")))
})

test_that("uw_branding = TRUE copies all three branding files", {
    proj <- fs::path(tmp, "uw-02")
    init_project(proj, uw_branding = TRUE, use_renv = FALSE, use_git = FALSE)

    expect_true(fs::file_exists(fs::path(proj, "assets", "styles.css")))
    expect_true(fs::file_exists(fs::path(proj, "assets", "header.html")))
    expect_true(fs::file_exists(fs::path(proj, "assets", "rci-banner.png")))
})

test_that("uw_branding = FALSE does not create assets/", {
    proj <- fs::path(tmp, "uw-03")
    init_project(proj, uw_branding = FALSE, use_renv = FALSE, use_git = FALSE)
    expect_false(fs::dir_exists(fs::path(proj, "assets")))
})


# -- 5. generate_project_config() ----------------------------------------------

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

test_that("generate_project_config() output is usable by init_project()", {
    dest <- generate_project_config("roundtrip.yml", path = tmp,
                                    overwrite = TRUE)
    proj <- fs::path(tmp, "roundtrip-proj")
    init_project(proj, config = dest, use_renv = FALSE, use_git = FALSE)

    # The standard folders baked into the template should all exist
    purrr::walk(standard_folders, \(folder) {
        expect_true(
            fs::dir_exists(fs::path(proj, folder)),
            info = paste("missing:", folder)
        )
    })
})
