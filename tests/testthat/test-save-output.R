# tests/testthat/test-save-output.R

# -- helpers -------------------------------------------------------------------

make_output_dir <- function(root, name = "output") {
    dir <- fs::path(root, name)
    fs::dir_create(dir)
    dir
}

read_accumulator_file <- function(output_dir) {
    utils::read.csv(
        fs::path(output_dir, "accumulator.csv"),
        colClasses      = "character",
        na.strings      = "",
        check.names     = FALSE,
        stringsAsFactors = FALSE
    )
}

# -- .capture_function_name() --------------------------------------------------

test_that(".capture_function_name() returns a bare function name unchanged", {
    expect_equal(.capture_function_name("saveRDS"), "saveRDS")
})

test_that(".capture_function_name() preserves namespaced calls", {
    expect_equal(.capture_function_name("ggplot2::ggsave"), "ggplot2::ggsave")
})

test_that(".capture_function_name() labels a single-line anonymous function", {
    result <- .capture_function_name("function(x, p) saveRDS(x, p)")

    expect_true(grepl("^anonymous function: ", result))
    expect_length(result, 1L)
})

test_that(".capture_function_name() collapses a multi-line anonymous function", {
    f_expr <- c("function(x, p) {", "    saveRDS(x, p)", "}")

    result <- .capture_function_name(f_expr)

    expect_length(result, 1L)
    expect_false(grepl("\n", result, fixed = TRUE))
})

test_that(".capture_function_name() truncates a long anonymous function", {
    f_expr <- paste0("function(x, p) ", strrep("a", 500L))

    result <- .capture_function_name(f_expr, max_chars = 50L)

    expect_true(nchar(result) < 100L)
    expect_true(grepl("\\.\\.\\.$", result))
})

test_that(".capture_function_name() does not truncate a short label", {
    result <- .capture_function_name("function(x, p) saveRDS(x, p)", max_chars = 200L)

    expect_false(grepl("\\.\\.\\.$", result))
})

# -- .flatten_field() ----------------------------------------------------------

test_that(".flatten_field() returns NA for NULL", {
    expect_true(is.na(.flatten_field(NULL)))
})

test_that(".flatten_field() returns NA for a zero-length vector", {
    expect_true(is.na(.flatten_field(character(0))))
})

test_that(".flatten_field() collapses newlines to single spaces", {
    expect_equal(.flatten_field("one\ntwo"), "one two")
})

test_that(".flatten_field() collapses runs of whitespace", {
    expect_equal(.flatten_field("one    two"), "one two")
})

test_that(".flatten_field() trims leading and trailing whitespace", {
    expect_equal(.flatten_field("  padded  "), "padded")
})

# -- .ensure_directory() -------------------------------------------------------

test_that(".ensure_directory() creates a missing directory", {
    root   <- withr::local_tempdir()
    target <- fs::path(root, "nested", "deeper", "file.rds")

    suppressMessages(.ensure_directory(target))

    expect_true(fs::dir_exists(fs::path(root, "nested", "deeper")))
})

test_that(".ensure_directory() reports when it creates a directory", {
    root   <- withr::local_tempdir()
    target <- fs::path(root, "nested", "file.rds")

    expect_message(.ensure_directory(target))
})

test_that(".ensure_directory() is silent when the directory exists", {
    root   <- withr::local_tempdir()
    target <- fs::path(root, "file.rds")

    expect_no_message(.ensure_directory(target))
})

test_that(".ensure_directory() is silent for a bare filename", {
    expect_no_message(.ensure_directory("file.rds"))
})

# -- save_output() input validation --------------------------------------------

test_that("save_output() errors when .f is missing", {
    root <- withr::local_tempdir()

    expect_error(
        save_output(mtcars, fs::path(root, "x.rds"), output_dir = root),
        info = "should error when .f is not supplied"
    )
})

test_that("save_output() errors when .f is not a function", {
    root <- withr::local_tempdir()

    expect_error(
        save_output(mtcars, fs::path(root, "x.rds"), .f = "saveRDS", output_dir = root),
        info = "should error when .f is a string rather than a function"
    )
})

test_that("save_output() errors when file_path is not a single string", {
    root <- withr::local_tempdir()

    expect_error(
        save_output(mtcars, c("a.rds", "b.rds"), .f = saveRDS, output_dir = root),
        info = "should error on a file_path vector of length > 1"
    )
})

test_that("save_output() errors when file_path is NA", {
    root <- withr::local_tempdir()

    expect_error(
        save_output(mtcars, NA_character_, .f = saveRDS, output_dir = root),
        info = "should error on a missing file_path"
    )
})

test_that("save_output() errors when manifest is not a single logical", {
    root <- withr::local_tempdir()

    expect_error(
        save_output(mtcars, fs::path(root, "x.rds"), .f = saveRDS,
                    manifest = NA, output_dir = root),
        info = "should error on a non-boolean manifest"
    )
})

test_that("save_output() errors when note is not a single string", {
    root <- withr::local_tempdir()

    expect_error(
        save_output(mtcars, fs::path(root, "x.rds"), .f = saveRDS,
                    note = c("a", "b"), output_dir = root),
        info = "should error on a note vector of length > 1"
    )
})

# -- save_output() writing behavior --------------------------------------------

test_that("save_output() writes the object via .f", {
    root <- withr::local_tempdir()
    dest <- fs::path(root, "mtcars.rds")

    save_output(mtcars, dest, .f = saveRDS, output_dir = root)

    expect_true(fs::file_exists(dest))
    expect_equal(readRDS(dest), mtcars)
})

test_that("save_output() returns the object invisibly", {
    root <- withr::local_tempdir()

    expect_invisible(
        save_output(mtcars, fs::path(root, "x.rds"), .f = saveRDS, output_dir = root)
    )
})

test_that("save_output() returns the object unchanged", {
    root   <- withr::local_tempdir()
    result <- save_output(mtcars, fs::path(root, "x.rds"), .f = saveRDS,
                          output_dir = root)

    expect_equal(result, mtcars)
})

test_that("save_output() passes ... through to .f", {
    root <- withr::local_tempdir()
    dest <- fs::path(root, "mtcars.csv")

    save_output(mtcars, dest, .f = write.csv, row.names = FALSE, output_dir = root)

    first_line <- readLines(dest, n = 1L)
    expect_false(grepl('^""', first_line))
})

test_that("save_output() creates a missing destination directory", {
    root <- withr::local_tempdir()
    dest <- fs::path(root, "figures", "plot.rds")

    suppressMessages(
        save_output(mtcars, dest, .f = saveRDS, output_dir = root)
    )

    expect_true(fs::file_exists(dest))
})

# -- accumulator recording -----------------------------------------------------

test_that("save_output() creates the accumulator on first call", {
    root <- withr::local_tempdir()

    save_output(mtcars, fs::path(root, "x.rds"), .f = saveRDS, output_dir = root)

    expect_true(fs::file_exists(fs::path(root, "accumulator.csv")))
})

test_that("save_output() writes the expected accumulator schema", {
    root <- withr::local_tempdir()

    save_output(mtcars, fs::path(root, "x.rds"), .f = saveRDS, output_dir = root)

    accumulator <- read_accumulator_file(root)

    expect_named(accumulator, .accumulator_columns())
})

test_that("save_output() records one row per call", {
    root <- withr::local_tempdir()

    save_output(mtcars, fs::path(root, "a.rds"), .f = saveRDS, output_dir = root)
    save_output(mtcars, fs::path(root, "b.rds"), .f = saveRDS, output_dir = root)

    expect_equal(nrow(read_accumulator_file(root)), 2L)
})

test_that("save_output() records a successful write", {
    root <- withr::local_tempdir()

    save_output(mtcars, fs::path(root, "x.rds"), .f = saveRDS, output_dir = root)

    accumulator <- read_accumulator_file(root)

    expect_equal(accumulator$status, "success")
    expect_true(is.na(accumulator$error_message))
})

test_that("save_output() records the function name", {
    root <- withr::local_tempdir()

    save_output(mtcars, fs::path(root, "x.rds"), .f = saveRDS, output_dir = root)

    expect_equal(read_accumulator_file(root)$function_used, "saveRDS")
})

test_that("save_output() records a namespaced function name", {
    root <- withr::local_tempdir()

    save_output(mtcars, fs::path(root, "x.rds"), .f = base::saveRDS, output_dir = root)

    expect_equal(read_accumulator_file(root)$function_used, "base::saveRDS")
})

test_that("save_output() records an anonymous function distinctly", {
    root <- withr::local_tempdir()

    save_output(
        mtcars,
        fs::path(root, "x.rds"),
        .f         = function(object, file_path) saveRDS(object, file_path),
        output_dir = root
    )

    function_used <- read_accumulator_file(root)$function_used

    expect_true(grepl("^anonymous function: ", function_used))
})

test_that("save_output() records multi-class objects as a pipe-separated field", {
    skip_if_not_installed("tibble")

    root <- withr::local_tempdir()
    tbl  <- tibble::as_tibble(mtcars)

    save_output(tbl, fs::path(root, "x.rds"), .f = saveRDS, output_dir = root)

    r_class <- read_accumulator_file(root)$r_class

    expect_equal(r_class, paste(class(tbl), collapse = "|"))
    expect_true(grepl("|", r_class, fixed = TRUE))
})

test_that("save_output() records a single-class object without a separator", {
    root <- withr::local_tempdir()

    save_output(mtcars, fs::path(root, "x.rds"), .f = saveRDS, output_dir = root)

    expect_equal(read_accumulator_file(root)$r_class, "data.frame")
})

test_that("save_output() records the note when supplied", {
    root <- withr::local_tempdir()

    save_output(mtcars, fs::path(root, "x.rds"), .f = saveRDS,
                note = "Unmodified example data.", output_dir = root)

    expect_equal(read_accumulator_file(root)$note, "Unmodified example data.")
})

test_that("save_output() records NA for an absent note", {
    root <- withr::local_tempdir()

    save_output(mtcars, fs::path(root, "x.rds"), .f = saveRDS, output_dir = root)

    expect_true(is.na(read_accumulator_file(root)$note))
})

test_that("save_output() flattens a multi-line note to one line", {
    root <- withr::local_tempdir()

    save_output(mtcars, fs::path(root, "x.rds"), .f = saveRDS,
                note = "first\nsecond", output_dir = root)

    expect_equal(read_accumulator_file(root)$note, "first second")
})

test_that("save_output() writes a UTC timestamp with millisecond precision", {
    root <- withr::local_tempdir()

    save_output(mtcars, fs::path(root, "x.rds"), .f = saveRDS, output_dir = root)

    timestamp <- read_accumulator_file(root)$timestamp

    expect_match(timestamp, "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\.\\d{3}Z$")
})

test_that("save_output() records nothing when manifest = FALSE", {
    root <- withr::local_tempdir()

    save_output(mtcars, fs::path(root, "x.rds"), .f = saveRDS,
                manifest = FALSE, output_dir = root)

    expect_false(fs::file_exists(fs::path(root, "accumulator.csv")))
})

test_that("save_output() still writes the object when manifest = FALSE", {
    root <- withr::local_tempdir()
    dest <- fs::path(root, "x.rds")

    save_output(mtcars, dest, .f = saveRDS, manifest = FALSE, output_dir = root)

    expect_true(fs::file_exists(dest))
})

# -- failure handling ----------------------------------------------------------

test_that("save_output() records a failed write before rethrowing", {
    root   <- withr::local_tempdir()
    boom   <- function(object, file_path) stop("write failed")

    expect_error(
        save_output(mtcars, fs::path(root, "x.rds"), .f = boom, output_dir = root)
    )

    accumulator <- read_accumulator_file(root)

    expect_equal(nrow(accumulator), 1L)
    expect_equal(accumulator$status, "failure")
    expect_equal(accumulator$error_message, "write failed")
})

test_that("save_output() rethrows the original condition class", {
    root <- withr::local_tempdir()

    boom <- function(object, file_path) {
        rlang::abort("write failed", class = "my_custom_write_error")
    }

    expect_error(
        save_output(mtcars, fs::path(root, "x.rds"), .f = boom, output_dir = root),
        class = "my_custom_write_error"
    )
})

test_that("save_output() rethrows the original condition message", {
    root <- withr::local_tempdir()
    boom <- function(object, file_path) stop("a very specific failure")

    expect_error(
        save_output(mtcars, fs::path(root, "x.rds"), .f = boom, output_dir = root),
        regexp = "a very specific failure"
    )
})

test_that("save_output() flattens a multi-line error message", {
    root <- withr::local_tempdir()
    boom <- function(object, file_path) stop("first line\nsecond line")

    expect_error(
        save_output(mtcars, fs::path(root, "x.rds"), .f = boom, output_dir = root)
    )

    error_message <- read_accumulator_file(root)$error_message

    expect_false(grepl("\n", error_message, fixed = TRUE))
})

test_that("save_output() records nothing on failure when manifest = FALSE", {
    root <- withr::local_tempdir()
    boom <- function(object, file_path) stop("write failed")

    expect_error(
        save_output(mtcars, fs::path(root, "x.rds"), .f = boom,
                    manifest = FALSE, output_dir = root)
    )

    expect_false(fs::file_exists(fs::path(root, "accumulator.csv")))
})

# -- .append_accumulator_row() -------------------------------------------------

test_that(".append_accumulator_row() rejects a mismatched existing schema", {
    root <- withr::local_tempdir()
    dir  <- make_output_dir(root)

    utils::write.csv(
        data.frame(wrong = "schema", stringsAsFactors = FALSE),
        fs::path(dir, "accumulator.csv"),
        row.names = FALSE
    )

    row <- data.frame(
        file_path     = "x.rds",
        r_class       = "data.frame",
        timestamp     = "2026-08-27T00:00:00.000Z",
        function_used = "saveRDS",
        status        = "success",
        error_message = NA_character_,
        note          = NA_character_,
        stringsAsFactors = FALSE
    )

    expect_error(
        .append_accumulator_row(row, output_dir = dir),
        info = "should abort rather than append under a different schema"
    )
})

test_that("save_output() round-trips a file path containing a comma", {
    root <- withr::local_tempdir()
    dest <- fs::path(root, "a,b.rds")

    save_output(mtcars, dest, .f = saveRDS, output_dir = root)

    expect_equal(read_accumulator_file(root)$file_path, as.character(dest))
})
