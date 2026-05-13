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

# Helper: create a style directory with one .css and one .html file
make_style_dir <- function(parent, dirname = "assets") {
  style_dir <- fs::path(parent, dirname)
  fs::dir_create(style_dir)
  readr::write_file(
    "body { font-family: sans-serif; }",
    fs::path(style_dir, "styles.css")
  )
  readr::write_file(
    "<header><h1>Branding</h1></header>",
    fs::path(style_dir, "header.html")
  )
  style_dir
}

# -- Happy path ---------------------------------------------------------------

test_that("creates the named .qmd in the specified path", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd")
  expect_true(fs::file_exists(fs::path(tmp, "analysis.qmd")))
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

# -- include_examples = TRUE (default) ----------------------------------------

test_that("creates data-raw/ folder and copies sample.csv when include_examples = TRUE", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd", include_examples = TRUE)
  expect_true(fs::dir_exists(fs::path(tmp, "data-raw")))
  expect_true(fs::file_exists(fs::path(tmp, "data-raw", "sample.csv")))
})

test_that("copies placeholder logo.png into assets/ when include_examples = TRUE", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd", include_examples = TRUE)
  expect_true(fs::dir_exists(fs::path(tmp, "assets")))
  expect_true(fs::file_exists(fs::path(tmp, "assets", "logo.png")))
})

test_that("uses the example template when include_examples = TRUE", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd", include_examples = TRUE)

  qmd_content <- readr::read_file(fs::path(tmp, "analysis.qmd"))
  expect_true(grepl("sample.csv", qmd_content, fixed = TRUE))
})

test_that("YAML includes params block when include_examples = TRUE", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd", include_examples = TRUE)

  qmd_content <- readr::read_file(fs::path(tmp, "analysis.qmd"))
  expect_true(grepl("params", qmd_content, fixed = TRUE))
  expect_true(grepl("input_file", qmd_content, fixed = TRUE))
})

# -- include_examples = FALSE --------------------------------------------------

test_that("does not create data-raw/ when include_examples = FALSE", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd", include_examples = FALSE)
  expect_false(fs::dir_exists(fs::path(tmp, "data-raw")))
})

test_that("does not copy sample.csv when include_examples = FALSE", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd", include_examples = FALSE)
  expect_false(fs::file_exists(fs::path(tmp, "data-raw", "sample.csv")))
})

test_that("does not copy logo.png when include_examples = FALSE", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd", include_examples = FALSE)
  expect_false(fs::file_exists(fs::path(tmp, "assets", "logo.png")))
})

test_that("uses the skeleton template when include_examples = FALSE", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd", include_examples = FALSE)

  qmd_content <- readr::read_file(fs::path(tmp, "analysis.qmd"))
  expect_false(grepl("sample.csv", qmd_content, fixed = TRUE))
})

test_that("skeleton YAML does not include params block", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd", include_examples = FALSE)

  qmd_content <- readr::read_file(fs::path(tmp, "analysis.qmd"))
  expect_false(grepl("params", qmd_content, fixed = TRUE))
})

test_that("skeleton contains a setup chunk with library(toolero)", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd", include_examples = FALSE)

  qmd_content <- readr::read_file(fs::path(tmp, "analysis.qmd"))
  expect_true(grepl("library(toolero)", qmd_content, fixed = TRUE))
})

# -- use_style = FALSE (default) -----------------------------------------------

test_that("does not inject css or include-before-body when use_style = FALSE", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd",
             use_style = FALSE, include_examples = FALSE)

  qmd_content <- readr::read_file(fs::path(tmp, "analysis.qmd"))
  expect_false(grepl("css:", qmd_content, fixed = TRUE))
  expect_false(grepl("include-before-body", qmd_content, fixed = TRUE))
})

# -- use_style = TRUE -----------------------------------------------------------

test_that("injects css and include-before-body when use_style = TRUE and assets exist", {
  tmp <- withr::local_tempdir()
  make_style_dir(tmp)

  create_qmd(
    path = tmp, filename = "analysis.qmd",
    include_examples = FALSE, use_style = TRUE
  )

  qmd_content <- readr::read_file(fs::path(tmp, "analysis.qmd"))
  expect_true(grepl("css:", qmd_content, fixed = TRUE))
  expect_true(grepl("styles.css", qmd_content, fixed = TRUE))
  expect_true(grepl("include-before-body", qmd_content, fixed = TRUE))
  expect_true(grepl("header.html", qmd_content, fixed = TRUE))
})

test_that("warns when use_style = TRUE but assets/ directory does not exist", {
  tmp <- withr::local_tempdir()

  expect_warning(
    create_qmd(
      path = tmp, filename = "analysis.qmd",
      include_examples = FALSE, use_style = TRUE
    ),
    "does not exist"
  )
})

test_that("warns when use_style = TRUE and assets/ is empty", {
  tmp <- withr::local_tempdir()
  fs::dir_create(fs::path(tmp, "assets"))

  expect_warning(
    create_qmd(
      path = tmp, filename = "analysis.qmd",
      include_examples = FALSE, use_style = TRUE
    ),
    "No.*files found"
  )
})

# -- use_style = directory path -------------------------------------------------

test_that("scans a custom style directory when use_style is a path", {
  tmp <- withr::local_tempdir()
  make_style_dir(tmp, "my-branding")

  create_qmd(
    path = tmp, filename = "analysis.qmd",
    include_examples = FALSE, use_style = fs::path(tmp, "my-branding")
  )

  qmd_content <- readr::read_file(fs::path(tmp, "analysis.qmd"))
  expect_true(grepl("css:", qmd_content, fixed = TRUE))
  expect_true(grepl("include-before-body", qmd_content, fixed = TRUE))
})

test_that("injects only css when style directory has .css but no .html", {
  tmp <- withr::local_tempdir()
  style_dir <- fs::path(tmp, "assets")
  fs::dir_create(style_dir)
  readr::write_file("body { color: red; }", fs::path(style_dir, "styles.css"))

  create_qmd(
    path = tmp, filename = "analysis.qmd",
    include_examples = FALSE, use_style = TRUE
  )

  qmd_content <- readr::read_file(fs::path(tmp, "analysis.qmd"))
  expect_true(grepl("css:", qmd_content, fixed = TRUE))
  expect_false(grepl("include-before-body", qmd_content, fixed = TRUE))
})

test_that("injects only include-before-body when style directory has .html but no .css", {
  tmp <- withr::local_tempdir()
  style_dir <- fs::path(tmp, "assets")
  fs::dir_create(style_dir)
  readr::write_file("<header>Hi</header>", fs::path(style_dir, "header.html"))

  create_qmd(
    path = tmp, filename = "analysis.qmd",
    include_examples = FALSE, use_style = TRUE
  )

  qmd_content <- readr::read_file(fs::path(tmp, "analysis.qmd"))
  expect_false(grepl("css:", qmd_content, fixed = TRUE))
  expect_true(grepl("include-before-body", qmd_content, fixed = TRUE))
})

test_that("errors when style directory contains multiple .css files", {
  tmp <- withr::local_tempdir()
  style_dir <- fs::path(tmp, "assets")
  fs::dir_create(style_dir)
  readr::write_file("body {}", fs::path(style_dir, "one.css"))
  readr::write_file("body {}", fs::path(style_dir, "two.css"))

  expect_error(
    create_qmd(
      path = tmp, filename = "analysis.qmd",
      include_examples = FALSE, use_style = TRUE
    ),
    "\\.css"
  )
})

test_that("errors when style directory contains multiple .html files", {
  tmp <- withr::local_tempdir()
  style_dir <- fs::path(tmp, "assets")
  fs::dir_create(style_dir)
  readr::write_file("<header>A</header>", fs::path(style_dir, "one.html"))
  readr::write_file("<header>B</header>", fs::path(style_dir, "two.html"))

  expect_error(
    create_qmd(
      path = tmp, filename = "analysis.qmd",
      include_examples = FALSE, use_style = TRUE
    ),
    "\\.html"
  )
})

test_that("warns when custom style directory does not exist", {
  tmp <- withr::local_tempdir()

  expect_warning(
    create_qmd(
      path = tmp, filename = "analysis.qmd",
      include_examples = FALSE, use_style = fs::path(tmp, "no-such-dir")
    ),
    "does not exist"
  )
})

# -- use_style with yaml_data override ------------------------------------------

test_that("yaml_data overrides auto-injected style values", {
  tmp <- withr::local_tempdir()
  make_style_dir(tmp)

  yaml_file <- withr::local_tempfile(fileext = ".yml")
  yaml_content <- "format:\n  html:\n    css: custom/override.css\n"
  readr::write_file(yaml_content, yaml_file)

  create_qmd(
    path = tmp, filename = "analysis.qmd",
    include_examples = FALSE, use_style = TRUE, yaml_data = yaml_file
  )

  qmd_content <- readr::read_file(fs::path(tmp, "analysis.qmd"))
  expect_true(grepl("override.css", qmd_content, fixed = TRUE))
})

# -- use_purl ------------------------------------------------------------------

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
  expect_true(fs::file_exists(fs::path(tmp, "R", "purl.R")))
})

test_that("purl.R uses glob-based qmd scanning", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd", use_purl = TRUE)
  content <- readr::read_file(fs::path(tmp, "R", "purl.R"))
  expect_true(grepl("dir_ls", content, fixed = TRUE))
})

test_that("does not create _quarto.yml when use_purl = FALSE", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd", use_purl = FALSE)
  expect_false(fs::file_exists(fs::path(tmp, "_quarto.yml")))
})

test_that("does not create purl.R when use_purl = FALSE", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd", use_purl = FALSE)
  expect_false(fs::file_exists(fs::path(tmp, "R", "purl.R")))
})

test_that("skips existing _quarto.yml without erroring when overwrite is FALSE", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd", use_purl = TRUE)
  expect_no_error(
    create_qmd(path = tmp, filename = "report.qmd", use_purl = TRUE)
  )
})

# -- Edge cases ----------------------------------------------------------------

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

test_that("skips existing sample.csv without erroring when overwrite is FALSE", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd")
  expect_no_error(
    create_qmd(path = tmp, filename = "report.qmd", overwrite = TRUE)
  )
})

test_that("skips existing logo.png without erroring when overwrite is FALSE", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd")
  expect_no_error(
    create_qmd(path = tmp, filename = "report.qmd", overwrite = TRUE)
  )
})

test_that("errors when use_style receives an invalid type", {
  tmp <- withr::local_tempdir()
  expect_error(
    create_qmd(
      path = tmp, filename = "analysis.qmd", use_style = 42
    ),
    "use_style"
  )
})

# -- Combination tests ---------------------------------------------------------

test_that("include_examples = TRUE with use_style = TRUE copies data and injects style", {
  tmp <- withr::local_tempdir()
  make_style_dir(tmp)

  create_qmd(
    path = tmp, filename = "analysis.qmd",
    include_examples = TRUE, use_style = TRUE
  )

  expect_true(fs::file_exists(fs::path(tmp, "data-raw", "sample.csv")))
  expect_true(fs::file_exists(fs::path(tmp, "assets", "logo.png")))

  qmd_content <- readr::read_file(fs::path(tmp, "analysis.qmd"))
  expect_true(grepl("css:", qmd_content, fixed = TRUE))
  expect_true(grepl("include-before-body", qmd_content, fixed = TRUE))
  expect_true(grepl("params", qmd_content, fixed = TRUE))
})

test_that("include_examples = FALSE with use_style = FALSE produces minimal skeleton", {
  tmp <- withr::local_tempdir()

  create_qmd(
    path = tmp, filename = "analysis.qmd",
    include_examples = FALSE, use_style = FALSE, use_purl = FALSE
  )

  expect_false(fs::dir_exists(fs::path(tmp, "data-raw")))
  expect_false(fs::file_exists(fs::path(tmp, "assets", "logo.png")))
  expect_false(fs::file_exists(fs::path(tmp, "_quarto.yml")))

  qmd_content <- readr::read_file(fs::path(tmp, "analysis.qmd"))
  expect_false(grepl("sample.csv", qmd_content, fixed = TRUE))
  expect_false(grepl("css:", qmd_content, fixed = TRUE))
  expect_false(grepl("params", qmd_content, fixed = TRUE))
  expect_true(grepl("library(toolero)", qmd_content, fixed = TRUE))
})

# -- .substitute_yaml() helper -------------------------------------------------

test_that("substitute_yaml() merges user values into template YAML", {
  template <- "---\ntitle: 'Your Document Title'\nauthor:\n  - name: 'Your Name'\n---\n\nBody text."
  user_yaml <- list(title = "My Real Title")

  result <- .substitute_yaml(template, user_yaml)
  expect_true(grepl("My Real Title", result, fixed = TRUE))
})

test_that("substitute_yaml() warns and returns content unchanged when no YAML header found", {
  content <- "No YAML here, just body text."
  user_yaml <- list(title = "My Title")

  expect_warning(
    result <- .substitute_yaml(content, user_yaml),
    "No YAML header found"
  )
  expect_equal(result, content)
})

test_that("substitute_yaml() serializes logicals as true/false not yes/no", {
  template <- "---\ntoc: true\nnumber-sections: true\nembed-resources: false\n---\n\nBody."
  user_yaml <- list(title = "My Title")

  result <- .substitute_yaml(template, user_yaml)
  expect_true(grepl("true", result, fixed = TRUE))
  expect_false(grepl("yes", result, fixed = TRUE))
  expect_false(grepl("no", result, fixed = TRUE))
})

# -- .inject_style_yaml() helper -----------------------------------------------

test_that("inject_style_yaml() adds css to YAML", {
  template <- "---\nformat:\n  html:\n    toc: true\n---\n\nBody."

  result <- .inject_style_yaml(template, css_file = "assets/styles.css")
  expect_true(grepl("css:", result, fixed = TRUE))
  expect_true(grepl("styles.css", result, fixed = TRUE))
})

test_that("inject_style_yaml() adds include-before-body to YAML", {
  template <- "---\nformat:\n  html:\n    toc: true\n---\n\nBody."

  result <- .inject_style_yaml(template, html_file = "assets/header.html")
  expect_true(grepl("include-before-body", result, fixed = TRUE))
  expect_true(grepl("header.html", result, fixed = TRUE))
})

test_that("inject_style_yaml() adds both when both are provided", {
  template <- "---\nformat:\n  html:\n    toc: true\n---\n\nBody."

  result <- .inject_style_yaml(
    template,
    css_file = "assets/styles.css",
    html_file = "assets/header.html"
  )
  expect_true(grepl("css:", result, fixed = TRUE))
  expect_true(grepl("include-before-body", result, fixed = TRUE))
})

test_that("inject_style_yaml() warns when no YAML header is found", {
  content <- "No YAML here."

  expect_warning(
    result <- .inject_style_yaml(content, css_file = "styles.css"),
    "No YAML header found"
  )
  expect_equal(result, content)
})

test_that("inject_style_yaml() creates format$html if absent", {
  template <- "---\ntitle: 'Test'\n---\n\nBody."

  result <- .inject_style_yaml(template, css_file = "assets/styles.css")
  expect_true(grepl("css:", result, fixed = TRUE))
  expect_true(grepl("format:", result, fixed = TRUE))
})
