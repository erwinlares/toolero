# tests/testthat/test-utils-yaml.R
#
# The line-oriented YAML header helpers behind create_qmd(). The point of
# these helpers is that they leave alone everything they were not asked to
# change, so most of what follows checks what did *not* happen.

# Helper: a header in the shape both shipped templates use, with the
# constructs a round trip would flatten -- quoted scalars, a block
# scalar, an indented sequence, and a comment.
rich_header <- function() {
    paste(
        "---",
        'title: "Your Document Title"',
        "author:",
        '  - name: "Your Name"',
        '    affiliation: "Your Institution"',
        "date: today",
        "abstract: |",
        "  A longer summary that runs",
        "  across two lines.",
        "categories:",
        '  - "add"',
        '  - "your"',
        "format:",
        "  html:",
        "    toc: true",
        "    # a comment a YAML round trip would delete",
        "    number-sections: true",
        "---",
        "",
        "## Introduction",
        "",
        sep = "\n"
    )
}


# -- .split_yaml_header() ------------------------------------------------------

test_that("split_yaml_header() returns NULL when there is no header", {
    expect_null(.split_yaml_header("Just body text.\n"))
})

test_that("split_yaml_header() returns NULL when the header is never closed", {
    expect_null(.split_yaml_header("---\ntitle: Test\n\nBody.\n"))
})

test_that("split_yaml_header() excludes both fences from the header", {
    parts <- .split_yaml_header("---\ntitle: Test\n---\n\nBody.\n")

    expect_equal(parts$header, "title: Test")
    expect_false(any(grepl("---", parts$header, fixed = TRUE)))
})

test_that("split_yaml_header() keeps the body verbatim", {
    parts <- .split_yaml_header("---\ntitle: Test\n---\n\nBody.\n")
    expect_equal(parts$body, c("", "Body."))
})

test_that("split_yaml_header() records a trailing newline", {
    expect_true(.split_yaml_header("---\na: 1\n---\nBody.\n")$trailing_newline)
    expect_false(.split_yaml_header("---\na: 1\n---\nBody.")$trailing_newline)
})

test_that("split_yaml_header() normalizes CRLF line endings", {
    parts <- .split_yaml_header("---\r\ntitle: Test\r\n---\r\n\r\nBody.\r\n")
    expect_equal(parts$header, "title: Test")
    expect_false(any(grepl("\r", parts$body, fixed = TRUE)))
})

test_that("split_yaml_header() handles an empty header", {
    parts <- .split_yaml_header("---\n---\n\nBody.\n")
    expect_equal(parts$header, character(0))
})


# -- .join_yaml_header() -------------------------------------------------------

test_that("join_yaml_header() round-trips an untouched document byte for byte", {
    content <- rich_header()
    parts <- .split_yaml_header(content)

    expect_equal(.join_yaml_header(parts$header, parts), content)
})

test_that("join_yaml_header() round-trips a document with no trailing newline", {
    content <- "---\ntitle: Test\n---\n\nBody."
    parts <- .split_yaml_header(content)

    expect_equal(.join_yaml_header(parts$header, parts), content)
})


# -- .yaml_line_key() ----------------------------------------------------------

test_that("yaml_line_key() reads a plain key", {
    expect_equal(.yaml_line_key("title: Something"), "title")
    expect_equal(.yaml_line_key("format:"), "format")
    expect_equal(.yaml_line_key("include-before-body: a.html"), "include-before-body")
})

test_that("yaml_line_key() takes the first colon, so URLs are values not keys", {
    expect_equal(.yaml_line_key("url: https://example.org"), "url")
})

test_that("yaml_line_key() reads a quoted key", {
    expect_equal(.yaml_line_key('"my key": 1'), "my key")
    expect_equal(.yaml_line_key("'my key': 1"), "my key")
})

test_that("yaml_line_key() rejects comments, sequence items, and plain text", {
    expect_true(is.na(.yaml_line_key("# format: html")))
    expect_true(is.na(.yaml_line_key("- name: Your Name")))
    expect_true(is.na(.yaml_line_key("A line of prose.")))
    expect_true(is.na(.yaml_line_key("")))
})

test_that("yaml_line_key() rejects a colon with no space after it", {
    expect_true(is.na(.yaml_line_key("12:30 is the time")))
})


# -- .set_yaml_key(): adding, replacing, and leaving alone ---------------------

test_that("set_yaml_key() appends a top-level key that is not present", {
    lines <- c("title: Test")
    expect_equal(
        .set_yaml_key(lines, "purl", TRUE),
        c("title: Test", "purl: true")
    )
})

test_that("set_yaml_key() replaces a top-level key that is present", {
    lines <- c("title: Test", "purl: false", "date: today")
    expect_equal(
        .set_yaml_key(lines, "purl", TRUE),
        c("title: Test", "purl: true", "date: today")
    )
})

test_that("set_yaml_key() writes logicals as true/false, not yes/no", {
    expect_equal(.set_yaml_key(character(0), "purl", FALSE), "purl: false")
    expect_false(any(grepl("yes|no", .set_yaml_key(character(0), "purl", TRUE))))
})

test_that("set_yaml_key() writes into an empty header", {
    expect_equal(.set_yaml_key(character(0), "purl", TRUE), "purl: true")
})

test_that("set_yaml_key() adds a leaf inside an existing nested block", {
    lines <- c("format:", "  html:", "    toc: true")

    expect_equal(
        .set_yaml_key(lines, c("format", "html", "css"), "assets/styles.css"),
        c("format:", "  html:", "    toc: true", "    css: assets/styles.css")
    )
})

test_that("set_yaml_key() replaces a leaf inside an existing nested block", {
    lines <- c("format:", "  html:", "    css: old.css", "    toc: true")

    expect_equal(
        .set_yaml_key(lines, c("format", "html", "css"), "new.css"),
        c("format:", "  html:", "    css: new.css", "    toc: true")
    )
})

test_that("set_yaml_key() builds the whole chain when the parent is missing", {
    expect_equal(
        .set_yaml_key("title: Test", c("format", "html", "css"), "a.css"),
        c("title: Test", "format:", "  html:", "    css: a.css")
    )
})

test_that("set_yaml_key() builds only the missing part of a partial chain", {
    lines <- c("format:", "  pdf:", "    toc: true")

    expect_equal(
        .set_yaml_key(lines, c("format", "html", "css"), "a.css"),
        c("format:", "  pdf:", "    toc: true", "  html:", "    css: a.css")
    )
})

test_that("set_yaml_key() leaves an existing key alone when overwrite = FALSE", {
    lines <- c("params:", "  input_file: data-raw/sample.csv")

    expect_equal(
        .set_yaml_key(lines, c("params", "input_file"), "other.csv",
                      overwrite = FALSE),
        lines
    )
})

test_that("set_yaml_key() still creates a missing key when overwrite = FALSE", {
    expect_equal(
        .set_yaml_key("title: Test", c("params", "input_file"), "d.csv",
                      overwrite = FALSE),
        c("title: Test", "params:", "  input_file: d.csv")
    )
})

test_that("set_yaml_key() merges into a params block that has other entries", {
    lines <- c("params:", "  seed: 42")

    expect_equal(
        .set_yaml_key(lines, c("params", "input_file"), "d.csv",
                      overwrite = FALSE),
        c("params:", "  seed: 42", "  input_file: d.csv")
    )
})

test_that("set_yaml_key() replaces a multi-line entry in full", {
    lines <- c(
        "author:",
        "  - name: Old Name",
        "    email: old@example.org",
        "date: today"
    )

    result <- .set_yaml_key(
        lines, "author", list(list(name = "New Name"))
    )

    expect_false(any(grepl("Old Name", result, fixed = TRUE)))
    expect_false(any(grepl("old@example.org", result, fixed = TRUE)))
    expect_true(any(grepl("New Name", result, fixed = TRUE)))
    expect_equal(result[[length(result)]], "date: today")
})

test_that("set_yaml_key() aborts rather than clobbering a scalar parent", {
    expect_error(
        .set_yaml_key("format: html", c("format", "html", "css"), "a.css"),
        "scalar value"
    )
})

test_that("set_yaml_key() ignores comment lines when looking for a key", {
    lines <- c("format:", "  html:", "    # css: commented-out.css",
               "    toc: true")

    result <- .set_yaml_key(lines, c("format", "html", "css"), "real.css")

    expect_true("    # css: commented-out.css" %in% result)
    expect_true("    css: real.css" %in% result)
})

test_that("set_yaml_key() does not mistake a sequence item for a mapping key", {
    lines <- c("author:", "  - name: Your Name", "name: not-the-author")

    result <- .set_yaml_key(lines, "name", "replaced")

    expect_true("  - name: Your Name" %in% result)
    expect_true("name: replaced" %in% result)
    expect_false(any(grepl("not-the-author", result, fixed = TRUE)))
})


# -- .set_yaml_keys(): the header-level entry point ----------------------------

test_that("set_yaml_keys() leaves every untouched header line verbatim", {
    content <- rich_header()
    before <- .split_yaml_header(content)$header

    result <- .set_yaml_keys(
        content,
        list(list(path = "purl", value = TRUE)),
        what = "the purl flag"
    )
    after <- .split_yaml_header(result)$header

    expect_equal(after[seq_along(before)], before)
    expect_equal(after[[length(after)]], "purl: true")
})

test_that("set_yaml_keys() preserves quoting, block scalars, and comments", {
    result <- .set_yaml_keys(
        rich_header(),
        list(list(path = "purl", value = TRUE)),
        what = "the purl flag"
    )

    expect_true(grepl('title: "Your Document Title"', result, fixed = TRUE))
    expect_true(grepl("abstract: |", result, fixed = TRUE))
    expect_true(grepl("  A longer summary that runs", result, fixed = TRUE))
    expect_true(grepl('  - "add"', result, fixed = TRUE))
    expect_true(
        grepl("# a comment a YAML round trip would delete", result, fixed = TRUE)
    )
})

test_that("set_yaml_keys() leaves the body untouched", {
    content <- rich_header()

    result <- .set_yaml_keys(
        content,
        list(list(path = "purl", value = TRUE)),
        what = "the purl flag"
    )

    expect_equal(
        .split_yaml_header(result)$body,
        .split_yaml_header(content)$body
    )
})

test_that("set_yaml_keys() applies several keys in order", {
    result <- .set_yaml_keys(
        "---\nformat:\n  html:\n    toc: true\n---\n\nBody.\n",
        list(
            list(path = c("format", "html", "css"), value = "a.css"),
            list(path = c("format", "html", "include-after-body"), value = "f.html")
        )
    )

    expect_true(grepl("css: a.css", result, fixed = TRUE))
    expect_true(grepl("include-after-body: f.html", result, fixed = TRUE))
})

test_that("set_yaml_keys() warns and returns content unchanged with no header", {
    content <- "No YAML here."

    expect_warning(
        result <- .set_yaml_keys(
            content,
            list(list(path = "purl", value = TRUE)),
            what = "the purl flag"
        ),
        "No YAML header found"
    )
    expect_equal(result, content)
})

test_that("set_yaml_keys() names the operation in the missing-header warning", {
    expect_warning(
        .set_yaml_keys("No YAML here.",
                       list(list(path = "purl", value = TRUE)),
                       what = "style injection"),
        "style injection"
    )
})

test_that("set_yaml_keys() is a silent no-op when there is nothing to set", {
    expect_no_warning(
        result <- .set_yaml_keys("No YAML here.", list())
    )
    expect_equal(result, "No YAML here.")
})

test_that("set_yaml_keys() preserves a document with no trailing newline", {
    result <- .set_yaml_keys(
        "---\ntitle: Test\n---\n\nBody.",
        list(list(path = "purl", value = TRUE))
    )

    expect_false(grepl("\n$", result))
})

test_that("set_yaml_keys() output still parses as YAML", {
    result <- .set_yaml_keys(
        rich_header(),
        list(
            list(path = "purl", value = TRUE),
            list(path = c("params", "input_file"), value = "data-raw/data.csv"),
            list(path = c("format", "html", "css"), value = "assets/styles.css")
        )
    )

    parsed <- yaml::yaml.load(
        paste(.split_yaml_header(result)$header, collapse = "\n")
    )

    expect_true(parsed[["purl"]])
    expect_equal(parsed[["params"]][["input_file"]], "data-raw/data.csv")
    expect_equal(parsed[["format"]][["html"]][["css"]], "assets/styles.css")
    expect_equal(parsed[["title"]], "Your Document Title")
    expect_equal(parsed[["format"]][["html"]][["toc"]], TRUE)
})
