# tests/testthat/test-utils-project.R
#
# Shared internals from R/utils-project.R. The helpers that back
# init_project() and generate_project_config() are exercised from
# test-init-project.R, where the functions that use them live; this file
# covers .ensure_directory(), which has more than one caller and so belongs
# with the file it now lives in rather than with any one of them.


# -- .ensure_directory() -------------------------------------------------------

test_that(".ensure_directory() creates a missing directory", {
    root   <- withr::local_tempdir()
    target <- fs::path(root, "nested", "deeper", "file.rds")

    suppressMessages(.ensure_directory(target))

    expect_true(fs::dir_exists(fs::path(root, "nested", "deeper")))
})

test_that(".ensure_directory() creates intermediate directories", {
    root   <- withr::local_tempdir()
    target <- fs::path(root, "a", "b", "c", "file.rds")

    suppressMessages(.ensure_directory(target))

    expect_true(fs::dir_exists(fs::path(root, "a", "b")))
})

test_that(".ensure_directory() reports when it creates a directory", {
    root   <- withr::local_tempdir()
    target <- fs::path(root, "nested", "file.rds")

    expect_message(.ensure_directory(target))
})

test_that(".ensure_directory() is silent when the directory exists", {
    root   <- withr::local_tempdir()
    target <- fs::path(root, "file.rds")

    expect_no_message(.ensure_directory(target))
})

test_that(".ensure_directory() is silent for a bare filename", {
    expect_no_message(.ensure_directory("file.rds"))
})

test_that(".ensure_directory() returns the directory invisibly", {
    # Both sides of the comparison are built with fs::path(). On macOS
    # withr::local_tempdir() can return a path containing a doubled slash
    # (.../T//Rtmp...), which fs tidies away, so comparing its raw value
    # against an fs-derived one fails on the separator alone. Same family
    # as the /var versus /private/var note in test-init-project.R.
    root       <- withr::local_tempdir()
    target_dir <- fs::path(root, "nested")
    target     <- fs::path(target_dir, "file.rds")

    suppressMessages(.ensure_directory(target))

    # The directory exists by now, so these take the silent path.
    expect_invisible(.ensure_directory(target))
    expect_equal(
        as.character(.ensure_directory(target)),
        as.character(target_dir)
    )
})

test_that(".ensure_directory() does not create the file itself", {
    root   <- withr::local_tempdir()
    target <- fs::path(root, "nested", "file.rds")

    suppressMessages(.ensure_directory(target))

    expect_true(fs::dir_exists(fs::path(root, "nested")))
    expect_false(fs::file_exists(target))
})

# -- The project root (T40) -----------------------------------------------------
# Paths in analysis code start at the project root, the rule here::here()
# follows. .project_root() looks for the same markers, but on every call, so
# these tests can move between temporary projects.

local_marked_project <- function(env = parent.frame()) {
    root <- withr::local_tempdir(.local_envir = env)
    file.create(fs::path(root, ".here"))
    fs::dir_create(fs::path(root, "reports", "2026"))
    as.character(fs::path_real(root))
}

test_that(".project_root() finds a .here marker above the starting folder", {
    root <- local_marked_project()

    expect_equal(.project_root(fs::path(root, "reports", "2026")), root)
})

test_that(".project_root() finds an RStudio project file", {
    root <- as.character(fs::path_real(withr::local_tempdir()))
    writeLines("Version: 1.0", fs::path(root, "proj.Rproj"))
    sub <- fs::dir_create(fs::path(root, "reports"))

    expect_equal(.project_root(sub), root)
})

test_that(".project_root() falls back to the starting folder when there is no marker", {
    # What an HTCondor execute node looks like: nothing above the job's
    # scratch directory marks a project, so the scratch directory is the root.
    dir <- as.character(fs::path_real(withr::local_tempdir()))

    expect_equal(.project_root(dir), dir)
})

test_that(".project_root() defaults to the working directory", {
    root <- local_marked_project()
    withr::local_dir(fs::path(root, "reports"))

    expect_equal(.project_root(), root)
})

test_that(".path_from_root() makes an absolute path inside the project relative", {
    root <- local_marked_project()
    fs::dir_create(fs::path(root, "output"))

    expect_equal(
        .path_from_root(fs::path(root, "output", "fit.rds"), root),
        "output/fit.rds"
    )
})

test_that(".path_from_root() makes a working-directory path relative to the root", {
    root <- local_marked_project()
    withr::local_dir(fs::path(root, "reports"))

    expect_equal(.path_from_root("fit.rds", root), "reports/fit.rds")
})

test_that(".path_from_root() leaves a path outside the project as given", {
    root    <- local_marked_project()
    outside <- fs::path(withr::local_tempdir(), "fit.rds")

    expect_equal(.path_from_root(outside, root), outside)
})

test_that(".resolve_output_dir() returns an explicit output_dir untouched", {
    expect_equal(.resolve_output_dir("somewhere/else", NULL), "somewhere/else")
})

test_that(".resolve_output_dir() defaults to output/ under the project root", {
    root <- local_marked_project()
    withr::local_dir(fs::path(root, "reports"))

    expect_equal(
        .resolve_output_dir(NULL, NULL),
        as.character(fs::path(root, "output"))
    )
})

test_that(".resolve_output_dir() takes a relative convention from the config's folder", {
    root   <- local_marked_project()
    config <- fs::path(root, "_toolero.yml")
    yaml::write_yaml(
        list(schema_version = 1L, folders = list("data"),
             conventions = list(output_dir = "results")),
        config
    )

    expect_equal(
        suppressMessages(.resolve_output_dir(NULL, config)),
        as.character(fs::path(root, "results"))
    )
})
