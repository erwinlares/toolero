# Tests for generate_data_doc()

tmp <- withr::local_tempdir()


# -- 1. Argument validation -----------------------------------------------------

test_that("generate_data_doc() errors if dataset is missing", {
    expect_error(
        generate_data_doc(path = tmp),
        class = "rlang_error"
    )
})

test_that("generate_data_doc() errors if dataset is an empty string", {
    expect_error(
        generate_data_doc(dataset = "", path = tmp),
        class = "rlang_error"
    )
})

test_that("generate_data_doc() errors if dataset is not length-one character", {
    expect_error(
        generate_data_doc(dataset = character(0), path = tmp),
        class = "rlang_error"
    )
    expect_error(
        generate_data_doc(dataset = c("a.csv", "b.csv"), path = tmp),
        class = "rlang_error"
    )
})

test_that("generate_data_doc() errors if path does not exist", {
    expect_error(
        generate_data_doc("survey.csv", path = fs::path(tmp, "nope")),
        class = "rlang_error"
    )
})


# -- 2. File creation and overwrite guard ----------------------------------------

test_that("generate_data_doc() creates a Markdown file at the given path", {
    dest <- generate_data_doc("creates.csv", path = tmp)
    expect_true(fs::file_exists(dest))
})

test_that("generate_data_doc() returns the destination path invisibly", {
    dest <- generate_data_doc("returns-path.csv", path = tmp)
    expect_equal(dest, fs::path_abs(fs::path(tmp, "returns-path.md")))
})

test_that("generate_data_doc() replaces the dataset's extension with .md", {
    dest <- generate_data_doc("weather_2024.csv", path = tmp)
    expect_equal(fs::path_file(dest), "weather_2024.md")
})

test_that("generate_data_doc() strips a nested dataset path down to the file name", {
    dest <- generate_data_doc("raw/nested-example.csv", path = tmp)
    expect_equal(fs::path_file(dest), "nested-example.md")
})

test_that("generate_data_doc() errors if the doc already exists and overwrite = FALSE", {
    generate_data_doc("no-overwrite.csv", path = tmp)
    expect_error(
        generate_data_doc("no-overwrite.csv", path = tmp, overwrite = FALSE),
        class = "rlang_error"
    )
})

test_that("generate_data_doc() overwrites when overwrite = TRUE", {
    generate_data_doc("overwrite.csv", path = tmp)
    expect_no_error(
        generate_data_doc("overwrite.csv", path = tmp, overwrite = TRUE)
    )
})


# -- 3. Template content ---------------------------------------------------------

test_that("generate_data_doc() fills in the dataset file name as the title", {
    dest  <- generate_data_doc("survey_responses.csv", path = tmp)
    lines <- readLines(dest)
    expect_equal(lines[1], "# survey_responses.csv")
})

test_that("generate_data_doc() fills in today's date under Date obtained", {
    dest  <- generate_data_doc("dated.csv", path = tmp)
    lines <- readLines(dest)
    expect_true(any(grepl(format(Sys.Date()), lines, fixed = TRUE)))
})

test_that("generate_data_doc() includes all the standard sections", {
    dest    <- generate_data_doc("sections.csv", path = tmp)
    content <- paste(readLines(dest), collapse = "\n")

    expect_true(grepl("## Source", content, fixed = TRUE))
    expect_true(grepl("## Date obtained", content, fixed = TRUE))
    expect_true(grepl("## License and usage terms", content, fixed = TRUE))
    expect_true(grepl("## Collection method", content, fixed = TRUE))
    expect_true(grepl("## Variables", content, fixed = TRUE))
    expect_true(grepl("## Known issues", content, fixed = TRUE))
})

test_that("generate_data_doc() leaves no placeholder tokens unfilled", {
    dest    <- generate_data_doc("no-placeholders.csv", path = tmp)
    content <- paste(readLines(dest), collapse = "\n")

    expect_false(grepl("{{", content, fixed = TRUE))
})

test_that("generate_data_doc() defaults to writing into a data/ subdirectory", {
    proj <- fs::path(tmp, "default-path-proj")
    fs::dir_create(fs::path(proj, "data"))
    withr::local_dir(proj)

    dest <- generate_data_doc("in-data-dir.csv")

    # path_real() resolves the /var -> /private/var symlink on macOS. proj
    # is built from tmp before the working directory changes, so it still
    # carries the symlinked form; dest is built from getwd() after
    # withr::local_dir() switches into proj, which on macOS reports the
    # resolved path. Both sides name the same file; only the spelling
    # differs.
    expect_equal(
        fs::path_real(dest),
        fs::path_real(fs::path(proj, "data", "in-data-dir.md"))
    )
})
