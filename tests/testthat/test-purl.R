# tests/testthat/test-purl.R
#
# purl.R is not a package function -- it's a template (inst/templates/purl.R)
# that create_qmd() copies into a target project and Quarto sources as a
# post-render script. These tests source it directly into a controlled
# temp directory with controlled QUARTO_PROJECT_* env vars, then assert on
# the resulting R/ contents (and, for .qmd_wants_purl(), call the function
# directly out of the sourced environment).

purl_template <- system.file("templates", "purl.R", package = "toolero", mustWork = TRUE)

# Helper: source purl.R into a fresh environment, inside `dir`, with the
# given QUARTO post-render env vars set for the duration of the source()
# call only. Returns the environment, so .qmd_wants_purl() can be called
# directly for unit-level assertions, and so callers can inspect what the
# script did to `dir` afterward.
source_purl <- function(dir, output_files = "", output_dir = "") {
    env <- new.env()
    withr::local_dir(dir)
    withr::local_envvar(c(
        QUARTO_PROJECT_OUTPUT_FILES = output_files,
        QUARTO_PROJECT_OUTPUT_DIR   = output_dir
    ))
    source(purl_template, local = env)
    env
}

# Helper: write a minimal, knitr::purl()-able .qmd with a purl: <logical>
# key in its header.
make_purlable_qmd <- function(path, purl = TRUE, body = "1 + 1") {
    content <- sprintf(
        "---\ntitle: 'Test'\npurl: %s\n---\n\n```{r}\n%s\n```\n",
        tolower(as.character(purl)), body
    )
    readr::write_file(content, path)
}

# Helper: write a .qmd with a YAML header but no purl key at all.
make_qmd_no_purl_key <- function(path, body = "1 + 1") {
    content <- sprintf("---\ntitle: 'Test'\n---\n\n```{r}\n%s\n```\n", body)
    readr::write_file(content, path)
}

# -- .qmd_wants_purl() ----------------------------------------------------------

test_that(".qmd_wants_purl() returns TRUE when purl: true is present", {
    tmp <- withr::local_tempdir()
    qmd <- fs::path(tmp, "doc.qmd")
    make_purlable_qmd(qmd, purl = TRUE)

    env <- source_purl(tmp)
    expect_true(env$.qmd_wants_purl(qmd))
})

test_that(".qmd_wants_purl() returns FALSE when purl: false is present", {
    tmp <- withr::local_tempdir()
    qmd <- fs::path(tmp, "doc.qmd")
    make_purlable_qmd(qmd, purl = FALSE)

    env <- source_purl(tmp)
    expect_false(env$.qmd_wants_purl(qmd))
})

test_that(".qmd_wants_purl() returns FALSE when the purl key is absent", {
    tmp <- withr::local_tempdir()
    qmd <- fs::path(tmp, "doc.qmd")
    make_qmd_no_purl_key(qmd)

    env <- source_purl(tmp)
    expect_false(env$.qmd_wants_purl(qmd))
})

test_that(".qmd_wants_purl() returns FALSE when there is no YAML header at all", {
    tmp <- withr::local_tempdir()
    qmd <- fs::path(tmp, "doc.qmd")
    readr::write_file("No YAML here, just body text.\n", qmd)

    env <- source_purl(tmp)
    expect_false(env$.qmd_wants_purl(qmd))
})

test_that(".qmd_wants_purl() returns FALSE when purl is a quoted string, not a logical", {
    tmp <- withr::local_tempdir()
    qmd <- fs::path(tmp, "doc.qmd")
    readr::write_file("---\ntitle: 'Test'\npurl: \"true\"\n---\n\nBody.\n", qmd)

    env <- source_purl(tmp)
    expect_false(env$.qmd_wants_purl(qmd))
})

# -- Fallback: QUARTO_PROJECT_OUTPUT_FILES unset ---------------------------------

test_that("falls back to scanning the project root when QUARTO_PROJECT_OUTPUT_FILES is unset", {
    tmp <- withr::local_tempdir()
    make_purlable_qmd(fs::path(tmp, "a.qmd"), purl = TRUE)
    make_purlable_qmd(fs::path(tmp, "b.qmd"), purl = FALSE)

    source_purl(tmp)

    expect_true(fs::file_exists(fs::path(tmp, "R", "a.R")))
    expect_false(fs::file_exists(fs::path(tmp, "R", "b.R")))
})

# -- QUARTO_PROJECT_OUTPUT_FILES: scoping to what was actually rendered ---------

test_that("purls only the document listed in QUARTO_PROJECT_OUTPUT_FILES, not every purl-able .qmd in the project", {
    tmp <- withr::local_tempdir()
    make_purlable_qmd(fs::path(tmp, "a.qmd"), purl = TRUE)
    make_purlable_qmd(fs::path(tmp, "b.qmd"), purl = TRUE)  # wants purl, but not "rendered" this pass

    source_purl(tmp, output_files = "a.html")

    expect_true(fs::file_exists(fs::path(tmp, "R", "a.R")))
    expect_false(fs::file_exists(fs::path(tmp, "R", "b.R")))
})

test_that("purls all documents listed when QUARTO_PROJECT_OUTPUT_FILES has multiple newline-separated entries", {
    tmp <- withr::local_tempdir()
    make_purlable_qmd(fs::path(tmp, "a.qmd"), purl = TRUE)
    make_purlable_qmd(fs::path(tmp, "b.qmd"), purl = TRUE)

    source_purl(tmp, output_files = "a.html\nb.html")

    expect_true(fs::file_exists(fs::path(tmp, "R", "a.R")))
    expect_true(fs::file_exists(fs::path(tmp, "R", "b.R")))
})

test_that("skips a rendered document whose header has purl: false", {
    tmp <- withr::local_tempdir()
    make_purlable_qmd(fs::path(tmp, "a.qmd"), purl = FALSE)

    source_purl(tmp, output_files = "a.html")

    expect_false(fs::file_exists(fs::path(tmp, "R", "a.R")))
})

test_that("does not purl a rendered document with no YAML header at all", {
    tmp <- withr::local_tempdir()
    readr::write_file("Just body text, no header.\n", fs::path(tmp, "a.qmd"))

    expect_no_error(source_purl(tmp, output_files = "a.html"))
    expect_false(fs::file_exists(fs::path(tmp, "R", "a.R")))
})

test_that("purled .R file contains the source chunk's code", {
    tmp <- withr::local_tempdir()
    make_purlable_qmd(fs::path(tmp, "a.qmd"), purl = TRUE, body = "x <- 42")

    source_purl(tmp, output_files = "a.html")

    r_content <- readr::read_file(fs::path(tmp, "R", "a.R"))
    expect_true(grepl("x <- 42", r_content, fixed = TRUE))
})

test_that("re-sourcing purl.R overwrites the previously purled .R file", {
    tmp <- withr::local_tempdir()
    qmd <- fs::path(tmp, "a.qmd")

    make_purlable_qmd(qmd, purl = TRUE, body = "x <- 1")
    source_purl(tmp, output_files = "a.html")

    make_purlable_qmd(qmd, purl = TRUE, body = "x <- 2")
    source_purl(tmp, output_files = "a.html")

    r_content <- readr::read_file(fs::path(tmp, "R", "a.R"))
    expect_true(grepl("x <- 2", r_content, fixed = TRUE))
    expect_false(grepl("x <- 1", r_content, fixed = TRUE))
})

# -- QUARTO_PROJECT_OUTPUT_DIR: website/book output-dir stripping ---------------

test_that("strips the output-dir prefix so a nested website output path maps to its source .qmd", {
    tmp <- withr::local_tempdir()
    fs::dir_create(fs::path(tmp, "posts", "hello"))
    make_purlable_qmd(fs::path(tmp, "posts", "hello", "index.qmd"), purl = TRUE)

    source_purl(
        tmp,
        output_files = "_site/posts/hello/index.html",
        output_dir   = "_site"
    )

    expect_true(fs::file_exists(fs::path(tmp, "R", "posts", "hello", "index.R")))
})

test_that("website render with output-dir only purls the pages listed as rendered, not the whole site", {
    tmp <- withr::local_tempdir()
    fs::dir_create(fs::path(tmp, "posts", "one"))
    fs::dir_create(fs::path(tmp, "posts", "two"))
    make_purlable_qmd(fs::path(tmp, "posts", "one", "index.qmd"), purl = TRUE)
    make_purlable_qmd(fs::path(tmp, "posts", "two", "index.qmd"), purl = TRUE)

    # Only posts/one was rendered this pass (e.g. an incremental preview)
    source_purl(
        tmp,
        output_files = "_site/posts/one/index.html",
        output_dir   = "_site"
    )

    expect_true(fs::file_exists(fs::path(tmp, "R", "posts", "one", "index.R")))
    expect_false(fs::file_exists(fs::path(tmp, "R", "posts", "two", "index.R")))
})

# -- Path mirroring: same-basename collision across directories -----------------
# The bug this whole change exists to fix: a directory-per-post convention
# (posts/<slug>/index.qmd) means many documents legitimately share the
# filename "index.qmd". Flattening output to R/<basename>.R would have
# every one of them silently overwrite the last one purled.

test_that("two documents with the same basename in different directories purl to distinct, correctly nested outputs", {
    tmp <- withr::local_tempdir()
    fs::dir_create(fs::path(tmp, "posts", "2026-08-04-giscus"))
    fs::dir_create(fs::path(tmp, "posts", "2026-09-01-toolero"))
    make_purlable_qmd(
        fs::path(tmp, "posts", "2026-08-04-giscus", "index.qmd"),
        purl = TRUE, body = "giscus_flag <- TRUE"
    )
    make_purlable_qmd(
        fs::path(tmp, "posts", "2026-09-01-toolero", "index.qmd"),
        purl = TRUE, body = "toolero_flag <- TRUE"
    )

    # Both rendered in the same full-project build
    source_purl(
        tmp,
        output_files = paste(
            "_site/posts/2026-08-04-giscus/index.html",
            "_site/posts/2026-09-01-toolero/index.html",
            sep = "\n"
        ),
        output_dir = "_site"
    )

    giscus_out  <- fs::path(tmp, "R", "posts", "2026-08-04-giscus", "index.R")
    toolero_out <- fs::path(tmp, "R", "posts", "2026-09-01-toolero", "index.R")

    expect_true(fs::file_exists(giscus_out))
    expect_true(fs::file_exists(toolero_out))

    # Each output holds its own document's code, not the other's --
    # confirming the collision is actually resolved, not just that two
    # files happen to exist.
    expect_true(grepl("giscus_flag", readr::read_file(giscus_out), fixed = TRUE))
    expect_false(grepl("toolero_flag", readr::read_file(giscus_out), fixed = TRUE))
    expect_true(grepl("toolero_flag", readr::read_file(toolero_out), fixed = TRUE))
    expect_false(grepl("giscus_flag", readr::read_file(toolero_out), fixed = TRUE))
})

test_that("path mirroring also applies to the fallback (no QUARTO_PROJECT_OUTPUT_FILES) branch", {
    tmp <- withr::local_tempdir()
    fs::dir_create(fs::path(tmp, "posts", "one"))
    make_purlable_qmd(fs::path(tmp, "posts", "one", "index.qmd"), purl = TRUE)

    source_purl(tmp)

    expect_true(fs::file_exists(fs::path(tmp, "R", "posts", "one", "index.R")))
})

# -- Missing source .qmd: informative, non-fatal ---------------------------------

test_that("reports, without erroring, when a rendered output has no matching source .qmd", {
    tmp <- withr::local_tempdir()

    expect_message(
        source_purl(tmp, output_files = "ghost.html"),
        "Could not find a source"
    )
})

test_that("does not create R/ when the only candidate has no matching source .qmd", {
    tmp <- withr::local_tempdir()

    suppressMessages(source_purl(tmp, output_files = "ghost.html"))
    expect_false(fs::dir_exists(fs::path(tmp, "R")))
})

test_that("still purls the valid candidates when one rendered output has no matching source .qmd", {
    tmp <- withr::local_tempdir()
    make_purlable_qmd(fs::path(tmp, "a.qmd"), purl = TRUE)

    suppressMessages(
        source_purl(tmp, output_files = "a.html\nghost.html")
    )

    expect_true(fs::file_exists(fs::path(tmp, "R", "a.R")))
})

# -- No purl-able candidates at all ----------------------------------------------

test_that("does not create R/ when no rendered candidate has purl: true", {
    tmp <- withr::local_tempdir()
    make_purlable_qmd(fs::path(tmp, "a.qmd"), purl = FALSE)

    expect_no_error(source_purl(tmp, output_files = "a.html"))
    expect_false(fs::dir_exists(fs::path(tmp, "R")))
})

test_that("does not create R/ on an empty project with no .qmd files at all", {
    tmp <- withr::local_tempdir()

    expect_no_error(source_purl(tmp))
    expect_false(fs::dir_exists(fs::path(tmp, "R")))
})
