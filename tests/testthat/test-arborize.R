# tests/testthat/test-arborize.R

# .build_arborize_qmd() -- simple notation --------------------------------

test_that(".build_arborize_qmd() returns a character string", {
    result <- .build_arborize_qmd(
        "[NP [Det the] [N cat]]",
        tree_notation = "simple",
        typst_package = "@preview/syntree:0.2.1"
    )
    expect_type(result, "character")
    expect_length(result, 1L)
})

test_that(".build_arborize_qmd() simple: contains the tree string", {
    result <- .build_arborize_qmd(
        "[NP [Det the] [N cat]]",
        tree_notation = "simple",
        typst_package = "@preview/syntree:0.2.1"
    )
    expect_true(grepl("NP", result))
    expect_true(grepl("Det the", result))
})

test_that(".build_arborize_qmd() simple: imports syntree package", {
    result <- .build_arborize_qmd(
        "[S [NP] [VP]]",
        tree_notation = "simple",
        typst_package = "@preview/syntree:0.2.1"
    )
    expect_true(grepl("@preview/syntree:0.2.1", result, fixed = TRUE))
    expect_true(grepl("#import", result, fixed = TRUE))
})

test_that(".build_arborize_qmd() simple: calls the syntree Typst function", {
    result <- .build_arborize_qmd(
        "[S [NP] [VP]]",
        tree_notation = "simple",
        typst_package = "@preview/syntree:0.2.1"
    )
    expect_true(grepl("#syntree(", result, fixed = TRUE))
})

test_that(".build_arborize_qmd() simple: does not contain render call", {
    result <- .build_arborize_qmd(
        "[S [NP] [VP]]",
        tree_notation = "simple",
        typst_package = "@preview/syntree:0.2.1"
    )
    expect_false(grepl("#render(", result, fixed = TRUE))
})

test_that(".build_arborize_qmd() simple: escapes double quotes in tree string", {
    result <- .build_arborize_qmd(
        '[NP [N "cat"]]',
        tree_notation = "simple",
        typst_package = "@preview/syntree:0.2.1"
    )
    expect_true(grepl('\\\\"cat\\\\"', result, fixed = TRUE))
})

test_that(".build_arborize_qmd() simple: does not escape single quotes", {
    result <- .build_arborize_qmd(
        "[NP [N cat's]]",
        tree_notation = "simple",
        typst_package = "@preview/syntree:0.2.1"
    )
    expect_true(grepl("cat's", result, fixed = TRUE))
})

# .build_arborize_qmd() -- structured notation ----------------------------

test_that(".build_arborize_qmd() structured: imports lingotree package", {
    result <- .build_arborize_qmd(
        "tree(tag: [VP], [smiled])",
        tree_notation = "structured",
        typst_package = "@preview/lingotree:1.0.0"
    )
    expect_true(grepl("@preview/lingotree:1.0.0", result, fixed = TRUE))
    expect_true(grepl("#import", result, fixed = TRUE))
})

test_that(".build_arborize_qmd() structured: uses wildcard import", {
    result <- .build_arborize_qmd(
        "tree(tag: [VP], [smiled])",
        tree_notation = "structured",
        typst_package = "@preview/lingotree:1.0.0"
    )
    expect_true(grepl(": *", result, fixed = TRUE))
})

test_that(".build_arborize_qmd() structured: wraps tree in render call", {
    result <- .build_arborize_qmd(
        "tree(tag: [VP], [smiled])",
        tree_notation = "structured",
        typst_package = "@preview/lingotree:1.0.0"
    )
    expect_true(grepl("#render(", result, fixed = TRUE))
})

test_that(".build_arborize_qmd() structured: passes tree string verbatim", {
    tree_str <- "tree(tag: [VP], [smiled])"
    result <- .build_arborize_qmd(
        tree_str,
        tree_notation = "structured",
        typst_package = "@preview/lingotree:1.0.0"
    )
    expect_true(grepl(tree_str, result, fixed = TRUE))
})

test_that(".build_arborize_qmd() structured: does not escape double quotes", {
    result <- .build_arborize_qmd(
        'tree(tag: [VP], ["smiled"])',
        tree_notation = "structured",
        typst_package = "@preview/lingotree:1.0.0"
    )
    expect_true(grepl('"smiled"', result, fixed = TRUE))
    expect_false(grepl('\\"smiled\\"', result, fixed = TRUE))
})

test_that(".build_arborize_qmd() structured: does not use syntree call", {
    result <- .build_arborize_qmd(
        "tree(tag: [VP], [smiled])",
        tree_notation = "structured",
        typst_package = "@preview/lingotree:1.0.0"
    )
    expect_false(grepl("#syntree(", result, fixed = TRUE))
})

# .build_arborize_qmd() -- shared -----------------------------------------

test_that(".build_arborize_qmd() contains a Typst code fence", {
    result <- .build_arborize_qmd(
        "[S [NP] [VP]]",
        tree_notation = "simple",
        typst_package = "@preview/syntree:0.2.1"
    )
    expect_true(grepl("```{=typst}", result, fixed = TRUE))
})

test_that(".build_arborize_qmd() reflects custom papersize", {
    result <- .build_arborize_qmd(
        "[S [NP] [VP]]",
        tree_notation = "simple",
        typst_package = "@preview/syntree:0.2.1",
        papersize     = "a4"
    )
    expect_true(grepl("papersize: a4", result))
})

test_that(".build_arborize_qmd() reflects custom margin in both axes", {
    result <- .build_arborize_qmd(
        "[S [NP] [VP]]",
        tree_notation = "simple",
        typst_package = "@preview/syntree:0.2.1",
        margin        = "1cm"
    )
    expect_true(grepl("x: 1cm", result))
    expect_true(grepl("y: 1cm", result))
})

test_that(".build_arborize_qmd() uses default papersize a5", {
    result <- .build_arborize_qmd(
        "[S [NP] [VP]]",
        tree_notation = "simple",
        typst_package = "@preview/syntree:0.2.1"
    )
    expect_true(grepl("papersize: a5", result))
})

test_that(".build_arborize_qmd() uses default margin 0.5cm", {
    result <- .build_arborize_qmd(
        "[S [NP] [VP]]",
        tree_notation = "simple",
        typst_package = "@preview/syntree:0.2.1"
    )
    expect_true(grepl("x: 0.5cm", result))
    expect_true(grepl("y: 0.5cm", result))
})

# .write_arborize_provenance() --------------------------------------------

test_that(".write_arborize_provenance() creates a yaml file", {
    tmp_png <- withr::local_tempfile(fileext = ".png")
    fs::file_create(tmp_png)

    .write_arborize_provenance(
        output        = tmp_png,
        tree          = "[NP [Det the] [N cat]]",
        tree_notation = "simple",
        typst_package = "@preview/syntree:0.2.1",
        dpi           = 300,
        papersize     = "a5",
        margin        = "0.5cm"
    )

    yaml_path <- fs::path_ext_set(tmp_png, "yaml")
    expect_true(fs::file_exists(yaml_path))
})

test_that(".write_arborize_provenance() yaml contains expected fields", {
    tmp_png <- withr::local_tempfile(fileext = ".png")
    fs::file_create(tmp_png)

    .write_arborize_provenance(
        output        = tmp_png,
        tree          = "[NP [Det the] [N cat]]",
        tree_notation = "simple",
        typst_package = "@preview/syntree:0.2.1",
        dpi           = 300,
        papersize     = "a5",
        margin        = "0.5cm"
    )

    yaml_path <- fs::path_ext_set(tmp_png, "yaml")
    contents  <- yaml::read_yaml(yaml_path)

    expect_equal(contents$tree,          "[NP [Det the] [N cat]]")
    expect_equal(contents$tree_notation, "simple")
    expect_equal(contents$typst_package, "@preview/syntree:0.2.1")
    expect_equal(contents$dpi,           300)
    expect_equal(contents$papersize,     "a5")
    expect_equal(contents$margin,        "0.5cm")
    expect_true("rendered_by"  %in% names(contents))
    expect_true("rendered_at"  %in% names(contents))
    expect_true("output"       %in% names(contents))
})

test_that(".write_arborize_provenance() yaml file name matches png", {
    tmp_png <- withr::local_tempfile(fileext = ".png")
    fs::file_create(tmp_png)

    result <- .write_arborize_provenance(
        output        = tmp_png,
        tree          = "[NP]",
        tree_notation = "simple",
        typst_package = "@preview/syntree:0.2.1",
        dpi           = 300,
        papersize     = "a5",
        margin        = "0.5cm"
    )

    expect_equal(
        fs::path_ext(result),
        "yaml"
    )
    expect_equal(
        fs::path_ext_remove(as.character(result)),
        fs::path_ext_remove(as.character(tmp_png))
    )
})

test_that(".write_arborize_provenance() returns path invisibly", {
    tmp_png <- withr::local_tempfile(fileext = ".png")
    fs::file_create(tmp_png)

    result <- .write_arborize_provenance(
        output        = tmp_png,
        tree          = "[NP]",
        tree_notation = "simple",
        typst_package = "@preview/syntree:0.2.1",
        dpi           = 300,
        papersize     = "a5",
        margin        = "0.5cm"
    )

    expect_equal(
        as.character(result),
        as.character(fs::path_ext_set(tmp_png, "yaml"))
    )
})

# arborize() input validation ---------------------------------------------

test_that("arborize() errors on non-character tree", {
    expect_error(arborize(123), "must be a non-empty character string")
})

test_that("arborize() errors on empty string", {
    expect_error(arborize(""), "must be a non-empty character string")
})

test_that("arborize() errors on length > 1 vector", {
    expect_error(
        arborize(c("[NP]", "[VP]")),
        "must be a non-empty character string"
    )
})

test_that("arborize() errors on NA", {
    expect_error(
        arborize(NA_character_),
        "must be a non-empty character string"
    )
})

test_that("arborize() errors when output exists and overwrite is FALSE", {
    tmp <- withr::local_tempfile(fileext = ".png")
    fs::file_create(tmp)
    expect_error(
        arborize("[NP [Det the] [N cat]]", output = tmp),
        "already exists"
    )
})

test_that("arborize() errors on invalid tree_notation", {
    expect_error(
        arborize("[NP]", tree_notation = "fancy"),
        "should be one of"
    )
})

test_that("arborize() errors when pdftools is not available", {
    skip_if(
        requireNamespace("pdftools", quietly = TRUE),
        "pdftools is installed -- skipping unavailability test"
    )
    expect_error(arborize("[NP [Det the] [N cat]]"), "pdftools")
})

# arborize() provenance argument ------------------------------------------

test_that("arborize() provenance = FALSE suppresses yaml file", {
    skip_on_ci()
    skip_on_cran()
    skip_if_not(
        isTRUE(tryCatch(quarto::quarto_version() >= "1.4",
                        error = function(e) FALSE)),
        "Quarto 1.4+ not available"
    )
    skip_if_not(
        requireNamespace("pdftools", quietly = TRUE),
        "pdftools not available"
    )

    tmp <- withr::local_tempfile(fileext = ".png")

    arborize(
        "[NP [Det the] [N cat]]",
        output     = tmp,
        provenance = FALSE,
        overwrite  = TRUE
    )

    yaml_path <- fs::path_ext_set(tmp, "yaml")
    expect_false(fs::file_exists(yaml_path))
})

test_that("arborize() provenance = TRUE writes yaml file", {
    skip_on_ci()
    skip_on_cran()
    skip_if_not(
        isTRUE(tryCatch(quarto::quarto_version() >= "1.4",
                        error = function(e) FALSE)),
        "Quarto 1.4+ not available"
    )
    skip_if_not(
        requireNamespace("pdftools", quietly = TRUE),
        "pdftools not available"
    )

    tmp <- withr::local_tempfile(fileext = ".png")

    arborize(
        "[NP [Det the] [N cat]]",
        output     = tmp,
        provenance = TRUE,
        overwrite  = TRUE
    )

    yaml_path <- fs::path_ext_set(tmp, "yaml")
    expect_true(fs::file_exists(yaml_path))

    contents <- yaml::read_yaml(yaml_path)
    expect_equal(contents$tree, "[NP [Det the] [N cat]]")
    expect_equal(contents$tree_notation, "simple")
})

# arborize() full pipeline ------------------------------------------------
# These tests render a real PDF and PNG via Quarto + Typst. They require:
#   - Quarto 1.4+ with Typst support
#   - pdftools installed
#   - Internet access for Typst to download packages on first use
#
# skip_on_ci() and skip_on_cran() prevent these from running on GitHub
# Actions or CRAN check machines where the Typst package cache may be
# absent and network conditions unpredictable.

test_that("arborize() simple: produces a non-empty PNG file", {
  skip_on_ci()
  skip_on_cran()
  skip_if_not(
    isTRUE(tryCatch(quarto::quarto_version() >= "1.4",
                    error = function(e) FALSE)),
    "Quarto 1.4+ not available"
  )
  skip_if_not(
    isTRUE(tryCatch({
      test_qmd <- withr::local_tempfile(fileext = ".qmd")
      writeLines(c("---", "title: test", "---", "hello"), test_qmd)
      quarto::quarto_render(test_qmd, output_format = "html", quiet = TRUE)
      TRUE
    }, error = function(e) FALSE)),
    "Quarto CLI cannot render -- possible version mismatch"
  )
  skip_if_not(
    requireNamespace("pdftools", quietly = TRUE),
    "pdftools not available"
  )
  tmp <- withr::local_tempfile(fileext = ".png")
  result <- arborize(
    "[NP [Det the] [N cat]]",
    output        = tmp,
    tree_notation = "simple",
    provenance    = FALSE,
    overwrite     = TRUE
  )
  expect_true(fs::file_exists(result))
  expect_gt(fs::file_size(result), 0)
})

test_that("arborize() simple: returns the output path invisibly", {
    skip_on_ci()
    skip_on_cran()
    skip_if_not(
        isTRUE(tryCatch(quarto::quarto_version() >= "1.4",
                        error = function(e) FALSE)),
        "Quarto 1.4+ not available"
    )
    skip_if_not(
        requireNamespace("pdftools", quietly = TRUE),
        "pdftools not available"
    )

    tmp <- withr::local_tempfile(fileext = ".png")

    result <- arborize(
        "[NP [Det the] [N cat]]",
        output        = tmp,
        tree_notation = "simple",
        provenance    = FALSE,
        overwrite     = TRUE
    )

    expect_equal(
        normalizePath(as.character(result), mustWork = FALSE),
        normalizePath(as.character(tmp),    mustWork = FALSE)
    )
})

test_that("arborize() simple: does not error when overwrite is TRUE", {
    skip_on_ci()
    skip_on_cran()
    skip_if_not(
        isTRUE(tryCatch(quarto::quarto_version() >= "1.4",
                        error = function(e) FALSE)),
        "Quarto 1.4+ not available"
    )
    skip_if_not(
        requireNamespace("pdftools", quietly = TRUE),
        "pdftools not available"
    )

    tmp <- withr::local_tempfile(fileext = ".png")
    fs::file_create(tmp)

    expect_no_error(
        arborize(
            "[NP [Det the] [N cat]]",
            output        = tmp,
            tree_notation = "simple",
            provenance    = FALSE,
            overwrite     = TRUE
        )
    )
})

test_that("arborize() structured: produces a non-empty PNG file", {
    skip_on_ci()
    skip_on_cran()
    skip_if_not(
        isTRUE(tryCatch(quarto::quarto_version() >= "1.4",
                        error = function(e) FALSE)),
        "Quarto 1.4+ not available"
    )
    skip_if_not(
        requireNamespace("pdftools", quietly = TRUE),
        "pdftools not available"
    )

    tmp <- withr::local_tempfile(fileext = ".png")

    result <- arborize(
        "tree(
      tag: [VP],
      tree(
        tag: [DP],
        [every],
        [farmer]
      ),
      [smiled]
    )",
        output        = tmp,
        tree_notation = "structured",
        provenance    = FALSE,
        overwrite     = TRUE
    )

    expect_true(fs::file_exists(result))
    expect_gt(fs::file_size(result), 0)
})
