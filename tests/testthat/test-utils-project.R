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
