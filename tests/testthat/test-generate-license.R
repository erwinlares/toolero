# Tests for generate_license()

# The destination file name is always "LICENSE" -- unlike
# generate_project_config(), a unique filename per test won't give us
# isolation. Each test that needs a clean destination gets its own
# subdirectory under the shared temp dir instead.
tmp <- withr::local_tempdir()

new_dir <- function(name) {
    dir <- fs::path(tmp, name)
    fs::dir_create(dir)
    dir
}


# -- 1. Argument validation -----------------------------------------------------

test_that("generate_license() errors if holder is missing", {
    expect_error(
        generate_license(path = new_dir("no-holder")),
        class = "rlang_error"
    )
})

test_that("generate_license() errors if holder is an empty string", {
    expect_error(
        generate_license(holder = "", path = new_dir("empty-holder")),
        class = "rlang_error"
    )
})

test_that("generate_license() errors if holder is not length-one character", {
    expect_error(
        generate_license(holder = character(0), path = new_dir("zero-len-holder")),
        class = "rlang_error"
    )
    expect_error(
        generate_license(holder = c("A", "B"), path = new_dir("multi-holder")),
        class = "rlang_error"
    )
})

test_that("generate_license() rejects an unsupported license with an informative error", {
    expect_error(
        generate_license(license = "Apache-2.0", holder = "Test Holder",
                         path = new_dir("bad-license")),
        class = "rlang_error"
    )
})

test_that("generate_license() errors if path does not exist", {
    expect_error(
        generate_license(holder = "Test Holder", path = fs::path(tmp, "nope")),
        class = "rlang_error"
    )
})


# -- 2. File creation and overwrite guard ----------------------------------------

test_that("generate_license() creates a LICENSE file at the given path", {
    dir  <- new_dir("creates")
    dest <- generate_license(holder = "Test Holder", path = dir)
    expect_true(fs::file_exists(dest))
})

test_that("generate_license() returns the destination path invisibly", {
    dir  <- new_dir("returns-path")
    dest <- generate_license(holder = "Test Holder", path = dir)
    expect_equal(dest, fs::path_abs(fs::path(dir, "LICENSE")))
})

test_that("generate_license() errors if LICENSE exists and overwrite = FALSE", {
    dir <- new_dir("no-overwrite")
    generate_license(holder = "Test Holder", path = dir)
    expect_error(
        generate_license(holder = "Test Holder", path = dir, overwrite = FALSE),
        class = "rlang_error"
    )
})

test_that("generate_license() overwrites when overwrite = TRUE", {
    dir <- new_dir("overwrite")
    generate_license(holder = "Test Holder", path = dir)
    expect_no_error(
        generate_license(holder = "Test Holder", path = dir, overwrite = TRUE)
    )
})


# -- 3. Template content ---------------------------------------------------------

test_that("generate_license() defaults to the MIT license", {
    dir   <- new_dir("default-mit")
    dest  <- generate_license(holder = "Test Holder", path = dir)
    lines <- readLines(dest)
    expect_true(any(grepl("^MIT License", lines)))
})

test_that("generate_license() defaults the year to the current year", {
    dir   <- new_dir("default-year")
    dest  <- generate_license(holder = "Test Holder", path = dir)
    lines <- readLines(dest)
    expect_true(any(grepl(format(Sys.Date(), "%Y"), lines, fixed = TRUE)))
})

test_that("generate_license() fills in the holder and year for MIT", {
    dir   <- new_dir("mit-fill")
    dest  <- generate_license(license = "MIT", holder = "Jane Researcher",
                              year = "2020", path = dir)
    lines <- readLines(dest)
    expect_true(any(grepl("Copyright (c) 2020 Jane Researcher", lines, fixed = TRUE)))
})

test_that("generate_license() fills in the holder and year for CC0", {
    dir   <- new_dir("cc0-fill")
    dest  <- generate_license(license = "CC0", holder = "Example Lab",
                              year = "2021", path = dir)
    lines <- readLines(dest)
    expect_true(any(grepl("Copyright (c) 2021 Example Lab", lines, fixed = TRUE)))
})

test_that("generate_license() fills in the holder and year for GPL-3", {
    dir   <- new_dir("gpl3-fill")
    dest  <- generate_license(license = "GPL-3", holder = "Example Lab",
                              year = "2022", path = dir)
    lines <- readLines(dest)
    expect_true(any(grepl("Copyright (c) 2022 Example Lab", lines, fixed = TRUE)))
})

test_that("generate_license() GPL-3 links to the canonical full text rather than reproducing it", {
    dir   <- new_dir("gpl3-link")
    dest  <- generate_license(license = "GPL-3", holder = "Test Holder", path = dir)
    lines <- readLines(dest)

    expect_true(any(grepl("https://www.gnu.org/licenses/gpl-3.0.txt", lines, fixed = TRUE)))
    # A stand-in notice, not the several-hundred-line GPL-3 text.
    expect_true(length(lines) < 50L)
})

test_that("generate_license() MIT and CC0 texts differ from each other", {
    mit_dir <- new_dir("mit-vs-cc0-mit")
    cc0_dir <- new_dir("mit-vs-cc0-cc0")
    mit     <- readLines(generate_license(license = "MIT", holder = "Test Holder", path = mit_dir))
    cc0     <- readLines(generate_license(license = "CC0", holder = "Test Holder", path = cc0_dir))

    expect_false(identical(mit, cc0))
})
