# tests/testthat/helper-project.R
#
# Shared fixtures for tests that depend on where the project root is.
# testthat sources every helper-*.R file before the tests run.

# A temporary project with a .here marker, optionally with subfolders such
# as reports/, entered for the rest of the calling test (or, outside a test,
# the calling function). Returns the symlink-resolved root as a character
# string, so it compares equal to what .project_root() returns.
#
# Prefer this to a bare withr::local_tempdir() whenever a test passes a
# relative path to a toolero function: the temporary directory has a
# marker, so the root is the project and not whatever happens to sit above
# the temporary directory.
local_project <- function(subdirs = "reports",
                          enter   = TRUE,
                          env     = parent.frame()) {
    root <- withr::local_tempdir(.local_envir = env)
    fs::file_create(fs::path(root, ".here"))

    for (dir in subdirs) {
        fs::dir_create(fs::path(root, dir))
    }

    root <- as.character(fs::path_real(root))

    if (enter) {
        withr::local_dir(root, .local_envir = env)
    }

    root
}
