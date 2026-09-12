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

    expect_named(manifest, c("species", "group_value", "n_rows", "file_path"))
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


# -- prefix (T08) ---------------------------------------------------------------

test_that("prefix defaults to NULL and leaves filenames unchanged", {
    tmp  <- withr::local_tempdir()
    data <- make_test_data()

    write_by_group(data, group_col = "species", output_dir = tmp)

    expect_true(fs::file_exists(fs::path(tmp, "adelie.csv")))
})

test_that("prefix is prepended with a single dash", {
    tmp  <- withr::local_tempdir()
    data <- make_test_data()

    write_by_group(data, group_col = "species", output_dir = tmp,
                   prefix = "penguins")

    expect_true(fs::file_exists(fs::path(tmp, "penguins-adelie.csv")))
    expect_true(fs::file_exists(fs::path(tmp, "penguins-gentoo.csv")))
    expect_false(fs::file_exists(fs::path(tmp, "adelie.csv")))
})

test_that("prefix uses a single dash and columns keep the double dash", {
    tmp  <- withr::local_tempdir()
    data <- make_multi_group_data()

    write_by_group(data, group_col = c("species", "sex"), output_dir = tmp,
                   prefix = "penguins", drop_na = TRUE)

    expect_true(fs::file_exists(fs::path(tmp, "penguins-adelie--female.csv")))
    expect_true(fs::file_exists(fs::path(tmp, "penguins-gentoo--male.csv")))
})

test_that("prefix is sanitized the same way group values are", {
    tmp  <- withr::local_tempdir()
    data <- make_test_data()

    write_by_group(data, group_col = "species", output_dir = tmp,
                   prefix = "Penguin Data!")

    expect_true(fs::file_exists(fs::path(tmp, "penguin-data-adelie.csv")))
})

test_that("prefix reaches the manifest file_path", {
    tmp  <- withr::local_tempdir()
    data <- make_test_data()

    write_by_group(data, group_col = "species", output_dir = tmp,
                   manifest = TRUE, prefix = "penguins")
    manifest <- readr::read_csv(fs::path(tmp, "manifest.csv"), show_col_types = FALSE)

    expect_true(all(grepl("penguins-", fs::path_file(manifest$file_path))))
})

test_that("prefix does not alter group_value", {
    tmp  <- withr::local_tempdir()
    data <- make_test_data()

    write_by_group(data, group_col = "species", output_dir = tmp,
                   manifest = TRUE, prefix = "penguins")
    manifest <- readr::read_csv(fs::path(tmp, "manifest.csv"), show_col_types = FALSE)

    expect_setequal(manifest$group_value, c("Adelie", "Gentoo", "Chinstrap"))
})

test_that("prefix rejects a non-string", {
    tmp  <- withr::local_tempdir()
    data <- make_test_data()

    expect_error(
        write_by_group(data, group_col = "species", output_dir = tmp, prefix = 1),
        "single, non-missing character string"
    )
    expect_error(
        write_by_group(data, group_col = "species", output_dir = tmp,
                       prefix = c("a", "b")),
        "single, non-missing character string"
    )
    expect_error(
        write_by_group(data, group_col = "species", output_dir = tmp,
                       prefix = NA_character_),
        "single, non-missing character string"
    )
})

test_that("prefix rejects a value that sanitizes to nothing", {
    tmp  <- withr::local_tempdir()
    data <- make_test_data()

    expect_error(
        write_by_group(data, group_col = "species", output_dir = tmp,
                       prefix = "!!!"),
        "sanitizes to an empty string"
    )
})

test_that("prefix is a purely additive argument", {
    # Positional calls written before prefix existed must still mean what
    # they meant: the fourth position is manifest, not prefix.
    tmp  <- withr::local_tempdir()
    data <- make_test_data()

    write_by_group(data, "species", tmp, TRUE)

    expect_true(fs::file_exists(fs::path(tmp, "manifest.csv")))
    expect_true(fs::file_exists(fs::path(tmp, "adelie.csv")))
})

# -- the NA / "NA" collision (T20) ----------------------------------------------

make_na_collision_data <- function() {
    tibble::tibble(
        region = c("NA", "NA", "EU", NA),
        value  = c(1, 2, 3, 4)
    )
}

test_that("drop_na = FALSE aborts when a column holds both NA and literal 'NA'", {
    tmp  <- withr::local_tempdir()
    data <- make_na_collision_data()

    expect_error(
        write_by_group(data, group_col = "region", output_dir = tmp,
                       drop_na = FALSE),
        "literal"
    )
})

test_that("the collision error names the offending column", {
    tmp  <- withr::local_tempdir()
    data <- make_na_collision_data()

    err <- tryCatch(
        write_by_group(data, group_col = "region", output_dir = tmp,
                       drop_na = FALSE),
        error = function(e) e
    )

    expect_match(conditionMessage(err), "region")
})

test_that("drop_na = TRUE is unaffected by the collision", {
    tmp  <- withr::local_tempdir()
    data <- make_na_collision_data()

    expect_no_error(
        write_by_group(data, group_col = "region", output_dir = tmp,
                       drop_na = TRUE)
    )

    # the literal "NA" rows survive as their own group; the missing row is gone
    na_group <- readr::read_csv(fs::path(tmp, "na.csv"), show_col_types = FALSE)
    expect_equal(nrow(na_group), 2)
})

test_that("a literal 'NA' with no missing values is not a collision", {
    tmp  <- withr::local_tempdir()
    data <- tibble::tibble(region = c("NA", "NA", "EU"), value = 1:3)

    expect_no_error(
        write_by_group(data, group_col = "region", output_dir = tmp,
                       drop_na = FALSE)
    )
})

test_that("missing values with no literal 'NA' are not a collision", {
    tmp  <- withr::local_tempdir()
    data <- tibble::tibble(region = c("EU", "EU", NA), value = 1:3)

    expect_no_error(
        write_by_group(data, group_col = "region", output_dir = tmp,
                       drop_na = FALSE)
    )
    expect_true(fs::file_exists(fs::path(tmp, "na.csv")))
})

test_that("the collision is detected in any grouping column, not just the first", {
    tmp  <- withr::local_tempdir()
    data <- tibble::tibble(
        species = c("Adelie", "Adelie", "Gentoo"),
        region  = c("NA", NA, "EU"),
        value   = 1:3
    )

    expect_error(
        write_by_group(data, group_col = c("species", "region"),
                       output_dir = tmp, drop_na = FALSE),
        "region"
    )
})

# -- group order (T21) ----------------------------------------------------------

test_that("groups are written in order of first appearance", {
    tmp  <- withr::local_tempdir()
    data <- tibble::tibble(
        site  = c("zulu", "alpha", "zulu", "mike"),
        value = 1:4
    )

    write_by_group(data, group_col = "site", output_dir = tmp, manifest = TRUE)
    manifest <- readr::read_csv(fs::path(tmp, "manifest.csv"), show_col_types = FALSE)

    expect_equal(manifest$group_value, c("zulu", "alpha", "mike"))
})

test_that("numeric groups are not reordered lexicographically", {
    tmp  <- withr::local_tempdir()
    data <- tibble::tibble(
        batch = c(9, 10, 11, 9),
        value = 1:4
    )

    write_by_group(data, group_col = "batch", output_dir = tmp, manifest = TRUE)
    manifest <- readr::read_csv(fs::path(tmp, "manifest.csv"), show_col_types = FALSE)

    # first appearance is 9, 10, 11 -- sorting the sanitized key would give
    # 10, 11, 9
    expect_equal(as.character(manifest$group_value), c("9", "10", "11"))
})

test_that("multi-column groups also follow first appearance", {
    tmp  <- withr::local_tempdir()
    data <- tibble::tibble(
        species = c("Gentoo", "Adelie", "Gentoo"),
        sex     = c("male",   "female", "male"),
        value   = 1:3
    )

    write_by_group(data, group_col = c("species", "sex"), output_dir = tmp,
                   manifest = TRUE)
    manifest <- readr::read_csv(fs::path(tmp, "manifest.csv"), show_col_types = FALSE)

    expect_equal(manifest$group_value, c("Gentoo | male", "Adelie | female"))
})

test_that("row order does not change file contents", {
    tmp  <- withr::local_tempdir()
    data <- tibble::tibble(
        site  = c("zulu", "alpha", "zulu", "mike"),
        value = 1:4
    )

    write_by_group(data, group_col = "site", output_dir = tmp)

    zulu <- readr::read_csv(fs::path(tmp, "zulu.csv"), show_col_types = FALSE)
    expect_equal(zulu$value, c(1L, 3L))
})

# -- one manifest schema (T22) --------------------------------------------------

test_that("a single-column manifest carries the grouping column", {
    tmp  <- withr::local_tempdir()
    data <- make_test_data()

    write_by_group(data, group_col = "species", output_dir = tmp, manifest = TRUE)
    manifest <- readr::read_csv(fs::path(tmp, "manifest.csv"), show_col_types = FALSE)

    expect_true("species" %in% names(manifest))
    expect_setequal(manifest$species, c("Adelie", "Gentoo", "Chinstrap"))
})

test_that("for a single column the per-column field repeats group_value", {
    tmp  <- withr::local_tempdir()
    data <- make_test_data()

    write_by_group(data, group_col = "species", output_dir = tmp, manifest = TRUE)
    manifest <- readr::read_csv(fs::path(tmp, "manifest.csv"), show_col_types = FALSE)

    expect_equal(manifest$species, manifest$group_value)
})

test_that("the manifest schema has one shape regardless of column count", {
    tmp  <- withr::local_tempdir()

    write_by_group(make_test_data(), group_col = "species",
                   output_dir = fs::path(tmp, "one"), manifest = TRUE)
    write_by_group(make_multi_group_data(), group_col = c("species", "sex"),
                   output_dir = fs::path(tmp, "two"), manifest = TRUE)

    one <- readr::read_csv(fs::path(tmp, "one", "manifest.csv"), show_col_types = FALSE)
    two <- readr::read_csv(fs::path(tmp, "two", "manifest.csv"), show_col_types = FALSE)

    tail_cols <- c("group_value", "n_rows", "file_path")
    expect_equal(utils::tail(names(one), 3L), tail_cols)
    expect_equal(utils::tail(names(two), 3L), tail_cols)
})

test_that("single-column group_value is the raw value, not a composite", {
    tmp  <- withr::local_tempdir()
    data <- make_test_data()

    write_by_group(data, group_col = "species", output_dir = tmp, manifest = TRUE)
    manifest <- readr::read_csv(fs::path(tmp, "manifest.csv"), show_col_types = FALSE)

    expect_false(any(grepl("|", manifest$group_value, fixed = TRUE)))
})

test_that("run_by_group() accepts a manifest carrying per-column fields", {
    tmp  <- withr::local_tempdir()
    data <- make_test_data()

    write_by_group(data, group_col = "species", output_dir = tmp, manifest = TRUE)

    result <- run_by_group(
        manifest = fs::path(tmp, "manifest.csv"),
        .f       = function(d) tibble::tibble(n = nrow(d))
    )

    expect_setequal(result$group_id, c("Adelie", "Gentoo", "Chinstrap"))
})
