# tests/testthat/test-create_qmd.R

# Helper: write a minimal yaml_data file to a temp location
make_yaml_config <- function(path) {
  yaml_content <- "
author:
  - name: 'Erwin Lares'
    affiliation: 'RCI, UW-Madison'
    orcid: '0000-0002-3284-828X'
    email: 'erwin.lares@wisc.edu'
"
  readr::write_file(yaml_content, path)
}

# -- Happy path ---------------------------------------------------------------

test_that("creates the named .qmd in the specified path", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd")
  expect_true(fs::file_exists(fs::path(tmp, "analysis.qmd")))
})

test_that("creates data/ folder and copies sample.csv", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd")
  expect_true(fs::dir_exists(fs::path(tmp, "data")))
  expect_true(fs::file_exists(fs::path(tmp, "data", "sample.csv")))
})

test_that("creates assets/ folder and copies styles.css and header.html", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd")
  expect_true(fs::dir_exists(fs::path(tmp, "assets")))
  expect_true(fs::file_exists(fs::path(tmp, "assets", "styles.css")))
  expect_true(fs::file_exists(fs::path(tmp, "assets", "header.html")))
})

test_that("returns path invisibly", {
  tmp <- withr::local_tempdir()
  result <- create_qmd(path = tmp, filename = "analysis.qmd")
  expect_equal(result, tmp)
})

test_that("respects custom filename argument", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "report.qmd")
  expect_true(fs::file_exists(fs::path(tmp, "report.qmd")))
  expect_false(fs::file_exists(fs::path(tmp, "analysis.qmd")))
})

test_that("pre-populates YAML when yaml_data is provided", {
  tmp <- withr::local_tempdir()
  yaml_file <- withr::local_tempfile(fileext = ".yml")
  make_yaml_config(yaml_file)

  create_qmd(path = tmp, filename = "analysis.qmd", yaml_data = yaml_file)

  qmd_content <- readr::read_file(fs::path(tmp, "analysis.qmd"))
  expect_true(grepl("Erwin Lares", qmd_content, fixed = TRUE))
  expect_true(grepl("RCI, UW-Madison", qmd_content, fixed = TRUE))
  expect_true(grepl("0000-0002-3284-828X", qmd_content, fixed = TRUE))
})

test_that("copies template as-is with placeholders when yaml_data is NULL", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd")

  qmd_content <- readr::read_file(fs::path(tmp, "analysis.qmd"))
  expect_true(grepl("Your Name", qmd_content, fixed = TRUE))
  expect_true(grepl("Your Document Title", qmd_content, fixed = TRUE))
})

# -- use_purl -----------------------------------------------------------------

test_that("creates _quarto.yml when use_purl = TRUE", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd", use_purl = TRUE)
  expect_true(fs::file_exists(fs::path(tmp, "_quarto.yml")))
})

test_that("_quarto.yml contains post-render hook", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd", use_purl = TRUE)
  content <- readr::read_file(fs::path(tmp, "_quarto.yml"))
  expect_true(grepl("post-render", content, fixed = TRUE))
  expect_true(grepl("purl.R", content, fixed = TRUE))
})

test_that("creates purl.R when use_purl = TRUE", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd", use_purl = TRUE)
  expect_true(fs::file_exists(fs::path(tmp, "purl.R")))
})

test_that("purl.R references QUARTO_DOCUMENT_PATH", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd", use_purl = TRUE)
  content <- readr::read_file(fs::path(tmp, "purl.R"))
  expect_true(grepl("QUARTO_DOCUMENT_PATH", content, fixed = TRUE))
})

test_that("does not create _quarto.yml when use_purl = FALSE", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd", use_purl = FALSE)
  expect_false(fs::file_exists(fs::path(tmp, "_quarto.yml")))
})

test_that("does not create purl.R when use_purl = FALSE", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd", use_purl = FALSE)
  expect_false(fs::file_exists(fs::path(tmp, "purl.R")))
})

test_that("skips existing _quarto.yml without erroring when overwrite is FALSE", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd", use_purl = TRUE)
  expect_no_error(
    create_qmd(path = tmp, filename = "report.qmd", use_purl = TRUE)
  )
})

# -- Edge cases ---------------------------------------------------------------

test_that("errors informatively when filename is NULL", {
  tmp <- withr::local_tempdir()
  expect_error(
    create_qmd(path = tmp),
    "filename"
  )
})

test_that("errors informatively when path does not exist", {
  expect_error(
    create_qmd(path = "/this/does/not/exist", filename = "analysis.qmd"),
    "does not exist"
  )
})

test_that("errors informatively when yaml_data path does not exist", {
  tmp <- withr::local_tempdir()
  expect_error(
    create_qmd(path = tmp, filename = "analysis.qmd",
               yaml_data = "/no/such/file.yml"),
    "does not exist"
  )
})

test_that("errors when .qmd already exists and overwrite is FALSE", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd")
  expect_error(
    create_qmd(path = tmp, filename = "analysis.qmd"),
    "already exists"
  )
})

test_that("overwrites .qmd when overwrite is TRUE", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd")
  expect_no_error(
    create_qmd(path = tmp, filename = "analysis.qmd", overwrite = TRUE)
  )
})

test_that("skips existing assets without erroring when overwrite is FALSE", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd")
  expect_no_error(
    create_qmd(path = tmp, filename = "report.qmd")
  )
})

test_that("skips existing sample.csv without erroring when overwrite is FALSE", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd")
  expect_no_error(
    create_qmd(path = tmp, filename = "report.qmd")
  )
})

# -- substitute_yaml() helper -------------------------------------------------

test_that("substitute_yaml() merges user values into template YAML", {
  template <- "---\ntitle: 'Your Document Title'\nauthor:\n  - name: 'Your Name'\n---\n\nBody text."
  user_yaml <- list(title = "My Real Title")

  result <- substitute_yaml(template, user_yaml)
  expect_true(grepl("My Real Title", result, fixed = TRUE))
})

test_that("substitute_yaml() warns and returns content unchanged when no YAML header found", {
  content <- "No YAML here, just body text."
  user_yaml <- list(title = "My Title")

  expect_warning(
    result <- substitute_yaml(content, user_yaml),
    "No YAML header found"
  )
  expect_equal(result, content)
})
