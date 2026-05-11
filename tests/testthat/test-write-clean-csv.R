# -- basic behavior ------------------------------------------------------------

test_that("write_clean_csv() writes a CSV file", {
    data <- data.frame(name = "Jane", score = 99)
    out  <- tempfile(fileext = ".csv")
    write_clean_csv(data, out)
    expect_true(fs::file_exists(out))
})

test_that("write_clean_csv() returns path invisibly", {
    data <- data.frame(name = "Jane", score = 99)
    out  <- tempfile(fileext = ".csv")
    result <- write_clean_csv(data, out)
    expect_equal(result, out)
})

test_that("write_clean_csv() written file is readable and correct", {
    data <- data.frame(name = "Jane", score = 99)
    out  <- tempfile(fileext = ".csv")
    write_clean_csv(data, out)
    result <- readr::read_csv(out, show_col_types = FALSE)
    expect_equal(nrow(result), 1)
    expect_equal(ncol(result), 2)
    expect_equal(result$name, "Jane")
})

# -- overwrite behavior --------------------------------------------------------

test_that("write_clean_csv() errors if file exists and overwrite = FALSE", {
    data <- data.frame(name = "Jane", score = 99)
    out  <- tempfile(fileext = ".csv")
    write_clean_csv(data, out)
    expect_error(
        write_clean_csv(data, out, overwrite = FALSE),
        info = "should error when file exists and overwrite is FALSE"
    )
})

test_that("write_clean_csv() overwrites file when overwrite = TRUE", {
    data <- data.frame(name = "Jane", score = 99)
    out  <- tempfile(fileext = ".csv")
    write_clean_csv(data, out)
    expect_error(
        write_clean_csv(data, out, overwrite = TRUE),
        NA,
        info = "should not error when overwrite is TRUE"
    )
})


# -- input validation ----------------------------------------------------------

test_that("write_clean_csv() errors on non-data-frame input", {
    out <- tempfile(fileext = ".csv")
    expect_error(
        write_clean_csv("not a data frame", out),
        info = "should error when data is not a data frame"
    )
})

test_that("write_clean_csv() errors on invalid path argument", {
    data <- data.frame(name = "Jane", score = 99)
    expect_error(
        write_clean_csv(data, 123),
        info = "should error when path is not a character string"
    )
})

# -- name cleaning -------------------------------------------------------------

test_that("write_clean_csv() warns when column names are not clean", {
    dirty <- data.frame("First Name" = "Jane", "Last Name" = "Doe",
                        check.names = FALSE)
    out <- tempfile(fileext = ".csv")
    expect_warning(
        write_clean_csv(dirty, out),
        info = "should warn when column names need cleaning"
    )
})

test_that("write_clean_csv() cleans column names before writing", {
    dirty <- data.frame("First Name" = "Jane", "Last Name" = "Doe",
                        check.names = FALSE)
    out <- tempfile(fileext = ".csv")
    suppressWarnings(write_clean_csv(dirty, out))
    result <- readr::read_csv(out, show_col_types = FALSE)
    expect_named(result, c("first_name", "last_name"))
})

test_that("write_clean_csv() does not warn when column names are already clean", {
    data <- data.frame(first_name = "Jane", last_name = "Doe")
    out  <- tempfile(fileext = ".csv")
    expect_no_warning(write_clean_csv(data, out))
})

# -- cli output ----------------------------------------------------------------

test_that("write_clean_csv() emits a success message", {
    data <- data.frame(name = "Jane", score = 99)
    out  <- tempfile(fileext = ".csv")
    expect_message(write_clean_csv(data, out))
})
