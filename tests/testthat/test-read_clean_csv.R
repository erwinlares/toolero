test_that("read_clean_csv() returns a tibble", {
    tmp <- tempfile(fileext = ".csv")
    writeLines("First Name,Last Name,Age\nJane,Doe,30", tmp)

    result <- read_clean_csv(tmp)

    expect_s3_class(result, "tbl_df")
})

test_that("read_clean_csv() cleans column names", {
    tmp <- tempfile(fileext = ".csv")
    writeLines("First Name,Last Name,Age\nJane,Doe,30", tmp)

    result <- read_clean_csv(tmp)

    expect_named(result, c("first_name", "last_name", "age"))
})

test_that("read_clean_csv() reads data correctly", {
    tmp <- tempfile(fileext = ".csv")
    writeLines("First Name,Last Name,Age\nJane,Doe,30", tmp)

    result <- read_clean_csv(tmp)

    expect_equal(nrow(result), 1)
    expect_equal(ncol(result), 3)
})

test_that("read_clean_csv() errors on non-existent file", {
    expect_error(read_clean_csv("non_existent_file.csv"))
})

test_that("read_clean_csv() verbose argument works", {
    tmp <- tempfile(fileext = ".csv")
    writeLines("First Name,Last Name,Age\nJane,Doe,30", tmp)

    # should run without error in both modes
    expect_no_error(read_clean_csv(tmp, verbose = FALSE))
    expect_no_error(read_clean_csv(tmp, verbose = TRUE))
})
