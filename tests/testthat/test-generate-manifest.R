# tests/testthat/test-generate-manifest.R

# -- helpers -------------------------------------------------------------------

make_accumulator <- function(output_dir, rows) {
    fs::dir_create(output_dir)
    utils::write.table(
        rows[, .accumulator_columns(), drop = FALSE],
        file      = fs::path(output_dir, "accumulator.csv"),
        sep       = ",",
        row.names = FALSE,
        col.names = TRUE,
        quote     = TRUE,
        qmethod   = "double",
        na        = ""
    )
    output_dir
}

make_row <- function(file_path     = "output/x.rds",
                     r_class       = "data.frame",
                     timestamp     = "2026-08-27T12:00:00.000Z",
                     function_used = "saveRDS",
                     status        = "success",
                     error_message = NA_character_,
                     note          = NA_character_) {
    data.frame(
        file_path     = file_path,
        r_class       = r_class,
        timestamp     = timestamp,
        function_used = function_used,
        status        = status,
        error_message = error_message,
        note          = note,
        stringsAsFactors = FALSE
    )
}

read_manifest <- function(output_dir, filename = "project-manifest.json") {
    jsonlite::fromJSON(
        fs::path(output_dir, filename),
        simplifyVector = FALSE
    )
}

# -- .read_accumulator() -------------------------------------------------------

test_that(".read_accumulator() errors when the accumulator is missing", {
    root <- withr::local_tempdir()

    expect_error(
        .read_accumulator(root),
        info = "a missing accumulator is a setup problem, not an empty result"
    )
})

test_that(".read_accumulator() returns all columns as character", {
    root <- withr::local_tempdir()
    make_accumulator(root, make_row())

    accumulator <- .read_accumulator(root)

    expect_true(all(vapply(accumulator, is.character, logical(1L))))
})

test_that(".read_accumulator() recovers NA rather than empty strings", {
    root <- withr::local_tempdir()
    make_accumulator(root, make_row(error_message = NA_character_))

    accumulator <- .read_accumulator(root)

    expect_true(is.na(accumulator$error_message))
})

test_that(".read_accumulator() preserves the timestamp string exactly", {
    root <- withr::local_tempdir()
    make_accumulator(root, make_row(timestamp = "2026-08-27T12:00:00.123Z"))

    expect_equal(.read_accumulator(root)$timestamp, "2026-08-27T12:00:00.123Z")
})

test_that(".read_accumulator() rejects a mismatched schema", {
    root <- withr::local_tempdir()
    fs::dir_create(root)
    utils::write.csv(
        data.frame(wrong = "schema", stringsAsFactors = FALSE),
        fs::path(root, "accumulator.csv"),
        row.names = FALSE
    )

    expect_error(.read_accumulator(root))
})

# -- .dedupe_accumulator() -----------------------------------------------------

test_that(".dedupe_accumulator() passes a zero-row frame through", {
    empty <- make_row()[0L, , drop = FALSE]

    expect_equal(nrow(.dedupe_accumulator(empty)), 0L)
})

test_that(".dedupe_accumulator() passes a single row through", {
    expect_equal(nrow(.dedupe_accumulator(make_row())), 1L)
})

test_that(".dedupe_accumulator() keeps distinct paths", {
    rows <- rbind(
        make_row(file_path = "a.rds"),
        make_row(file_path = "b.rds")
    )

    expect_equal(nrow(.dedupe_accumulator(rows)), 2L)
})

test_that(".dedupe_accumulator() keeps the latest row per path", {
    rows <- rbind(
        make_row(file_path = "a.rds", timestamp = "2026-08-27T12:00:00.000Z",
                 note = "first"),
        make_row(file_path = "a.rds", timestamp = "2026-08-27T13:00:00.000Z",
                 note = "second")
    )

    result <- .dedupe_accumulator(rows)

    expect_equal(nrow(result), 1L)
    expect_equal(result$note, "second")
})

test_that(".dedupe_accumulator() ignores file order when timestamps disagree", {
    rows <- rbind(
        make_row(file_path = "a.rds", timestamp = "2026-08-27T13:00:00.000Z",
                 note = "later"),
        make_row(file_path = "a.rds", timestamp = "2026-08-27T12:00:00.000Z",
                 note = "earlier")
    )

    expect_equal(.dedupe_accumulator(rows)$note, "later")
})

test_that(".dedupe_accumulator() breaks timestamp ties by append order", {
    rows <- rbind(
        make_row(file_path = "a.rds", timestamp = "2026-08-27T12:00:00.000Z",
                 note = "first"),
        make_row(file_path = "a.rds", timestamp = "2026-08-27T12:00:00.000Z",
                 note = "second")
    )

    expect_equal(.dedupe_accumulator(rows)$note, "second")
})

test_that(".dedupe_accumulator() lets a later failure supersede an earlier success", {
    rows <- rbind(
        make_row(file_path = "a.rds", timestamp = "2026-08-27T12:00:00.000Z",
                 status = "success"),
        make_row(file_path = "a.rds", timestamp = "2026-08-27T13:00:00.000Z",
                 status = "failure", error_message = "disk full")
    )

    result <- .dedupe_accumulator(rows)

    expect_equal(result$status, "failure")
})

test_that(".dedupe_accumulator() orders surviving rows chronologically", {
    rows <- rbind(
        make_row(file_path = "b.rds", timestamp = "2026-08-27T13:00:00.000Z"),
        make_row(file_path = "a.rds", timestamp = "2026-08-27T12:00:00.000Z")
    )

    expect_equal(.dedupe_accumulator(rows)$file_path, c("a.rds", "b.rds"))
})

test_that(".dedupe_accumulator() sorts millisecond precision correctly", {
    rows <- rbind(
        make_row(file_path = "a.rds", timestamp = "2026-08-27T12:00:00.900Z",
                 note = "earlier"),
        make_row(file_path = "a.rds", timestamp = "2026-08-27T12:00:01.100Z",
                 note = "later")
    )

    expect_equal(.dedupe_accumulator(rows)$note, "later")
})

# -- generate_manifest() input validation --------------------------------------

test_that("generate_manifest() errors when output_dir is not a single string", {
    expect_error(generate_manifest(output_dir = c("a", "b")))
})

test_that("generate_manifest() errors when filename is not a single string", {
    root <- withr::local_tempdir()
    make_accumulator(root, make_row())

    expect_error(generate_manifest(output_dir = root, filename = c("a", "b")))
})

test_that("generate_manifest() errors when overwrite is not a single logical", {
    root <- withr::local_tempdir()
    make_accumulator(root, make_row())

    expect_error(generate_manifest(output_dir = root, overwrite = NA))
})

# -- generate_manifest() writing behavior --------------------------------------

test_that("generate_manifest() writes the manifest file", {
    root <- withr::local_tempdir()
    make_accumulator(root, make_row())

    suppressMessages(generate_manifest(output_dir = root))

    expect_true(fs::file_exists(fs::path(root, "project-manifest.json")))
})

test_that("generate_manifest() returns the path invisibly", {
    root <- withr::local_tempdir()
    make_accumulator(root, make_row())

    expect_invisible(suppressMessages(generate_manifest(output_dir = root)))
})

test_that("generate_manifest() honours a custom filename", {
    root <- withr::local_tempdir()
    make_accumulator(root, make_row())

    suppressMessages(generate_manifest(output_dir = root, filename = "custom.json"))

    expect_true(fs::file_exists(fs::path(root, "custom.json")))
})

test_that("generate_manifest() records execution_context once at the top level", {
    root <- withr::local_tempdir()
    make_accumulator(root, make_row())

    suppressMessages(generate_manifest(output_dir = root))

    manifest <- read_manifest(root)

    expect_true("execution_context" %in% names(manifest))
    expect_length(manifest$execution_context, 1L)
})

test_that("generate_manifest() records generated_at once at the top level", {
    root <- withr::local_tempdir()
    make_accumulator(root, make_row())

    suppressMessages(generate_manifest(output_dir = root))

    manifest <- read_manifest(root)

    expect_true("generated_at" %in% names(manifest))
    expect_match(
        manifest$generated_at,
        "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\.\\d{3}Z$"
    )
})

test_that("generate_manifest() writes one artifact entry per deduplicated row", {
    root <- withr::local_tempdir()
    make_accumulator(root, rbind(
        make_row(file_path = "a.rds"),
        make_row(file_path = "b.rds", timestamp = "2026-08-27T13:00:00.000Z")
    ))

    suppressMessages(generate_manifest(output_dir = root))

    expect_length(read_manifest(root)$artifacts, 2L)
})

test_that("generate_manifest() carries all accumulator fields into artifacts", {
    root <- withr::local_tempdir()
    make_accumulator(root, make_row())

    suppressMessages(generate_manifest(output_dir = root))

    artifact <- read_manifest(root)$artifacts[[1L]]

    expect_setequal(names(artifact), .accumulator_columns())
})

test_that("generate_manifest() deduplicates before writing", {
    root <- withr::local_tempdir()
    make_accumulator(root, rbind(
        make_row(file_path = "a.rds", timestamp = "2026-08-27T12:00:00.000Z"),
        make_row(file_path = "a.rds", timestamp = "2026-08-27T13:00:00.000Z")
    ))

    suppressMessages(generate_manifest(output_dir = root))

    expect_length(read_manifest(root)$artifacts, 1L)
})

test_that("generate_manifest() excludes checksum and RO-Crate fields", {
    root <- withr::local_tempdir()
    make_accumulator(root, make_row())

    suppressMessages(generate_manifest(output_dir = root))

    artifact <- read_manifest(root)$artifacts[[1L]]

    expect_false("checksum" %in% names(artifact))
    expect_false("@id" %in% names(artifact))
    expect_false("dateCreated" %in% names(artifact))
})

# -- overwrite behavior --------------------------------------------------------

test_that("generate_manifest() errors when the manifest exists and overwrite is FALSE", {
    root <- withr::local_tempdir()
    make_accumulator(root, make_row())
    suppressMessages(generate_manifest(output_dir = root))

    expect_error(
        generate_manifest(output_dir = root),
        info = "should refuse to replace an existing manifest by default"
    )
})

test_that("generate_manifest() replaces the manifest when overwrite is TRUE", {
    root <- withr::local_tempdir()
    make_accumulator(root, make_row(file_path = "a.rds"))
    suppressMessages(generate_manifest(output_dir = root))

    make_accumulator(root, rbind(
        make_row(file_path = "a.rds"),
        make_row(file_path = "b.rds", timestamp = "2026-08-27T13:00:00.000Z")
    ))

    suppressMessages(generate_manifest(output_dir = root, overwrite = TRUE))

    expect_length(read_manifest(root)$artifacts, 2L)
})

# -- empty accumulator ---------------------------------------------------------

test_that("generate_manifest() warns on an accumulator with no rows", {
    root <- withr::local_tempdir()
    make_accumulator(root, make_row()[0L, , drop = FALSE])

    expect_warning(
        generate_manifest(output_dir = root),
        info = "an empty accumulator is still a truthful record"
    )
})

test_that("generate_manifest() still writes a manifest when the accumulator is empty", {
    root <- withr::local_tempdir()
    make_accumulator(root, make_row()[0L, , drop = FALSE])

    suppressWarnings(suppressMessages(generate_manifest(output_dir = root)))

    expect_true(fs::file_exists(fs::path(root, "project-manifest.json")))
})

test_that("generate_manifest() writes an empty artifacts array, not an object", {
    root <- withr::local_tempdir()
    make_accumulator(root, make_row()[0L, , drop = FALSE])

    suppressWarnings(suppressMessages(generate_manifest(output_dir = root)))

    raw <- paste(readLines(fs::path(root, "project-manifest.json")), collapse = "")

    expect_match(raw, "\"artifacts\"\\s*:\\s*\\[\\s*\\]")
})

test_that("generate_manifest() errors when no accumulator exists at all", {
    root <- withr::local_tempdir()

    expect_error(
        generate_manifest(output_dir = root),
        info = "distinct from an accumulator that exists but holds no rows"
    )
})

# -- reporting -----------------------------------------------------------------

test_that("generate_manifest() reports the artifact count", {
    root <- withr::local_tempdir()
    make_accumulator(root, make_row())

    expect_message(generate_manifest(output_dir = root))
})

test_that("generate_manifest() reports recorded failures", {
    root <- withr::local_tempdir()
    make_accumulator(root, make_row(status = "failure", error_message = "disk full"))

    expect_message(generate_manifest(output_dir = root), regexp = "fail")
})

# -- end-to-end ----------------------------------------------------------------

test_that("save_output() and generate_manifest() compose", {
    root <- withr::local_tempdir()

    save_output(mtcars, fs::path(root, "a.rds"), .f = saveRDS, output_dir = root)
    save_output(iris,   fs::path(root, "b.rds"), .f = saveRDS, output_dir = root)

    suppressMessages(generate_manifest(output_dir = root))

    manifest <- read_manifest(root)

    expect_length(manifest$artifacts, 2L)
    expect_true(all(vapply(
        manifest$artifacts,
        function(a) a$status == "success",
        logical(1L)
    )))
})

test_that("a failed save survives into the manifest", {
    root <- withr::local_tempdir()
    boom <- function(object, file_path) stop("write failed")

    save_output(mtcars, fs::path(root, "a.rds"), .f = saveRDS, output_dir = root)
    expect_error(
        save_output(iris, fs::path(root, "b.rds"), .f = boom, output_dir = root)
    )

    suppressMessages(generate_manifest(output_dir = root))

    statuses <- vapply(
        read_manifest(root)$artifacts,
        function(a) a$status,
        character(1L)
    )

    expect_setequal(statuses, c("success", "failure"))
})
