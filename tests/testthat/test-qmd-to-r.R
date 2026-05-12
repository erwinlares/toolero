# -- helper --------------------------------------------------------------------

make_qmd <- function(path, chunks = TRUE) {
    lines <- c(
        "---",
        "title: Test Document",
        "---",
        "",
        "Some prose."
    )
    if (chunks) {
        lines <- c(lines,
                   "",
                   "```{r}",
                   "x <- 1 + 1",
                   "```",
                   "",
                   "```{r}",
                   "y <- x * 2",
                   "```"
        )
    }
    writeLines(lines, path)
    path
}

# -- input validation ----------------------------------------------------------

test_that("qmd_to_r() errors on non-existent file", {
    expect_error(
        qmd_to_r(input = "nonexistent.qmd"),
        info = "should error when input file does not exist"
    )
})

test_that("qmd_to_r() errors on non-character input", {
    expect_error(
        qmd_to_r(input = 123),
        info = "should error when input is not a character string"
    )
})

test_that("qmd_to_r() errors when input is not a .qmd file", {
    tmp <- tempfile(fileext = ".R")
    writeLines("x <- 1", tmp)
    expect_error(
        qmd_to_r(input = tmp),
        info = "should error when input does not have .qmd extension"
    )
})

test_that("qmd_to_r() errors on invalid documentation value", {
    tmp <- tempfile(fileext = ".qmd")
    make_qmd(tmp)
    expect_error(
        qmd_to_r(input = tmp, documentation = 5L),
        info = "should error when documentation is not 0, 1, or 2"
    )
})

test_that("qmd_to_r() errors on non-character output", {
    tmp <- tempfile(fileext = ".qmd")
    make_qmd(tmp)
    expect_error(
        qmd_to_r(input = tmp, output = 123),
        info = "should error when output is not a character string"
    )
})

# -- output path resolution ----------------------------------------------------

test_that("qmd_to_r() defaults output to same directory with .R extension", {
    tmp <- tempfile(fileext = ".qmd")
    make_qmd(tmp)
    expected_output <- fs::path_ext_set(tmp, "R")
    result <- qmd_to_r(input = tmp)
    expect_equal(result, expected_output)
    expect_true(fs::file_exists(expected_output))
})

test_that("qmd_to_r() respects explicit output path", {
    tmp_in  <- tempfile(fileext = ".qmd")
    tmp_out <- tempfile(fileext = ".R")
    make_qmd(tmp_in)
    result <- qmd_to_r(input = tmp_in, output = tmp_out)
    expect_equal(result, tmp_out)
    expect_true(fs::file_exists(tmp_out))
})

# -- return value --------------------------------------------------------------

test_that("qmd_to_r() returns output path invisibly", {
    tmp <- tempfile(fileext = ".qmd")
    make_qmd(tmp)
    expect_invisible(qmd_to_r(input = tmp))
})

test_that("qmd_to_r() returned path matches the output file", {
    tmp_in  <- tempfile(fileext = ".qmd")
    tmp_out <- tempfile(fileext = ".R")
    make_qmd(tmp_in)
    result <- qmd_to_r(input = tmp_in, output = tmp_out)
    expect_equal(result, tmp_out)
})

# -- output content ------------------------------------------------------------

test_that("qmd_to_r() produces a non-empty .R file", {
    tmp_in  <- tempfile(fileext = ".qmd")
    tmp_out <- tempfile(fileext = ".R")
    make_qmd(tmp_in)
    qmd_to_r(input = tmp_in, output = tmp_out)
    content <- readLines(tmp_out)
    expect_true(length(content) > 0)
})

test_that("qmd_to_r() extracted script contains code from chunks", {
    tmp_in  <- tempfile(fileext = ".qmd")
    tmp_out <- tempfile(fileext = ".R")
    make_qmd(tmp_in)
    qmd_to_r(input = tmp_in, output = tmp_out)
    content <- paste(readLines(tmp_out), collapse = "\n")
    expect_true(grepl("x <- 1 + 1", content, fixed = TRUE))
    expect_true(grepl("y <- x * 2", content, fixed = TRUE))
})

test_that("qmd_to_r() with documentation = 0 produces minimal output", {
    tmp_in   <- tempfile(fileext = ".qmd")
    tmp_out0 <- tempfile(fileext = ".R")
    tmp_out1 <- tempfile(fileext = ".R")
    make_qmd(tmp_in)
    qmd_to_r(input = tmp_in, output = tmp_out0, documentation = 0L)
    qmd_to_r(input = tmp_in, output = tmp_out1, documentation = 1L)
    lines0 <- readLines(tmp_out0)
    lines1 <- readLines(tmp_out1)
    expect_true(length(lines0) <= length(lines1))
})

test_that("qmd_to_r() handles .qmd with no R chunks", {
    tmp_in  <- tempfile(fileext = ".qmd")
    tmp_out <- tempfile(fileext = ".R")
    make_qmd(tmp_in, chunks = FALSE)
    expect_error(
        qmd_to_r(input = tmp_in, output = tmp_out),
        NA,
        info = "should not error on a .qmd with no R chunks"
    )
    expect_true(fs::file_exists(tmp_out))
})

# -- cli output ----------------------------------------------------------------

test_that("qmd_to_r() emits a success message", {
    tmp_in  <- tempfile(fileext = ".qmd")
    tmp_out <- tempfile(fileext = ".R")
    make_qmd(tmp_in)
    expect_message(qmd_to_r(input = tmp_in, output = tmp_out))
})
