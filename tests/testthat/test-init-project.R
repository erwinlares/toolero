test_that("init_project() creates the standard folder structure", {
    tmp <- file.path(tempdir(), "test-project")
    on.exit(fs::dir_delete(tmp), add = TRUE)

    init_project(tmp, use_renv = FALSE, use_git = FALSE, open = FALSE)

    standard_folders <- c("data", "data-raw", "images", "plots", "results", "scripts", "docs", "R")
    purrr::walk(standard_folders, \(folder) {
        expect_true(fs::dir_exists(file.path(tmp, folder)))
    })
})

test_that("init_project() creates extra folders when provided", {
    tmp <- file.path(tempdir(), "test-project-extra")
    on.exit(fs::dir_delete(tmp), add = TRUE)

    init_project(tmp, use_renv = FALSE, use_git = FALSE, open = FALSE,
                 extra_folders = c("notebooks", "presentations"))

    expect_true(fs::dir_exists(file.path(tmp, "notebooks")))
    expect_true(fs::dir_exists(file.path(tmp, "presentations")))
})

test_that("init_project() does not create extra folders when extra_folders is NULL", {
    tmp <- file.path(tempdir(), "test-project-null")
    on.exit(fs::dir_delete(tmp), add = TRUE)

    init_project(tmp, use_renv = FALSE, use_git = FALSE, open = FALSE)

    expect_false(fs::dir_exists(file.path(tmp, "notebooks")))
})

test_that("init_project() creates a valid project structure", {
    tmp <- file.path(tempdir(), "test-project-rproj")
    on.exit(fs::dir_delete(tmp), add = TRUE)

    init_project(tmp, use_renv = FALSE, use_git = FALSE, open = FALSE)

    expect_true(fs::dir_exists(tmp))
})

test_that("init_project() creates assets/ folder when uw_branding = TRUE", {
    tmp <- file.path(tempdir(), "test-project-branding")
    on.exit(fs::dir_delete(tmp), add = TRUE)

    init_project(tmp, use_renv = FALSE, use_git = FALSE, open = FALSE,
                 uw_branding = TRUE)

    expect_true(fs::dir_exists(file.path(tmp, "assets")))
})

test_that("init_project() copies branding files when uw_branding = TRUE", {
    tmp <- file.path(tempdir(), "test-project-branding-files")
    on.exit(fs::dir_delete(tmp), add = TRUE)

    init_project(tmp, use_renv = FALSE, use_git = FALSE, open = FALSE,
                 uw_branding = TRUE)

    expect_true(fs::file_exists(file.path(tmp, "assets", "styles.css")))
    expect_true(fs::file_exists(file.path(tmp, "assets", "header.html")))
    expect_true(fs::file_exists(file.path(tmp, "assets", "rci-banner.png")))
})

test_that("init_project() does not create assets/ folder when uw_branding = FALSE", {
    tmp <- file.path(tempdir(), "test-project-no-branding")
    on.exit(fs::dir_delete(tmp), add = TRUE)

    init_project(tmp, use_renv = FALSE, use_git = FALSE, open = FALSE,
                 uw_branding = FALSE)

    expect_false(fs::dir_exists(file.path(tmp, "assets")))
})
