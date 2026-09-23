# tests/testthat/test-generate-profile.R

# -- input validation -----------------------------------------------------------

test_that("errors when filename is not supplied", {
    tmp <- withr::local_tempdir()

    expect_error(
        generate_profile(path = tmp),
        "must be supplied"
    )
})

test_that("errors when filename is NULL", {
    tmp <- withr::local_tempdir()

    expect_error(
        generate_profile(filename = NULL, path = tmp),
        "must be supplied"
    )
})

test_that("errors when filename is not a single string", {
    tmp <- withr::local_tempdir()

    expect_error(
        generate_profile(filename = c("a.yml", "b.yml"), path = tmp),
        "single character string"
    )
})

test_that("errors when path does not exist", {
    expect_error(
        generate_profile("profile.yml", path = "/no/such/directory"),
        "does not exist"
    )
})

test_that("errors when the destination already exists and overwrite = FALSE", {
    tmp <- withr::local_tempdir()
    generate_profile("profile.yml", path = tmp)

    expect_error(
        generate_profile("profile.yml", path = tmp),
        "already exists"
    )
})

# -- writing behavior -------------------------------------------------------------

test_that("writes the file at the expected destination", {
    tmp <- withr::local_tempdir()

    generate_profile("profile.yml", path = tmp)

    expect_true(fs::file_exists(fs::path(tmp, "profile.yml")))
})

test_that("returns the destination path invisibly", {
    tmp <- withr::local_tempdir()

    expect_invisible(generate_profile("profile.yml", path = tmp))
})

test_that("returns exactly the path it wrote to", {
    tmp    <- withr::local_tempdir()
    result <- generate_profile("profile.yml", path = tmp)

    expect_equal(as.character(result), as.character(fs::path(tmp, "profile.yml")))
})

test_that("overwrite = TRUE replaces an existing file", {
    tmp <- withr::local_tempdir()
    generate_profile("profile.yml", path = tmp)
    readr::write_file("sentinel", fs::path(tmp, "profile.yml"))

    generate_profile("profile.yml", path = tmp, overwrite = TRUE)

    content <- readr::read_file(fs::path(tmp, "profile.yml"))
    expect_false(identical(content, "sentinel"))
})

test_that("supports more than one profile under different filenames", {
    tmp <- withr::local_tempdir()

    generate_profile("personal.yml", path = tmp)
    generate_profile("work.yml", path = tmp)

    expect_true(fs::file_exists(fs::path(tmp, "personal.yml")))
    expect_true(fs::file_exists(fs::path(tmp, "work.yml")))
})

# -- default path -----------------------------------------------------------------

test_that("path defaults to the user's home directory, not the working directory", {
    expect_equal(
        as.character(eval(formals(generate_profile)$path)),
        as.character(fs::path_home())
    )
})

# -- template content ---------------------------------------------------------------

test_that("the written file has a personal information section", {
    tmp <- withr::local_tempdir()
    generate_profile("profile.yml", path = tmp)

    content <- readr::read_file(fs::path(tmp, "profile.yml"))
    expect_true(grepl("Personal information", content, fixed = TRUE))
    expect_true(grepl("author:", content, fixed = TRUE))
})

test_that("the written file has a document settings section", {
    tmp <- withr::local_tempdir()
    generate_profile("profile.yml", path = tmp)

    content <- readr::read_file(fs::path(tmp, "profile.yml"))
    expect_true(grepl("Document settings", content, fixed = TRUE))
    expect_true(grepl("format:", content, fixed = TRUE))
})

test_that("the written file does not include a phone number or mailing address placeholder", {
    tmp <- withr::local_tempdir()
    generate_profile("profile.yml", path = tmp)

    content <- readr::read_file(fs::path(tmp, "profile.yml"))
    expect_false(grepl("^phone:", content, ignore.case = TRUE))
    expect_false(grepl("^address:", content, ignore.case = TRUE))
})

test_that("the written file parses as valid YAML", {
    tmp <- withr::local_tempdir()
    generate_profile("profile.yml", path = tmp)

    parsed <- yaml::read_yaml(fs::path(tmp, "profile.yml"))
    expect_true("author" %in% names(parsed))
    expect_true("format" %in% names(parsed))
})

test_that("the written file's author block is usable by create_qmd(header_defaults = )", {
    tmp <- withr::local_tempdir()
    generate_profile("profile.yml", path = tmp)

    create_qmd(
        path = tmp, filename = "analysis.qmd", include_examples = FALSE,
        header_defaults = fs::path(tmp, "profile.yml")
    )

    qmd_content <- readr::read_file(fs::path(tmp, "analysis.qmd"))
    expect_true(grepl("Your Department, Your Institution", qmd_content, fixed = TRUE))
})

test_that("the written file's author block is usable by generate_citation()", {
    tmp <- withr::local_tempdir()
    generate_profile("profile.yml", path = tmp)

    generate_citation(path = tmp, profile = fs::path(tmp, "profile.yml"))

    cff_content <- readr::read_file(fs::path(tmp, "CITATION.cff"))
    expect_true(grepl("affiliation: \"Your Department, Your Institution\"", cff_content, fixed = TRUE))
})
