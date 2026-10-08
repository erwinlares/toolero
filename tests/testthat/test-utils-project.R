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

test_that(".resolve_output_dir() reads a relative explicit output_dir from the root", {
    root <- local_marked_project()
    withr::local_dir(fs::path(root, "reports"))

    expect_equal(
        .resolve_output_dir("somewhere/else", NULL),
        as.character(fs::path(root, "somewhere", "else"))
    )
})

test_that(".resolve_output_dir() returns an absolute explicit output_dir untouched", {
    absolute <- as.character(fs::path(withr::local_tempdir(), "else"))

    expect_equal(.resolve_output_dir(absolute, NULL), absolute)
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


# -- The job scratch directory (T41) --------------------------------------------
# HTCondor sets _CONDOR_SCRATCH_DIR itself, inside the job. setup.R unsets it
# for the whole suite, so each test here sets it on purpose.

test_that(".job_scratch_dir() is NULL when the variable is unset or empty", {
    expect_null(.job_scratch_dir())

    withr::local_envvar(c("_CONDOR_SCRATCH_DIR" = ""))
    expect_null(.job_scratch_dir())
})

test_that(".job_scratch_dir() is NULL when the variable names a missing folder", {
    gone <- fs::path(withr::local_tempdir(), "not-there")
    withr::local_envvar(c("_CONDOR_SCRATCH_DIR" = as.character(gone)))

    expect_null(.job_scratch_dir())
})

test_that(".job_scratch_dir() returns the symlink-resolved folder", {
    scratch <- withr::local_tempdir()
    withr::local_envvar(c("_CONDOR_SCRATCH_DIR" = scratch))

    expect_equal(.job_scratch_dir(), as.character(fs::path_real(scratch)))
})

test_that(".project_root() is the scratch directory when HTCondor names one", {
    scratch <- withr::local_tempdir()
    withr::local_envvar(c("_CONDOR_SCRATCH_DIR" = scratch))

    expect_equal(.project_root(), as.character(fs::path_real(scratch)))
})

test_that(".project_root() prefers the scratch directory to a marker", {
    root    <- local_project()
    scratch <- withr::local_tempdir()
    withr::local_envvar(c("_CONDOR_SCRATCH_DIR" = scratch))

    expect_false(identical(.project_root(), root))
    expect_equal(.project_root(), as.character(fs::path_real(scratch)))
})

test_that(".project_root() ignores an unusable scratch variable and uses the marker", {
    root <- local_project()
    withr::local_envvar(c("_CONDOR_SCRATCH_DIR" = ""))
    expect_equal(.project_root(), root)

    gone <- fs::path(withr::local_tempdir(), "not-there")
    withr::local_envvar(c("_CONDOR_SCRATCH_DIR" = as.character(gone)))
    expect_equal(.project_root(), root)
})


# -- local_project() (helper-project.R) ------------------------------------------

test_that("local_project() builds a marked project and enters it", {
    root <- local_project(subdirs = c("reports", "data"))

    expect_true(fs::file_exists(fs::path(root, ".here")))
    expect_true(fs::dir_exists(fs::path(root, "reports")))
    expect_true(fs::dir_exists(fs::path(root, "data")))
    expect_equal(as.character(fs::path_real(getwd())), root)
    expect_equal(.project_root(), root)
})

test_that("local_project(enter = FALSE) leaves the working directory alone", {
    before <- getwd()
    root   <- local_project(enter = FALSE)

    expect_equal(getwd(), before)
    expect_true(fs::file_exists(fs::path(root, ".here")))
})


# -- .is_relative_local_path() (T41) --------------------------------------------

test_that(".is_relative_local_path() separates relative paths from everything else", {
    paths <- c(
        "a/b.csv", "a.csv", "./a.csv", "../a.csv",
        "/abs/a.csv", "~/a.csv",
        "https://x.org/a.csv", "s3://bucket/a.csv",
        "", NA
    )

    expect_equal(
        .is_relative_local_path(paths),
        c(TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE)
    )
})

test_that(".is_relative_local_path() copes with a zero-length vector", {
    expect_equal(.is_relative_local_path(character(0)), logical(0))
})


# -- .resolve_from_project_root() (T41) -----------------------------------------

test_that(".resolve_from_project_root() keeps NULL as NULL", {
    expect_null(.resolve_from_project_root(NULL))
})

test_that(".resolve_from_project_root() joins a relative path to the root", {
    root <- local_project()

    expect_equal(
        .resolve_from_project_root("output/fit.rds"),
        as.character(fs::path(root, "output", "fit.rds"))
    )
})

test_that(".resolve_from_project_root() gives the same answer from a subfolder", {
    root <- local_project()
    withr::local_dir(fs::path(root, "reports"))

    expect_equal(
        .resolve_from_project_root("output/fit.rds"),
        as.character(fs::path(root, "output", "fit.rds"))
    )
})

test_that(".resolve_from_project_root() takes an explicit root", {
    expect_equal(
        .resolve_from_project_root("a/b.csv", root = "/some/root"),
        as.character(fs::path("/some/root", "a", "b.csv"))
    )
})

test_that(".resolve_from_project_root() lets absolute paths, URLs, NA and empty strings through", {
    root  <- local_project()
    paths <- c(
        absolute = as.character(fs::path(withr::local_tempdir(), "x.rds")),
        home     = "~/x.rds",
        url      = "https://example.org/x.csv",
        bucket   = "s3://bucket/x.csv",
        missing  = NA_character_,
        empty    = ""
    )

    expect_identical(.resolve_from_project_root(paths, root = root), paths)
})

test_that(".resolve_from_project_root() is vectorised and keeps names", {
    root  <- local_project()
    paths <- c(first = "a.csv", second = "/abs/b.csv", third = "sub/c.csv")

    out <- .resolve_from_project_root(paths)

    expect_named(out, c("first", "second", "third"))
    expect_equal(
        unname(out),
        c(
            as.character(fs::path(root, "a.csv")),
            "/abs/b.csv",
            as.character(fs::path(root, "sub", "c.csv"))
        )
    )
})

test_that(".resolve_from_project_root() does not interpret . or ..", {
    expect_equal(
        .resolve_from_project_root("../x.csv", root = "/some/root"),
        "/some/root/../x.csv"
    )
})

test_that(".resolve_from_project_root() does not look for the root when nothing needs it", {
    local_mocked_bindings(
        .project_root = function(...) stop("the root was looked up")
    )

    expect_no_error(
        .resolve_from_project_root(c("/abs/x.csv", "https://x.org/y.csv"))
    )
})

test_that(".resolve_from_project_root() resolves from the scratch directory in a job", {
    scratch <- withr::local_tempdir()
    withr::local_envvar(c("_CONDOR_SCRATCH_DIR" = scratch))

    expect_equal(
        .resolve_from_project_root("data/jobs/group-a.csv"),
        as.character(fs::path(fs::path_real(scratch), "data", "jobs", "group-a.csv"))
    )
})


# -- .resolve_input_from_project_root() (T41) -----------------------------------

test_that(".resolve_input_from_project_root() keeps NULL as NULL", {
    expect_null(.resolve_input_from_project_root(NULL))
})

test_that(".resolve_input_from_project_root() reads from the root when the file is there", {
    root <- local_project(subdirs = c("reports", "data"))
    fs::file_create(fs::path(root, "data", "a.csv"))
    withr::local_dir(fs::path(root, "reports"))

    expect_no_message(
        out <- .resolve_input_from_project_root("data/a.csv")
    )
    expect_equal(out, as.character(fs::path(root, "data", "a.csv")))
})

test_that(".resolve_input_from_project_root() prefers the root when the file exists in both places", {
    root <- local_project(subdirs = c("reports", "data", "reports/data"))
    fs::file_create(fs::path(root, "data", "a.csv"))
    fs::file_create(fs::path(root, "reports", "data", "a.csv"))
    withr::local_dir(fs::path(root, "reports"))

    expect_no_message(
        out <- .resolve_input_from_project_root("data/a.csv")
    )
    expect_equal(out, as.character(fs::path(root, "data", "a.csv")))
})

test_that(".resolve_input_from_project_root() falls back to the working directory and says so", {
    root <- local_project()
    fs::file_create(fs::path(root, "reports", "a.csv"))
    withr::local_dir(fs::path(root, "reports"))

    expect_message(
        out <- .resolve_input_from_project_root("a.csv"),
        "working directory"
    )
    expect_equal(out, "a.csv")
})

test_that(".resolve_input_from_project_root() names the root path when neither location has the file", {
    root <- local_project()
    withr::local_dir(fs::path(root, "reports"))

    expect_no_message(
        out <- .resolve_input_from_project_root("nowhere.csv")
    )
    expect_equal(out, as.character(fs::path(root, "nowhere.csv")))
})

test_that(".resolve_input_from_project_root() leaves absolute paths and URLs alone", {
    root     <- local_project()
    absolute <- as.character(fs::path(root, "reports", "a.csv"))
    fs::file_create(absolute)

    expect_no_message(
        out <- .resolve_input_from_project_root(
            c(absolute, "https://example.org/a.csv")
        )
    )
    expect_equal(out, c(absolute, "https://example.org/a.csv"))
})

test_that(".resolve_input_from_project_root() handles a named vector with a mixed outcome", {
    root <- local_project(subdirs = c("reports", "data"))
    fs::file_create(fs::path(root, "data", "at-root.csv"))
    fs::file_create(fs::path(root, "reports", "in-wd.csv"))
    withr::local_dir(fs::path(root, "reports"))

    paths <- c(a = "data/at-root.csv", b = "in-wd.csv")

    expect_message(
        out <- .resolve_input_from_project_root(paths),
        "working directory"
    )
    expect_named(out, c("a", "b"))
    expect_equal(
        unname(out),
        c(as.character(fs::path(root, "data", "at-root.csv")), "in-wd.csv")
    )
})

test_that(".resolve_input_from_project_root() treats a folder like a file", {
    root <- local_project(subdirs = c("reports", "output"))
    withr::local_dir(fs::path(root, "reports"))

    expect_no_message(
        out <- .resolve_input_from_project_root("output")
    )
    expect_equal(out, as.character(fs::path(root, "output")))
})


# -- .resolve_from_project_root(): "." and non-character input (T42) -------------

test_that(".resolve_from_project_root() turns a bare \".\" into the root itself", {
    root <- local_project()

    expect_equal(.resolve_from_project_root("."), root)
    expect_equal(
        .resolve_from_project_root(c(a = ".", b = "x.csv")),
        c(a = root, b = as.character(fs::path(root, "x.csv")))
    )
})

test_that(".resolve_from_project_root() hands back a non-character value untouched", {
    expect_identical(.resolve_from_project_root(123), 123)
    expect_identical(.resolve_from_project_root(TRUE), TRUE)
    expect_identical(.resolve_from_project_root(list("a")), list("a"))
})
