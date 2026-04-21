# tests/testthat/test-write_by_group.R

# Helper: minimal test data
make_test_data <- function() {
    tibble::tibble(
        species   = c("Adelie", "Adelie", "Gentoo", "Gentoo", "Chinstrap"),
        body_mass = c(3750, 3800, 5000, 4900, 3500)
    )
}

# -- Happy path ---------------------------------------------------------------

test_that("creates one CSV file per group", {
    tmp  <- withr::local_tempdir()
    data <- make_test_data()

    write_by_group(data, group_col = "species", output_dir = tmp)

    expect_true(fs::file_exists(fs::path(tmp, "adelie.csv")))
    expect_true(fs::file_exists(fs::path(tmp, "gentoo.csv")))
    expect_true(fs::file_exists(fs::path(tmp, "chinstrap.csv")))
})

test_that("CSV filenames match sanitized group values", {
    tmp  <- withr::local_tempdir()
    data <- make_test_data()

    write_by_group(data, group_col = "species", output_dir = tmp)

    written_files <- fs::path_file(fs::dir_ls(tmp, glob = "*.csv"))
    expect_setequal(written_files, c("adelie.csv", "gentoo.csv", "chinstrap.csv"))
})

test_that("each CSV contains only rows for that group", {
    tmp  <- withr::local_tempdir()
    data <- make_test_data()

    write_by_group(data, group_col = "species", output_dir = tmp)

    adelie <- readr::read_csv(fs::path(tmp, "adelie.csv"), show_col_types = FALSE)
    expect_equal(nrow(adelie), 2)
    expect_true(all(adelie$species == "Adelie"))

    gentoo <- readr::read_csv(fs::path(tmp, "gentoo.csv"), show_col_types = FALSE)
    expect_equal(nrow(gentoo), 2)
    expect_true(all(gentoo$species == "Gentoo"))

    chinstrap <- readr::read_csv(fs::path(tmp, "chinstrap.csv"), show_col_types = FALSE)
    expect_equal(nrow(chinstrap), 1)
    expect_true(all(chinstrap$species == "Chinstrap"))
})

test_that("returns output_dir invisibly", {
    tmp  <- withr::local_tempdir()
    data <- make_test_data()

    result <- write_by_group(data, group_col = "species", output_dir = tmp)
    expect_equal(result, tmp)
})

test_that("creates output_dir if it does not exist", {
    tmp     <- withr::local_tempdir()
    new_dir <- fs::path(tmp, "new_output")
    data    <- make_test_data()

    expect_false(fs::dir_exists(new_dir))
    write_by_group(data, group_col = "species", output_dir = new_dir)
    expect_true(fs::dir_exists(new_dir))
})

test_that("writes manifest.csv when manifest = TRUE", {
    tmp  <- withr::local_tempdir()
    data <- make_test_data()

    write_by_group(data, group_col = "species", output_dir = tmp, manifest = TRUE)
    expect_true(fs::file_exists(fs::path(tmp, "manifest.csv")))
})

test_that("manifest contains correct columns", {
    tmp  <- withr::local_tempdir()
    data <- make_test_data()

    write_by_group(data, group_col = "species", output_dir = tmp, manifest = TRUE)
    manifest <- readr::read_csv(fs::path(tmp, "manifest.csv"), show_col_types = FALSE)

    expect_named(manifest, c("group_value", "n_rows", "file_path"))
})

test_that("manifest row counts match actual group sizes", {
    tmp  <- withr::local_tempdir()
    data <- make_test_data()

    write_by_group(data, group_col = "species", output_dir = tmp, manifest = TRUE)
    manifest <- readr::read_csv(fs::path(tmp, "manifest.csv"), show_col_types = FALSE)

    adelie_row <- manifest[manifest$group_value == "Adelie", ]
    expect_equal(adelie_row$n_rows, 2)

    chinstrap_row <- manifest[manifest$group_value == "Chinstrap", ]
    expect_equal(chinstrap_row$n_rows, 1)
})

test_that("manifest is not written when manifest = FALSE", {
    tmp  <- withr::local_tempdir()
    data <- make_test_data()

    write_by_group(data, group_col = "species", output_dir = tmp)
    expect_false(fs::file_exists(fs::path(tmp, "manifest.csv")))
})

# -- Edge cases / defensive ---------------------------------------------------

test_that("errors informatively when data is not a data frame", {
    tmp <- withr::local_tempdir()
    expect_error(
        write_by_group(list(a = 1, b = 2), group_col = "a", output_dir = tmp),
        "data frame or tibble"
    )
})

test_that("errors informatively when group_col is not found in data", {
    tmp  <- withr::local_tempdir()
    data <- make_test_data()

    expect_error(
        write_by_group(data, group_col = "island", output_dir = tmp),
        "not found"
    )
})

test_that("sanitizes group values with spaces in filenames", {
    tmp  <- withr::local_tempdir()
    data <- tibble::tibble(
        group = c("group one", "group one", "group two"),
        value = c(1, 2, 3)
    )

    write_by_group(data, group_col = "group", output_dir = tmp)
    expect_true(fs::file_exists(fs::path(tmp, "group_one.csv")))
    expect_true(fs::file_exists(fs::path(tmp, "group_two.csv")))
})

test_that("sanitizes group values with special characters in filenames", {
    tmp  <- withr::local_tempdir()
    data <- tibble::tibble(
        group = c("group@one", "group@one", "group#two"),
        value = c(1, 2, 3)
    )

    write_by_group(data, group_col = "group", output_dir = tmp)
    expect_true(fs::file_exists(fs::path(tmp, "group_one.csv")))
    expect_true(fs::file_exists(fs::path(tmp, "group_two.csv")))
})

# -- sanitize_filename() helper -----------------------------------------------

test_that("sanitize_filename() lowercases input", {
    expect_equal(sanitize_filename("Adelie"), "adelie")
})

test_that("sanitize_filename() replaces spaces with underscores", {
    expect_equal(sanitize_filename("group one"), "group_one")
})

test_that("sanitize_filename() replaces special characters with underscores", {
    expect_equal(sanitize_filename("group@one!"), "group_one")
})

test_that("sanitize_filename() collapses consecutive underscores", {
    expect_equal(sanitize_filename("group  one"), "group_one")
})

test_that("sanitize_filename() strips leading and trailing underscores", {
    expect_equal(sanitize_filename("@group@"), "group")
})
