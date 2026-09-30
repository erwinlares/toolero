# tests/testthat/test-read-output-records.R
#
# read_output_records() -- the reader for the output record (T37). The
# fixtures under fixtures/output-records/ are the reference examples named
# in CONVENTIONS.md section 7.

fixture <- function(...) {
    testthat::test_path("fixtures", "output-records", ...)
}

# Copy a fixture into a fresh output folder under the name the reader
# looks for, optionally alongside the accumulator-only fixture.
fixture_folder <- function(json = NULL, accumulator = FALSE, env = parent.frame()) {
    dir <- withr::local_tempdir(.local_envir = env)
    if (!is.null(json)) {
        fs::file_copy(fixture(json), fs::path(dir, "project-manifest.json"))
    }
    if (accumulator) {
        fs::file_copy(
            fixture("accumulator-only", "accumulator.csv"),
            fs::path(dir, "accumulator.csv")
        )
    }
    dir
}

expected_columns <- c(
    "source", "file_path", "r_class", "timestamp", "function_used",
    "status", "error_message", "note", "read_from", "schema_version",
    "execution_context", "generated_at", "commit"
)

# Warning messages are matched on single words: cli wraps long messages,
# and a temporary path early in the line makes the wrap point unpredictable.

# -- argument validation -------------------------------------------------------

test_that("read_output_records() rejects a path that is not a character vector", {
    expect_error(read_output_records(path = 1), "must be a character vector")
    expect_error(read_output_records(path = character(0)), "must be a character vector")
    expect_error(read_output_records(path = NA_character_), "must be a character vector")
    expect_error(read_output_records(path = ""), "must be a character vector")
})

test_that("read_output_records() rejects a bad filename", {
    dir <- fixture_folder("good.json")
    expect_error(read_output_records(dir, filename = c("a", "b")), "filename")
    expect_error(read_output_records(dir, filename = ""), "filename")
})

test_that("read_output_records() errors on a path that does not exist, naming it", {
    dir <- fixture_folder("good.json")
    missing <- fs::path(dir, "no-such-folder")
    expect_error(read_output_records(c(dir, missing)), "no-such-folder")
})

# -- reading version 1 records -------------------------------------------------

test_that("read_output_records() reads the good fixture, one row per artifact", {
    result <- read_output_records(fixture("good.json"))

    expect_s3_class(result, "tbl_df")
    expect_named(result, expected_columns)
    expect_equal(nrow(result), 2L)

    expect_equal(result$file_path, c("output/tables/summary.csv", "output/figures/mass.png"))
    expect_equal(result$r_class, c("tbl_df|tbl|data.frame", "gg|ggplot"))
    expect_equal(result$function_used, c("readr::write_csv", "ggplot2::ggsave"))
    expect_equal(result$status, c("success", "failure"))
    expect_equal(result$error_message, c(NA, "cannot open file 'output/figures/mass.png'"))
    expect_equal(result$note, c("Per-species summary.", NA))
    expect_equal(result$timestamp, c("2026-09-29T18:04:10.101Z", "2026-09-29T18:04:11.202Z"))

    expect_equal(result$read_from, rep("output record", 2))
    expect_identical(result$schema_version, c(1L, 1L))
    expect_equal(result$execution_context, rep("rscript", 2))
    expect_equal(result$generated_at, rep("2026-09-29T18:04:12.345Z", 2))
    expect_equal(result$commit, rep("3f2a9c1e8b7d6a5f4e3d2c1b0a9f8e7d6c5b4a39", 2))
})

test_that("read_output_records() finds project-manifest.json inside a folder", {
    dir    <- fixture_folder("good.json")
    result <- read_output_records(dir)

    expect_equal(nrow(result), 2L)
    expect_equal(result$source, rep(dir, 2))
})

test_that("read_output_records() honors a different filename", {
    dir <- withr::local_tempdir()
    fs::file_copy(fixture("good.json"), fs::path(dir, "record.json"))

    result <- read_output_records(dir, filename = "record.json")
    expect_equal(nrow(result), 2L)
})

test_that("read_output_records() returns no rows and no warning for an empty record", {
    expect_no_warning(result <- read_output_records(fixture("empty.json")))

    expect_named(result, expected_columns)
    expect_equal(nrow(result), 0L)
    expect_type(result$schema_version, "integer")
    expect_type(result$file_path, "character")
})

test_that("read_output_records() reads an unversioned record as version 1, quietly", {
    expect_no_warning(result <- read_output_records(fixture("unversioned.json")))

    expect_equal(nrow(result), 1L)
    expect_identical(result$schema_version, 1L)
    expect_equal(result$execution_context, "quarto")
    expect_equal(result$file_path, "output/model.rds")
    expect_true(is.na(result$commit))
})

# -- unknown versions ----------------------------------------------------------

test_that("read_output_records() reads a future version as far as it can, with a warning", {
    expect_warning(
        result <- read_output_records(fixture("future-version.json")),
        regexp = "99"
    )

    expect_equal(nrow(result), 1L)
    expect_identical(result$schema_version, 99L)
    expect_equal(result$file_path, "output/model.rds")
    expect_equal(result$r_class, "lm")
})

test_that("read_output_records() ignores keys and fields it does not know", {
    result <- suppressWarnings(read_output_records(fixture("future-version.json")))

    expect_named(result, expected_columns)
    expect_false("platform" %in% names(result))
    expect_false("bytes" %in% names(result))
})

test_that("read_output_records() turns a non-scalar field into NA rather than failing", {
    dir <- withr::local_tempdir()
    writeLines(
        '{"schema_version": 2, "commit": null, "artifacts": [
            {"file_path": "output/a.rds", "r_class": ["lm", "glm"], "status": "success"}
        ]}',
        fs::path(dir, "project-manifest.json")
    )

    result <- suppressWarnings(read_output_records(dir))

    expect_equal(result$file_path, "output/a.rds")
    expect_true(is.na(result$r_class))
    expect_true(is.na(result$execution_context))
    expect_true(is.na(result$timestamp))
})

# -- the accumulator fallback --------------------------------------------------

test_that("read_output_records() falls back to the accumulator when there is no record", {
    dir <- fixture_folder(accumulator = TRUE)

    expect_warning(
        result <- read_output_records(dir),
        regexp = "accumulator"
    )

    # Two rows for one file in the accumulator; the later one is kept.
    expect_equal(nrow(result), 1L)
    expect_equal(result$file_path, "output/model.rds")
    expect_equal(result$note, "Re-run after fixing the formula.")
    expect_equal(result$read_from, "accumulator")
    expect_identical(result$schema_version, NA_integer_)
    expect_true(is.na(result$execution_context))
    expect_true(is.na(result$generated_at))
    expect_true(is.na(result$commit))
})

test_that("read_output_records() falls back to the accumulator when the record is malformed", {
    dir <- fixture_folder("malformed.json", accumulator = TRUE)

    expect_warning(
        result <- read_output_records(dir),
        regexp = "JSON"
    )

    expect_equal(nrow(result), 1L)
    expect_equal(result$read_from, "accumulator")
})

test_that("read_output_records() prefers the record when both are present", {
    dir <- fixture_folder("good.json", accumulator = TRUE)

    expect_no_warning(result <- read_output_records(dir))
    expect_equal(nrow(result), 2L)
    expect_equal(result$read_from, rep("output record", 2))
})

test_that("read_output_records() warns and returns no rows for a malformed record alone", {
    dir <- fixture_folder("malformed.json")

    expect_warning(
        result <- read_output_records(dir),
        regexp = "Nothing was read"
    )
    expect_named(result, expected_columns)
    expect_equal(nrow(result), 0L)
})

test_that("read_output_records() warns and returns no rows for a folder with neither file", {
    dir <- withr::local_tempdir()

    expect_warning(
        result <- read_output_records(dir),
        regexp = "beside"
    )
    expect_equal(nrow(result), 0L)
})

test_that("read_output_records() warns rather than errors on an accumulator with the wrong columns", {
    dir <- withr::local_tempdir()
    writeLines(c('"a","b"', '"1","2"'), fs::path(dir, "accumulator.csv"))

    expect_warning(
        result <- read_output_records(dir),
        regexp = "either"
    )
    expect_equal(nrow(result), 0L)
})

test_that("read_output_records() treats structurally wrong records as unreadable", {
    cases <- c(
        not_object      = '[1, 2, 3]',
        string_version  = '{"schema_version": "1", "artifacts": []}',
        no_artifacts    = '{"schema_version": 1}',
        object_artifacts = '{"schema_version": 1, "artifacts": {}}',
        scalar_entry    = '{"schema_version": 1, "artifacts": ["output/a.rds"]}'
    )

    for (case in names(cases)) {
        dir <- withr::local_tempdir()
        writeLines(cases[[case]], fs::path(dir, "project-manifest.json"))

        expect_warning(
            result <- read_output_records(dir),
            regexp = "Nothing",
            info = case
        )
        expect_equal(nrow(result), 0L, info = case)
    }
})

# -- several folders -----------------------------------------------------------

test_that("read_output_records() stacks several folders and labels rows by name", {
    a <- fixture_folder("good.json")
    b <- fixture_folder("unversioned.json")

    result <- read_output_records(c(adelie = a, gentoo = b))

    expect_equal(nrow(result), 3L)
    expect_equal(result$source, c("adelie", "adelie", "gentoo"))
    expect_equal(result$execution_context, c("rscript", "rscript", "quarto"))
})

test_that("read_output_records() labels unnamed elements by their path", {
    a <- fixture_folder("good.json")
    b <- fixture_folder("unversioned.json")

    result <- read_output_records(c(adelie = a, b))
    expect_equal(result$source, c("adelie", "adelie", b))
})

test_that("read_output_records() keeps reading after one incomplete folder", {
    good  <- fixture_folder("good.json")
    empty <- withr::local_tempdir()
    acc   <- fixture_folder(accumulator = TRUE)

    warnings <- character(0)
    result <- withCallingHandlers(
        read_output_records(c(good = good, empty = empty, acc = acc)),
        warning = function(w) {
            warnings <<- c(warnings, conditionMessage(w))
            invokeRestart("muffleWarning")
        }
    )

    expect_length(warnings, 2L)
    expect_equal(result$source, c("good", "good", "acc"))
    expect_equal(result$read_from, c("output record", "output record", "accumulator"))
})

# -- round trip with save_output() and generate_manifest() ---------------------

save_six <- function(output_dir) {
    for (i in 1:6) {
        save_output(
            object     = mtcars[i, ],
            file_path  = fs::path(output_dir, sprintf("row-%d.rds", i)),
            .f         = saveRDS,
            output_dir = output_dir,
            note       = if (i == 1) "first" else NULL
        )
    }
    suppressMessages(generate_manifest(output_dir = output_dir, git_root = output_dir))
}

test_that("read_output_records() reads back what generate_manifest() wrote", {
    output_dir <- withr::local_tempdir()
    save_six(output_dir)

    result <- read_output_records(output_dir)

    expect_equal(nrow(result), 6L)
    expect_equal(result$status, rep("success", 6))
    expect_equal(result$function_used, rep("saveRDS", 6))
    expect_equal(result$r_class, rep("data.frame", 6))
    expect_equal(result$note, c("first", rep(NA, 5)))
    expect_true(all(is.na(result$error_message)))
    expect_identical(result$schema_version, rep(1L, 6))
    expect_true(all(is.na(result$commit)))
})

test_that("read_output_records() returns 18 rows from three six-artifact jobs", {
    # The shape of T37's done-when: three extracted minimal-project jobs
    # that each saved six artifacts. The real version runs on CHTC.
    jobs <- c(
        adelie    = withr::local_tempdir(),
        chinstrap = withr::local_tempdir(),
        gentoo    = withr::local_tempdir()
    )
    for (dir in jobs) save_six(dir)

    result <- read_output_records(jobs)

    expect_equal(nrow(result), 18L)
    expect_equal(as.vector(table(result$source)), c(6L, 6L, 6L))
    expect_setequal(unique(result$source), names(jobs))
})

test_that("read_output_records() defaults to the project's own output folder", {
    root <- withr::local_tempdir()
    fs::file_create(fs::path(root, ".here"))
    withr::local_dir(root)

    save_output(mtcars, "output/mtcars.rds", .f = saveRDS)
    suppressMessages(generate_manifest(git_root = root))

    result <- read_output_records()

    expect_equal(nrow(result), 1L)
    expect_equal(result$file_path, "output/mtcars.rds")
})
