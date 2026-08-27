# tests/testthat/test-write_by_group.R

# Helper: minimal test data
make_test_data <- function() {
    tibble::tibble(
        species   = c("Adelie", "Adelie", "Gentoo", "Gentoo", "Chinstrap"),
        body_mass = c(3750, 3800, 5000, 4900, 3500)
    )
}

# Helper: two-column grouping data with one NA in the second grouping column
make_multi_group_data <- function() {
    tibble::tibble(
        species   = c("Adelie", "Adelie", "Adelie", "Gentoo", "Gentoo", "Gentoo"),
        sex       = c("female", "male",   NA,        "female", "male",   "male"),
        body_mass = c(3750,     3800,     3700,       5000,     4900,     4950)
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

test_that("errors listing every missing column when several are missing", {
    tmp  <- withr::local_tempdir()
    data <- make_test_data()

    err <- tryCatch(
        write_by_group(data, group_col = c("island", "habitat"), output_dir = tmp),
        error = function(e) e
    )
    expect_match(conditionMessage(err), "island")
    expect_match(conditionMessage(err), "habitat")
})

test_that("errors when group_col contains duplicated column names", {
    tmp  <- withr::local_tempdir()
    data <- make_test_data()

    expect_error(
        write_by_group(data, group_col = c("species", "species"), output_dir = tmp),
        "duplicated"
    )
})

test_that("errors when group_col includes a list-column", {
    tmp  <- withr::local_tempdir()
    data <- tibble::tibble(
        species = c("Adelie", "Gentoo"),
        weird   = list(1:2, 3:4)
    )

    expect_error(
        write_by_group(data, group_col = c("species", "weird"), output_dir = tmp),
        "list-column"
    )
})

test_that("sanitizes group values with spaces using dashes in filenames", {
    tmp  <- withr::local_tempdir()
    data <- tibble::tibble(
        group = c("group one", "group one", "group two"),
        value = c(1, 2, 3)
    )

    write_by_group(data, group_col = "group", output_dir = tmp)
    expect_true(fs::file_exists(fs::path(tmp, "group-one.csv")))
    expect_true(fs::file_exists(fs::path(tmp, "group-two.csv")))
})

test_that("sanitizes group values with special characters using dashes in filenames", {
    tmp  <- withr::local_tempdir()
    data <- tibble::tibble(
        group = c("group@one", "group@one", "group#two"),
        value = c(1, 2, 3)
    )

    write_by_group(data, group_col = "group", output_dir = tmp)
    expect_true(fs::file_exists(fs::path(tmp, "group-one.csv")))
    expect_true(fs::file_exists(fs::path(tmp, "group-two.csv")))
})

# -- Multi-column grouping: happy path -----------------------------------------

test_that("creates one CSV file per combination of multiple grouping columns", {
    tmp  <- withr::local_tempdir()
    data <- make_multi_group_data()

    write_by_group(data, group_col = c("species", "sex"), output_dir = tmp, drop_na = TRUE)

    expect_true(fs::file_exists(fs::path(tmp, "adelie--female.csv")))
    expect_true(fs::file_exists(fs::path(tmp, "adelie--male.csv")))
    expect_true(fs::file_exists(fs::path(tmp, "gentoo--female.csv")))
    expect_true(fs::file_exists(fs::path(tmp, "gentoo--male.csv")))
})

test_that("multi-column filenames use -- as the between-column separator", {
    tmp  <- withr::local_tempdir()
    data <- make_multi_group_data()

    write_by_group(data, group_col = c("species", "sex"), output_dir = tmp, drop_na = TRUE)

    written_files <- fs::path_file(fs::dir_ls(tmp, glob = "*.csv"))
    expect_true(all(grepl("--", written_files)))
})

test_that("each CSV under multi-column grouping contains only rows for that combination", {
    tmp  <- withr::local_tempdir()
    data <- make_multi_group_data()

    write_by_group(data, group_col = c("species", "sex"), output_dir = tmp, drop_na = TRUE)

    gentoo_male <- readr::read_csv(fs::path(tmp, "gentoo--male.csv"), show_col_types = FALSE)
    expect_equal(nrow(gentoo_male), 2)
    expect_true(all(gentoo_male$species == "Gentoo"))
    expect_true(all(gentoo_male$sex == "male"))
})

test_that("only observed column combinations produce files, not the full cross-product", {
    tmp  <- withr::local_tempdir()
    data <- make_multi_group_data()

    write_by_group(data, group_col = c("species", "sex"), output_dir = tmp, drop_na = TRUE)

    # species has 2 levels, sex has 2 levels (after dropping NA), but only 4
    # combinations are actually observed here -- confirm no extras appear
    written_files <- fs::path_file(fs::dir_ls(tmp, glob = "*.csv"))
    expect_length(written_files, 4)
})

# -- Multi-column manifest ------------------------------------------------------

test_that("manifest gains one column per grouping variable for multi-column grouping", {
    tmp  <- withr::local_tempdir()
    data <- make_multi_group_data()

    write_by_group(data, group_col = c("species", "sex"), output_dir = tmp,
                   manifest = TRUE, drop_na = TRUE)
    manifest <- readr::read_csv(fs::path(tmp, "manifest.csv"), show_col_types = FALSE)

    expect_named(manifest, c("species", "sex", "group_value", "n_rows", "file_path"))
})

test_that("multi-column group_value is a raw, pipe-separated composite", {
    tmp  <- withr::local_tempdir()
    data <- make_multi_group_data()

    write_by_group(data, group_col = c("species", "sex"), output_dir = tmp,
                   manifest = TRUE, drop_na = TRUE)
    manifest <- readr::read_csv(fs::path(tmp, "manifest.csv"), show_col_types = FALSE)

    expect_true("Adelie | female" %in% manifest$group_value)
    expect_true("Gentoo | male" %in% manifest$group_value)
})

test_that("group_col order determines filename and manifest column order", {
    tmp  <- withr::local_tempdir()
    data <- make_multi_group_data()

    write_by_group(data, group_col = c("sex", "species"), output_dir = tmp,
                   manifest = TRUE, drop_na = TRUE)

    expect_true(fs::file_exists(fs::path(tmp, "female--adelie.csv")))
    manifest <- readr::read_csv(fs::path(tmp, "manifest.csv"), show_col_types = FALSE)
    expect_named(manifest, c("sex", "species", "group_value", "n_rows", "file_path"))
})

# -- drop_na behavior -----------------------------------------------------------

test_that("drop_na = TRUE (default) drops rows with NA in any grouping column", {
    tmp  <- withr::local_tempdir()
    data <- make_multi_group_data()

    write_by_group(data, group_col = c("species", "sex"), output_dir = tmp, drop_na = TRUE)

    written_files <- fs::path_file(fs::dir_ls(tmp, glob = "*.csv"))
    expect_false("adelie--na.csv" %in% written_files)

    total_rows <- sum(vapply(fs::dir_ls(tmp, glob = "*.csv"), function(f) {
        nrow(readr::read_csv(f, show_col_types = FALSE))
    }, integer(1)))
    expect_equal(total_rows, 5)  # 6 rows in fixture, 1 has NA sex
})

test_that("drop_na = FALSE treats missing grouping values as their own group", {
    tmp  <- withr::local_tempdir()
    data <- make_multi_group_data()

    write_by_group(data, group_col = c("species", "sex"), output_dir = tmp, drop_na = FALSE)

    expect_true(fs::file_exists(fs::path(tmp, "adelie--na.csv")))
    na_group <- readr::read_csv(fs::path(tmp, "adelie--na.csv"), show_col_types = FALSE)
    expect_equal(nrow(na_group), 1)
})

test_that("drop_na = FALSE writes all rows across all groups, none lost", {
    tmp  <- withr::local_tempdir()
    data <- make_multi_group_data()

    write_by_group(data, group_col = c("species", "sex"), output_dir = tmp, drop_na = FALSE)

    total_rows <- sum(vapply(fs::dir_ls(tmp, glob = "*.csv"), function(f) {
        nrow(readr::read_csv(f, show_col_types = FALSE))
    }, integer(1)))
    expect_equal(total_rows, nrow(data))
})

# -- Reserved manifest column names ----------------------------------------------

test_that("errors when group_col uses a reserved manifest column name and manifest = TRUE", {
    tmp  <- withr::local_tempdir()
    data <- tibble::tibble(
        group_value = c("a", "b"),
        other       = c(1, 2)
    )

    expect_error(
        write_by_group(data, group_col = "group_value", output_dir = tmp, manifest = TRUE),
        "reserved"
    )
})

test_that("does not error on a reserved column name when manifest = FALSE", {
    tmp  <- withr::local_tempdir()
    data <- tibble::tibble(
        group_value = c("a", "b"),
        other       = c(1, 2)
    )

    expect_error(
        write_by_group(data, group_col = "group_value", output_dir = tmp, manifest = FALSE),
        NA
    )
})

# -- sanitize_filename() helper -----------------------------------------------

test_that("sanitize_filename() lowercases input", {
    expect_equal(sanitize_filename("Adelie"), "adelie")
})

test_that("sanitize_filename() replaces spaces with dashes", {
    expect_equal(sanitize_filename("group one"), "group-one")
})

test_that("sanitize_filename() replaces special characters with dashes", {
    expect_equal(sanitize_filename("group@one!"), "group-one")
})

test_that("sanitize_filename() collapses consecutive dashes", {
    expect_equal(sanitize_filename("group  one"), "group-one")
})

test_that("sanitize_filename() strips leading and trailing dashes", {
    expect_equal(sanitize_filename("@group@"), "group")
})
