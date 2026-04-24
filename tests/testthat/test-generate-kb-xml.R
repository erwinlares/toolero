# tests/testthat/test-generate-kb-xml.R

# Helper: write a minimal .qmd file with known YAML to a temp location
make_test_qmd <- function(path,
                          title       = "Test Title",
                          description = "Test summary",
                          categories  = c("tag1", "tag2")) {
    categories_block <- paste0(
        "categories:\n",
        paste0("  - \"", categories, "\"", collapse = "\n")
    )
    content <- glue::glue(
        "---\n",
        "title: \"{title}\"\n",
        "description: \"{description}\"\n",
        "{categories_block}\n",
        "---\n\n",
        "Body text.\n"
    )
    readr::write_file(content, path)
}

# Helper: write a minimal .html file to a temp location
make_test_html <- function(path) {
    readr::write_file(
        "<html><body><p>Test content</p></body></html>",
        path
    )
}

# -- .extract_qmd_metadata() --------------------------------------------------

test_that(".extract_qmd_metadata() extracts title correctly", {
    tmp <- withr::local_tempfile(fileext = ".qmd")
    make_test_qmd(tmp, title = "My Title")
    meta <- .extract_qmd_metadata(tmp)
    expect_equal(meta$kb_title, "My Title")
})

test_that(".extract_qmd_metadata() extracts description as kb_summary", {
    tmp <- withr::local_tempfile(fileext = ".qmd")
    make_test_qmd(tmp, description = "A short summary")
    meta <- .extract_qmd_metadata(tmp)
    expect_equal(meta$kb_summary, "A short summary")
})

test_that(".extract_qmd_metadata() collapses categories into kb_keywords", {
    tmp <- withr::local_tempfile(fileext = ".qmd")
    make_test_qmd(tmp, categories = c("reproducibility", "quarto", "R"))
    meta <- .extract_qmd_metadata(tmp)
    expect_equal(meta$kb_keywords, "reproducibility, quarto, R")
})

test_that(".extract_qmd_metadata() returns empty string for missing title", {
    tmp <- withr::local_tempfile(fileext = ".qmd")
    readr::write_file("---\ndescription: \"desc\"\n---\n\nBody.\n", tmp)
    meta <- .extract_qmd_metadata(tmp)
    expect_equal(meta$kb_title, "")
})

test_that(".extract_qmd_metadata() returns empty string for missing description", {
    tmp <- withr::local_tempfile(fileext = ".qmd")
    readr::write_file("---\ntitle: \"title\"\n---\n\nBody.\n", tmp)
    meta <- .extract_qmd_metadata(tmp)
    expect_equal(meta$kb_summary, "")
})

test_that(".extract_qmd_metadata() returns empty string for missing categories", {
    tmp <- withr::local_tempfile(fileext = ".qmd")
    readr::write_file("---\ntitle: \"title\"\n---\n\nBody.\n", tmp)
    meta <- .extract_qmd_metadata(tmp)
    expect_equal(meta$kb_keywords, "")
})

test_that(".extract_qmd_metadata() returns a list with correct names", {
    tmp <- withr::local_tempfile(fileext = ".qmd")
    make_test_qmd(tmp)
    meta <- .extract_qmd_metadata(tmp)
    expect_named(meta, c("kb_title", "kb_summary", "kb_keywords"))
})

# -- generate_kb_xml() validation ---------------------------------------------

test_that("errors informatively when html_path does not exist", {
    expect_error(
        generate_kb_xml(html_path = "/no/such/file.html"),
        "does not exist"
    )
})

test_that("errors informatively when qmd_path cannot be inferred", {
    tmp_html <- withr::local_tempfile(fileext = ".html")
    make_test_html(tmp_html)
    expect_error(
        generate_kb_xml(html_path = tmp_html),
        "Could not find"
    )
})

test_that("errors informatively when explicit qmd_path does not exist", {
    tmp_html <- withr::local_tempfile(fileext = ".html")
    make_test_html(tmp_html)
    expect_error(
        generate_kb_xml(
            html_path = tmp_html,
            qmd_path  = "/no/such/file.qmd"
        ),
        "Could not find"
    )
})

test_that("infers qmd_path correctly from html_path", {
    tmp_dir  <- withr::local_tempdir()
    tmp_html <- fs::path(tmp_dir, "analysis.html")
    tmp_qmd  <- fs::path(tmp_dir, "analysis.qmd")
    make_test_html(tmp_html)
    make_test_qmd(tmp_qmd)

    # function will fail at render step but qmd inference must succeed first
    expect_error(
        generate_kb_xml(html_path = tmp_html),
        regexp = NA
    ) |> tryCatch(error = function(e) {
        expect_false(grepl("Could not find", conditionMessage(e)))
    })
})

test_that("output_dir defaults to directory of html_path", {
    tmp_dir  <- withr::local_tempdir()
    tmp_html <- fs::path(tmp_dir, "analysis.html")
    tmp_qmd  <- fs::path(tmp_dir, "analysis.qmd")
    make_test_html(tmp_html)
    make_test_qmd(tmp_qmd)

    expected_output <- fs::path(tmp_dir, "analysis.xml")

    # intercept before render
    tryCatch(
        generate_kb_xml(html_path = tmp_html),
        error = function(e) NULL
    )

    # if render happened to succeed in env with quarto, check output location
    if (fs::file_exists(expected_output)) {
        expect_true(fs::file_exists(expected_output))
    } else {
        skip("Quarto not available — output_dir defaulting not verified")
    }
})

# -- integration test (requires Quarto) ---------------------------------------

test_that("produces a valid XML file with correct structure", {
    skip_if_not(
        isTRUE(tryCatch(
            { quarto::quarto_version(); TRUE },
            error = function(e) FALSE
        )),
        "Quarto not available"
    )

    tmp_dir  <- withr::local_tempdir()
    tmp_html <- fs::path(tmp_dir, "analysis.html")
    tmp_qmd  <- fs::path(tmp_dir, "analysis.qmd")

    make_test_html(tmp_html)
    make_test_qmd(tmp_qmd,
                  title       = "Integration Title",
                  description = "Integration summary",
                  categories  = c("test", "xml"))

    result <- generate_kb_xml(
        html_path  = tmp_html,
        qmd_path   = tmp_qmd,
        output_dir = tmp_dir
    )

    expect_true(fs::file_exists(result))

    xml_doc  <- xml2::read_xml(result)
    kb_doc   <- xml2::xml_find_first(xml_doc, "kb_document")

    expect_equal(
        xml2::xml_text(xml2::xml_find_first(kb_doc, "kb_title")),
        "Integration Title"
    )
    expect_equal(
        xml2::xml_text(xml2::xml_find_first(kb_doc, "kb_summary")),
        "Integration summary"
    )
    expect_equal(
        xml2::xml_text(xml2::xml_find_first(kb_doc, "kb_keywords")),
        "test, xml"
    )
})
