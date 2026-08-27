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
    expect_no_error(read_clean_csv(tmp, verbose = FALSE))
    expect_no_error(read_clean_csv(tmp, verbose = TRUE))
})

# -- na argument ---------------------------------------------------------------

test_that("read_clean_csv() treats custom strings as NA", {
    tmp <- tempfile(fileext = ".csv")
    writeLines("name,score\nJane,99\nJohn,missing\nAlex,.", tmp)
    result <- read_clean_csv(tmp, na = c("", "NA", "missing", "."))
    expect_true(is.na(result$score[2]))
    expect_true(is.na(result$score[3]))
})

test_that("read_clean_csv() respects na = character() (no NA substitution)", {
    tmp <- tempfile(fileext = ".csv")
    writeLines("name,score\nJane,NA\nJohn,99", tmp)
    result <- read_clean_csv(tmp, na = character())
    expect_equal(result$score, c("NA", "99"))
})

# -- drop_na argument ----------------------------------------------------------

test_that("read_clean_csv() drop_na = TRUE drops all rows with any NA", {
    tmp <- tempfile(fileext = ".csv")
    writeLines("name,score\nJane,99\nJohn,NA\nAlex,88", tmp)
    result <- read_clean_csv(tmp, drop_na = TRUE)
    expect_equal(nrow(result), 2)
    expect_false(anyNA(result))
})

test_that("read_clean_csv() drop_na on specific columns drops only affected rows", {
    tmp <- tempfile(fileext = ".csv")
    writeLines("name,score,group\nJane,99,NA\nJohn,NA,B\nAlex,88,C", tmp)
    result <- read_clean_csv(tmp, drop_na = "score")
    expect_equal(nrow(result), 2)
    expect_true(any(is.na(result$group)))
})

test_that("read_clean_csv() drop_na errors on unknown column names", {
    tmp <- tempfile(fileext = ".csv")
    writeLines("name,score\nJane,99\nJohn,NA", tmp)
    expect_error(
        read_clean_csv(tmp, drop_na = "nonexistent_col"),
        info = "drop_na with bad column name should error"
    )
})

test_that("read_clean_csv() drop_na = FALSE leaves NAs untouched", {
    tmp <- tempfile(fileext = ".csv")
    writeLines("name,score\nJane,99\nJohn,NA", tmp)
    result <- read_clean_csv(tmp, drop_na = FALSE)
    expect_equal(nrow(result), 2)
    expect_true(anyNA(result))
})

test_that("read_clean_csv() drop_na emits a message", {
    tmp <- tempfile(fileext = ".csv")
    writeLines("name,score\nJane,99\nJohn,NA", tmp)
    expect_message(read_clean_csv(tmp, drop_na = TRUE))
})

test_that("read_clean_csv() drop_na with column vector emits a message", {
    tmp <- tempfile(fileext = ".csv")
    writeLines("name,score\nJane,99\nJohn,NA", tmp)
    expect_message(read_clean_csv(tmp, drop_na = "score"))
})

# -- summary argument ----------------------------------------------------------

test_that("read_clean_csv() summary = TRUE emits a message", {
    tmp <- tempfile(fileext = ".csv")
    writeLines("First Name,score\nJane,99\nJohn,88", tmp)
    expect_message(read_clean_csv(tmp, summary = TRUE))
})

test_that("read_clean_csv() summary = FALSE emits no message", {
    tmp <- tempfile(fileext = ".csv")
    writeLines("First Name,score\nJane,99\nJohn,88", tmp)
    expect_no_message(read_clean_csv(tmp, summary = FALSE))
})

test_that("read_clean_csv() summary does not affect returned data", {
    tmp <- tempfile(fileext = ".csv")
    writeLines("First Name,score\nJane,99\nJohn,88", tmp)
    result_with    <- suppressMessages(read_clean_csv(tmp, summary = TRUE))
    result_without <- read_clean_csv(tmp, summary = FALSE)
    expect_equal(result_with, result_without)
})
