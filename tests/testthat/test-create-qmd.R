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

# Helper: create a style directory with standardized branding files
make_style_dir <- function(parent, dirname = "assets") {
  style_dir <- fs::path(parent, dirname)
  fs::dir_create(style_dir)
  readr::write_file(
    "body { font-family: sans-serif; }",
    fs::path(style_dir, "styles.css")
  )
  readr::write_file(
    "<div class='header'><h1>Branding</h1></div>",
    fs::path(style_dir, "header.html")
  )
  readr::write_file(
    "<div class='footer'>Footer text</div>",
    fs::path(style_dir, "footer.html")
  )
  style_dir
}

# Helper: write a _quarto.yml with arbitrary content, simulating a
# pre-existing project (e.g. a Quarto website) at `path`
make_quarto_yml <- function(path, content) {
  readr::write_file(content, fs::path(path, "_quarto.yml"))
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

test_that("pre-populates YAML when header_defaults is provided", {
  tmp <- withr::local_tempdir()
  yaml_file <- withr::local_tempfile(fileext = ".yml")
  make_yaml_config(yaml_file)

  create_qmd(path = tmp, filename = "analysis.qmd", header_defaults = yaml_file)

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
  expect_true(grepl("resolve_input_path(", qmd_content, fixed = TRUE))
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

# -- logo.png overwrite exemption ----------------------------------------------

test_that("does not overwrite logo.png even when overwrite = TRUE", {
  tmp <- withr::local_tempdir()

  # Place a sentinel file in assets/ to stand in for a branding logo
  assets_dir <- fs::path(tmp, "assets")
  fs::dir_create(assets_dir)
  readr::write_file("sentinel", fs::path(assets_dir, "logo.png"))

  create_qmd(
    path = tmp, filename = "analysis.qmd",
    include_examples = TRUE, overwrite = TRUE
  )

  # Generic placeholder must not have replaced the sentinel
  content <- readr::read_file(fs::path(assets_dir, "logo.png"))
  expect_equal(content, "sentinel")
})

test_that("logo.png is left in place when it already exists and overwrite = FALSE", {
  tmp <- withr::local_tempdir()

  assets_dir <- fs::path(tmp, "assets")
  fs::dir_create(assets_dir)
  readr::write_file("sentinel", fs::path(assets_dir, "logo.png"))

  create_qmd(
    path = tmp, filename = "analysis.qmd",
    include_examples = TRUE, overwrite = FALSE
  )

  content <- readr::read_file(fs::path(assets_dir, "logo.png"))
  expect_equal(content, "sentinel")
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

test_that("injects css, include-before-body, and include-after-body when use_style = TRUE and all assets exist", {
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
  expect_true(grepl("include-after-body", qmd_content, fixed = TRUE))
  expect_true(grepl("footer.html", qmd_content, fixed = TRUE))
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

test_that("warns when use_style = TRUE and assets/ has none of the standardized files", {
  tmp <- withr::local_tempdir()
  fs::dir_create(fs::path(tmp, "assets"))

  expect_warning(
    create_qmd(
      path = tmp, filename = "analysis.qmd",
      include_examples = FALSE, use_style = TRUE
    ),
    "Skipping style injection"
  )
})

# -- use_style = TRUE: partial asset sets --------------------------------------

test_that("injects only css when assets/ has styles.css but no html files", {
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
  expect_false(grepl("include-after-body", qmd_content, fixed = TRUE))
})

test_that("injects only include-before-body when assets/ has header.html but no css or footer", {
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
  expect_false(grepl("include-after-body", qmd_content, fixed = TRUE))
})

test_that("injects only include-after-body when assets/ has footer.html but no css or header", {
  tmp <- withr::local_tempdir()
  style_dir <- fs::path(tmp, "assets")
  fs::dir_create(style_dir)
  readr::write_file("<footer>Bye</footer>", fs::path(style_dir, "footer.html"))

  create_qmd(
    path = tmp, filename = "analysis.qmd",
    include_examples = FALSE, use_style = TRUE
  )

  qmd_content <- readr::read_file(fs::path(tmp, "analysis.qmd"))
  expect_false(grepl("css:", qmd_content, fixed = TRUE))
  expect_false(grepl("include-before-body", qmd_content, fixed = TRUE))
  expect_true(grepl("include-after-body", qmd_content, fixed = TRUE))
})

test_that("ignores files in assets/ that do not match standardized names", {
  tmp <- withr::local_tempdir()
  style_dir <- fs::path(tmp, "assets")
  fs::dir_create(style_dir)
  readr::write_file("body {}", fs::path(style_dir, "custom-theme.css"))
  readr::write_file("<div>hi</div>", fs::path(style_dir, "banner.html"))

  # This case is expected to warn (the dedicated warning behavior itself
  # is covered by the "warns when use_style = TRUE and assets/ has none
  # of the standardized files" test above) -- this test is only about
  # what happens to the YAML afterward, so catch it rather than leaving
  # it unhandled.
  expect_warning(
    create_qmd(
      path = tmp, filename = "analysis.qmd",
      include_examples = FALSE, use_style = TRUE
    ),
    "Skipping style injection"
  )

  qmd_content <- readr::read_file(fs::path(tmp, "analysis.qmd"))
  expect_false(grepl("css:", qmd_content, fixed = TRUE))
  expect_false(grepl("include-before-body", qmd_content, fixed = TRUE))
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
  expect_true(grepl("include-after-body", qmd_content, fixed = TRUE))
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

# -- use_style with header_defaults override -------------------------------------

test_that("header_defaults overrides auto-injected style values", {
  tmp <- withr::local_tempdir()
  make_style_dir(tmp)

  yaml_file <- withr::local_tempfile(fileext = ".yml")
  yaml_content <- "format:\n  html:\n    css: custom/override.css\n"
  readr::write_file(yaml_content, yaml_file)

  create_qmd(
    path = tmp, filename = "analysis.qmd",
    include_examples = FALSE, use_style = TRUE, header_defaults = yaml_file
  )

  qmd_content <- readr::read_file(fs::path(tmp, "analysis.qmd"))
  expect_true(grepl("override.css", qmd_content, fixed = TRUE))
})

test_that("header_defaults preserves use_style's other injected keys when overriding one sibling (T-G6)", {
  tmp <- withr::local_tempdir()
  make_style_dir(tmp)

  yaml_file <- withr::local_tempfile(fileext = ".yml")
  # Overrides only css: the header_file/footer_file keys use_style injected
  # into the same format: html: mapping are not mentioned here at all, and
  # should survive rather than being discarded along with the rest of the
  # block css lives in.
  readr::write_file("format:\n  html:\n    css: custom/override.css\n", yaml_file)

  create_qmd(
    path = tmp, filename = "analysis.qmd",
    include_examples = FALSE, use_style = TRUE, header_defaults = yaml_file
  )

  qmd_content <- readr::read_file(fs::path(tmp, "analysis.qmd"))
  expect_true(grepl("override.css", qmd_content, fixed = TRUE))
  expect_true(grepl("include-before-body", qmd_content, fixed = TRUE))
  expect_true(grepl("include-after-body", qmd_content, fixed = TRUE))
})

# -- use_purl: default and header stamping -------------------------------------

test_that("use_purl defaults to FALSE: no _quarto.yml or R/purl.R created", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd")
  expect_false(fs::file_exists(fs::path(tmp, "_quarto.yml")))
  expect_false(fs::file_exists(fs::path(tmp, "R", "purl.R")))
})

test_that("stamps purl: false in the header by default", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd")
  qmd_content <- readr::read_file(fs::path(tmp, "analysis.qmd"))
  expect_true(grepl("purl: false", qmd_content, fixed = TRUE))
})

test_that("stamps purl: true in the header when use_purl = TRUE", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd", use_purl = TRUE)
  qmd_content <- readr::read_file(fs::path(tmp, "analysis.qmd"))
  expect_true(grepl("purl: true", qmd_content, fixed = TRUE))
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

# -- use_purl: fresh _quarto.yml -------------------------------------------------

test_that("creates _quarto.yml when use_purl = TRUE and none exists", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd", use_purl = TRUE)
  expect_true(fs::file_exists(fs::path(tmp, "_quarto.yml")))
})

test_that("fresh _quarto.yml contains post-render hook pointing at R/purl.R", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd", use_purl = TRUE)
  parsed <- yaml::read_yaml(fs::path(tmp, "_quarto.yml"))
  expect_true("R/purl.R" %in% as.character(parsed[["project"]][["post-render"]]))
})

test_that("creates R/purl.R when use_purl = TRUE", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd", use_purl = TRUE)
  expect_true(fs::file_exists(fs::path(tmp, "R", "purl.R")))
})

test_that("deployed purl.R reads QUARTO_PROJECT_OUTPUT_FILES rather than globbing the project root", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd", use_purl = TRUE)
  content <- readr::read_file(fs::path(tmp, "R", "purl.R"))
  expect_true(grepl("QUARTO_PROJECT_OUTPUT_FILES", content, fixed = TRUE))
})

# -- use_purl: merging into an existing _quarto.yml (non-guarded types) ---------
# type: website / book / manuscript are guarded -- see the dedicated
# section below. These tests use neutral fixtures (no project: type:, or
# a type outside the guarded set) so they actually exercise .merge_post_
# render_hook() through create_qmd(), rather than tripping the guard.

test_that("merging into an existing _quarto.yml adds the post-render hook", {
  tmp <- withr::local_tempdir()
  make_quarto_yml(tmp, "project:\n  execute-dir: project\n")

  create_qmd(path = tmp, filename = "analysis.qmd", use_purl = TRUE)

  parsed <- yaml::read_yaml(fs::path(tmp, "_quarto.yml"))
  expect_true("R/purl.R" %in% as.character(parsed[["project"]][["post-render"]]))
})

test_that("does not duplicate the post-render hook across two create_qmd() calls", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd", use_purl = TRUE)
  create_qmd(path = tmp, filename = "report.qmd", use_purl = TRUE)

  parsed <- yaml::read_yaml(fs::path(tmp, "_quarto.yml"))
  hooks <- as.character(parsed[["project"]][["post-render"]])
  expect_equal(sum(hooks == "R/purl.R"), 1)
})

test_that("second create_qmd() call with use_purl = TRUE does not error on an already-merged _quarto.yml", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd", use_purl = TRUE)
  expect_no_error(
    create_qmd(path = tmp, filename = "report.qmd", use_purl = TRUE)
  )
})

test_that("normalizes an existing post-render entry given as a bare string", {
  tmp <- withr::local_tempdir()
  make_quarto_yml(tmp, "project:\n  execute-dir: project\n  post-render: existing-script.R\n")

  create_qmd(path = tmp, filename = "analysis.qmd", use_purl = TRUE)

  parsed <- yaml::read_yaml(fs::path(tmp, "_quarto.yml"))
  hooks <- as.character(parsed[["project"]][["post-render"]])
  expect_true("existing-script.R" %in% hooks)
  expect_true("R/purl.R" %in% hooks)
  expect_length(hooks, 2)
})

test_that("normalizes an existing post-render entry given as a list", {
  tmp <- withr::local_tempdir()
  make_quarto_yml(
    tmp,
    "project:\n  execute-dir: project\n  post-render:\n    - compress.ts\n    - fix-links.py\n"
  )

  create_qmd(path = tmp, filename = "analysis.qmd", use_purl = TRUE)

  parsed <- yaml::read_yaml(fs::path(tmp, "_quarto.yml"))
  hooks <- as.character(parsed[["project"]][["post-render"]])
  expect_true(all(c("compress.ts", "fix-links.py", "R/purl.R") %in% hooks))
  expect_length(hooks, 3)
})

test_that("does not add a second entry when R/purl.R is already the post-render hook", {
  tmp <- withr::local_tempdir()
  make_quarto_yml(tmp, "project:\n  execute-dir: project\n  post-render: R/purl.R\n")

  create_qmd(path = tmp, filename = "analysis.qmd", use_purl = TRUE)

  parsed <- yaml::read_yaml(fs::path(tmp, "_quarto.yml"))
  hooks <- as.character(parsed[["project"]][["post-render"]])
  expect_equal(sum(hooks == "R/purl.R"), 1)
})

test_that("adds a project: block when merging into a _quarto.yml that lacks one", {
  tmp <- withr::local_tempdir()
  make_quarto_yml(tmp, "preview:\n  port: 4200\n")

  create_qmd(path = tmp, filename = "analysis.qmd", use_purl = TRUE)

  parsed <- yaml::read_yaml(fs::path(tmp, "_quarto.yml"))
  expect_true("R/purl.R" %in% as.character(parsed[["project"]][["post-render"]]))
  expect_equal(parsed[["preview"]][["port"]], 4200)
})

test_that("merges the hook regardless of overwrite = FALSE, for a non-guarded project", {
  tmp <- withr::local_tempdir()
  make_quarto_yml(tmp, "project:\n  execute-dir: project\nformat:\n  html:\n    theme: cosmo\n")

  create_qmd(
    path = tmp, filename = "analysis.qmd",
    use_purl = TRUE, overwrite = FALSE
  )

  parsed <- yaml::read_yaml(fs::path(tmp, "_quarto.yml"))
  expect_equal(parsed[["format"]][["html"]][["theme"]], "cosmo")
  expect_true("R/purl.R" %in% as.character(parsed[["project"]][["post-render"]]))
})

# -- use_purl: guard skips _quarto.yml wiring for website/book/manuscript -------
# R/purl.R mirrors each purled document's path under R/, which resolves
# the same-basename collision within a single project -- but a website,
# book, or manuscript project renders many documents on every full build,
# and the person scaffolding one .qmd may not be thinking about the
# others. The guard skips automatic wiring for these three project types
# and explains how to opt in by hand.

test_that("skips wiring and warns for project: type: website, leaving the file untouched", {
  tmp <- withr::local_tempdir()
  make_quarto_yml(tmp, "project:\n  type: website\nwebsite:\n  title: My Site\n")

  expect_warning(
    create_qmd(path = tmp, filename = "analysis.qmd", use_purl = TRUE),
    "website"
  )

  parsed <- yaml::read_yaml(fs::path(tmp, "_quarto.yml"))
  expect_equal(parsed[["project"]][["type"]], "website")
  expect_equal(parsed[["website"]][["title"]], "My Site")
  expect_null(parsed[["project"]][["post-render"]])
})

test_that("skips wiring and warns for project: type: book, leaving the file untouched", {
  tmp <- withr::local_tempdir()
  make_quarto_yml(tmp, "project:\n  type: book\nbook:\n  title: My Book\n")

  expect_warning(
    create_qmd(path = tmp, filename = "analysis.qmd", use_purl = TRUE),
    "book"
  )

  parsed <- yaml::read_yaml(fs::path(tmp, "_quarto.yml"))
  expect_equal(parsed[["project"]][["type"]], "book")
  expect_equal(parsed[["book"]][["title"]], "My Book")
  expect_null(parsed[["project"]][["post-render"]])
})

test_that("skips wiring and warns for project: type: manuscript, leaving the file untouched", {
  tmp <- withr::local_tempdir()
  make_quarto_yml(tmp, "project:\n  type: manuscript\n")

  expect_warning(
    create_qmd(path = tmp, filename = "analysis.qmd", use_purl = TRUE),
    "manuscript"
  )

  parsed <- yaml::read_yaml(fs::path(tmp, "_quarto.yml"))
  expect_equal(parsed[["project"]][["type"]], "manuscript")
  expect_null(parsed[["project"]][["post-render"]])
})

test_that("guard leaves an existing post-render entry in a website project untouched", {
  tmp <- withr::local_tempdir()
  make_quarto_yml(tmp, "project:\n  type: website\n  post-render: some-other-script.R\n")

  suppressWarnings(
    create_qmd(path = tmp, filename = "analysis.qmd", use_purl = TRUE)
  )

  parsed <- yaml::read_yaml(fs::path(tmp, "_quarto.yml"))
  hooks <- as.character(parsed[["project"]][["post-render"]])
  expect_equal(hooks, "some-other-script.R")
  expect_false("R/purl.R" %in% hooks)
})

test_that("still creates R/purl.R even when _quarto.yml wiring is skipped by the guard", {
  tmp <- withr::local_tempdir()
  make_quarto_yml(tmp, "project:\n  type: website\n")

  suppressWarnings(
    create_qmd(path = tmp, filename = "analysis.qmd", use_purl = TRUE)
  )

  expect_true(fs::file_exists(fs::path(tmp, "R", "purl.R")))
})

test_that("still stamps purl: true in the document header even when the guard skips _quarto.yml wiring", {
  tmp <- withr::local_tempdir()
  make_quarto_yml(tmp, "project:\n  type: website\n")

  suppressWarnings(
    create_qmd(path = tmp, filename = "analysis.qmd", use_purl = TRUE)
  )

  qmd_content <- readr::read_file(fs::path(tmp, "analysis.qmd"))
  expect_true(grepl("purl: true", qmd_content, fixed = TRUE))
})

test_that("the guard fires regardless of overwrite = TRUE", {
  tmp <- withr::local_tempdir()
  make_quarto_yml(tmp, "project:\n  type: website\nwebsite:\n  title: My Site\n")

  expect_warning(
    create_qmd(
      path = tmp, filename = "analysis.qmd",
      use_purl = TRUE, overwrite = TRUE
    ),
    "website"
  )

  parsed <- yaml::read_yaml(fs::path(tmp, "_quarto.yml"))
  expect_equal(parsed[["website"]][["title"]], "My Site")
  expect_null(parsed[["project"]][["post-render"]])
})

test_that("warning names the file, the project type, and shows the manual post-render snippet", {
  tmp <- withr::local_tempdir()
  make_quarto_yml(tmp, "project:\n  type: website\n")

  expect_warning(
    create_qmd(path = tmp, filename = "analysis.qmd", use_purl = TRUE),
    "post-render"
  )
})

test_that("does not guard a _quarto.yml with no project: type: at all", {
  tmp <- withr::local_tempdir()
  make_quarto_yml(tmp, "project:\n  execute-dir: project\n")

  expect_no_warning(
    create_qmd(path = tmp, filename = "analysis.qmd", use_purl = TRUE)
  )

  parsed <- yaml::read_yaml(fs::path(tmp, "_quarto.yml"))
  expect_true("R/purl.R" %in% as.character(parsed[["project"]][["post-render"]]))
})

test_that("does not guard a fresh project with no pre-existing _quarto.yml", {
  tmp <- withr::local_tempdir()

  expect_no_warning(
    create_qmd(path = tmp, filename = "analysis.qmd", use_purl = TRUE)
  )

  parsed <- yaml::read_yaml(fs::path(tmp, "_quarto.yml"))
  expect_true("R/purl.R" %in% as.character(parsed[["project"]][["post-render"]]))
})

# -- .quarto_project_type() helper -----------------------------------------------

test_that("quarto_project_type() returns NULL when _quarto.yml does not exist", {
  tmp <- withr::local_tempdir()
  expect_null(.quarto_project_type(fs::path(tmp, "_quarto.yml")))
})

test_that("quarto_project_type() returns NULL when project: key is absent", {
  tmp <- withr::local_tempdir()
  yml_path <- fs::path(tmp, "_quarto.yml")
  readr::write_file("preview:\n  port: 4200\n", yml_path)
  expect_null(.quarto_project_type(yml_path))
})

test_that("quarto_project_type() returns NULL when project: exists but type: is absent", {
  tmp <- withr::local_tempdir()
  yml_path <- fs::path(tmp, "_quarto.yml")
  readr::write_file("project:\n  execute-dir: project\n", yml_path)
  expect_null(.quarto_project_type(yml_path))
})

test_that("quarto_project_type() returns the type when set", {
  tmp <- withr::local_tempdir()
  yml_path <- fs::path(tmp, "_quarto.yml")
  readr::write_file("project:\n  type: book\n", yml_path)
  expect_equal(.quarto_project_type(yml_path), "book")
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

test_that("errors informatively when header_defaults path does not exist", {
  tmp <- withr::local_tempdir()
  expect_error(
    create_qmd(path = tmp, filename = "analysis.qmd",
               header_defaults = "/no/such/file.yml"),
    "does not exist"
  )
})

# -- yaml_data -> header_defaults rename (deprecation) ---------------------------

test_that("yaml_data still works, via the deprecation shim", {
  tmp <- withr::local_tempdir()
  yaml_file <- withr::local_tempfile(fileext = ".yml")
  make_yaml_config(yaml_file)

  suppressWarnings(
    create_qmd(path = tmp, filename = "analysis.qmd", yaml_data = yaml_file)
  )

  qmd_content <- readr::read_file(fs::path(tmp, "analysis.qmd"))
  expect_true(grepl("Erwin Lares", qmd_content, fixed = TRUE))
})

test_that("supplying yaml_data emits a lifecycle deprecation warning", {
  tmp <- withr::local_tempdir()
  yaml_file <- withr::local_tempfile(fileext = ".yml")
  make_yaml_config(yaml_file)

  expect_warning(
    create_qmd(path = tmp, filename = "analysis.qmd", yaml_data = yaml_file),
    class = "lifecycle_warning_deprecated"
  )
})

test_that("supplying header_defaults alone does not warn", {
  tmp <- withr::local_tempdir()
  yaml_file <- withr::local_tempfile(fileext = ".yml")
  make_yaml_config(yaml_file)

  expect_no_warning(
    create_qmd(path = tmp, filename = "analysis.qmd", header_defaults = yaml_file)
  )
})

test_that("header_defaults takes precedence when both header_defaults and yaml_data are supplied", {
  tmp <- withr::local_tempdir()

  header_defaults_file <- withr::local_tempfile(fileext = ".yml")
  readr::write_file("title: 'From header_defaults'\n", header_defaults_file)

  yaml_data_file <- withr::local_tempfile(fileext = ".yml")
  readr::write_file("title: 'From yaml_data'\n", yaml_data_file)

  suppressWarnings(
    create_qmd(
      path = tmp, filename = "analysis.qmd",
      header_defaults = header_defaults_file, yaml_data = yaml_data_file
    )
  )

  qmd_content <- readr::read_file(fs::path(tmp, "analysis.qmd"))
  expect_true(grepl("From header_defaults", qmd_content, fixed = TRUE))
  expect_false(grepl("From yaml_data", qmd_content, fixed = TRUE))
})

test_that("errors informatively when yaml_data (deprecated) path does not exist", {
  tmp <- withr::local_tempdir()
  expect_error(
    suppressWarnings(
      create_qmd(path = tmp, filename = "analysis.qmd",
                 yaml_data = "/no/such/file.yml")
    ),
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

test_that("include_examples = TRUE with use_style = TRUE copies data and injects all style keys", {
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
  expect_true(grepl("include-after-body", qmd_content, fixed = TRUE))
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

test_that("use_purl = TRUE with use_style = TRUE stamps purl: true and injects style keys in the same document", {
  tmp <- withr::local_tempdir()
  make_style_dir(tmp)

  create_qmd(
    path = tmp, filename = "analysis.qmd",
    include_examples = FALSE, use_style = TRUE, use_purl = TRUE
  )

  qmd_content <- readr::read_file(fs::path(tmp, "analysis.qmd"))
  expect_true(grepl("purl: true", qmd_content, fixed = TRUE))
  expect_true(grepl("css:", qmd_content, fixed = TRUE))
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

  result <- .inject_style_yaml(template, header_file = "assets/header.html")
  expect_true(grepl("include-before-body", result, fixed = TRUE))
  expect_true(grepl("header.html", result, fixed = TRUE))
})

test_that("inject_style_yaml() adds include-after-body to YAML", {
  template <- "---\nformat:\n  html:\n    toc: true\n---\n\nBody."

  result <- .inject_style_yaml(template, footer_file = "assets/footer.html")
  expect_true(grepl("include-after-body", result, fixed = TRUE))
  expect_true(grepl("footer.html", result, fixed = TRUE))
})

test_that("inject_style_yaml() adds all three when all are provided", {
  template <- "---\nformat:\n  html:\n    toc: true\n---\n\nBody."

  result <- .inject_style_yaml(
    template,
    css_file    = "assets/styles.css",
    header_file = "assets/header.html",
    footer_file = "assets/footer.html"
  )
  expect_true(grepl("css:", result, fixed = TRUE))
  expect_true(grepl("include-before-body", result, fixed = TRUE))
  expect_true(grepl("include-after-body", result, fixed = TRUE))
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

# -- .inject_purl_yaml() helper -------------------------------------------------

test_that("inject_purl_yaml() adds purl: true to YAML", {
  template <- "---\ntitle: 'Test'\n---\n\nBody."

  result <- .inject_purl_yaml(template, purl = TRUE)
  expect_true(grepl("purl: true", result, fixed = TRUE))
})

test_that("inject_purl_yaml() adds purl: false to YAML", {
  template <- "---\ntitle: 'Test'\n---\n\nBody."

  result <- .inject_purl_yaml(template, purl = FALSE)
  expect_true(grepl("purl: false", result, fixed = TRUE))
})

test_that("inject_purl_yaml() overwrites an existing purl key", {
  template <- "---\ntitle: 'Test'\npurl: false\n---\n\nBody."

  result <- .inject_purl_yaml(template, purl = TRUE)
  expect_true(grepl("purl: true", result, fixed = TRUE))
  expect_false(grepl("purl: false", result, fixed = TRUE))
})

test_that("inject_purl_yaml() warns and returns content unchanged when no YAML header is found", {
  content <- "No YAML here."

  expect_warning(
    result <- .inject_purl_yaml(content, purl = TRUE),
    "No YAML header found"
  )
  expect_equal(result, content)
})

# -- .merge_post_render_hook() helper -------------------------------------------

test_that("merge_post_render_hook() adds a project: block when none exists", {
  tmp <- withr::local_tempdir()
  yml_path <- fs::path(tmp, "_quarto.yml")
  readr::write_file("preview:\n  port: 4200\n", yml_path)

  added <- .merge_post_render_hook(yml_path, hook = "R/purl.R")
  expect_true(added)

  parsed <- yaml::read_yaml(yml_path)
  expect_true("R/purl.R" %in% as.character(parsed[["project"]][["post-render"]]))
  expect_equal(parsed[["preview"]][["port"]], 4200)
})

test_that("merge_post_render_hook() preserves other keys in an existing project: block", {
  tmp <- withr::local_tempdir()
  yml_path <- fs::path(tmp, "_quarto.yml")
  readr::write_file("project:\n  type: website\n  output-dir: _site\n", yml_path)

  .merge_post_render_hook(yml_path, hook = "R/purl.R")

  parsed <- yaml::read_yaml(yml_path)
  expect_equal(parsed[["project"]][["type"]], "website")
  expect_equal(parsed[["project"]][["output-dir"]], "_site")
  expect_true("R/purl.R" %in% as.character(parsed[["project"]][["post-render"]]))
})

test_that("merge_post_render_hook() returns FALSE and leaves the file unchanged when the hook is already present", {
  tmp <- withr::local_tempdir()
  yml_path <- fs::path(tmp, "_quarto.yml")
  readr::write_file("project:\n  type: website\n  post-render: R/purl.R\n", yml_path)

  before <- readr::read_file(yml_path)
  added <- .merge_post_render_hook(yml_path, hook = "R/purl.R")
  after <- readr::read_file(yml_path)

  expect_false(added)
  expect_equal(before, after)
})

test_that("merge_post_render_hook() normalizes a bare-string post-render entry", {
  tmp <- withr::local_tempdir()
  yml_path <- fs::path(tmp, "_quarto.yml")
  readr::write_file("project:\n  post-render: existing-script.R\n", yml_path)

  .merge_post_render_hook(yml_path, hook = "R/purl.R")

  parsed <- yaml::read_yaml(yml_path)
  hooks <- as.character(parsed[["project"]][["post-render"]])
  expect_setequal(hooks, c("existing-script.R", "R/purl.R"))
})

test_that("merge_post_render_hook() normalizes a list post-render entry without dropping existing scripts", {
  tmp <- withr::local_tempdir()
  yml_path <- fs::path(tmp, "_quarto.yml")
  readr::write_file(
    "project:\n  post-render:\n    - compress.ts\n    - fix-links.py\n",
    yml_path
  )

  .merge_post_render_hook(yml_path, hook = "R/purl.R")

  parsed <- yaml::read_yaml(yml_path)
  hooks <- as.character(parsed[["project"]][["post-render"]])
  expect_setequal(hooks, c("compress.ts", "fix-links.py", "R/purl.R"))
})

# -- T15: R/purl.R is scaffolded subject to overwrite, and the guard says so ----

test_that("an existing R/purl.R is left in place when overwrite = FALSE", {
  tmp <- withr::local_tempdir()
  fs::dir_create(fs::path(tmp, "R"))
  readr::write_file("# stale copy\n", fs::path(tmp, "R", "purl.R"))

  create_qmd(path = tmp, filename = "analysis.qmd", use_purl = TRUE)

  expect_equal(
    readr::read_file(fs::path(tmp, "R", "purl.R")),
    "# stale copy\n"
  )
})

test_that("an existing R/purl.R is replaced when overwrite = TRUE", {
  tmp <- withr::local_tempdir()
  fs::dir_create(fs::path(tmp, "R"))
  readr::write_file("# stale copy\n", fs::path(tmp, "R", "purl.R"))

  create_qmd(
    path = tmp, filename = "analysis.qmd",
    use_purl = TRUE, overwrite = TRUE
  )

  expect_false(
    grepl("stale copy", readr::read_file(fs::path(tmp, "R", "purl.R")),
          fixed = TRUE)
  )
})

test_that("the guard's warning says R/purl.R was created when it was", {
  tmp <- withr::local_tempdir()
  make_quarto_yml(tmp, "project:\n  type: website\n")

  expect_warning(
    create_qmd(path = tmp, filename = "analysis.qmd", use_purl = TRUE),
    "created"
  )
})

test_that("the guard's warning says R/purl.R was already there when it was", {
  tmp <- withr::local_tempdir()
  make_quarto_yml(tmp, "project:\n  type: website\n")
  fs::dir_create(fs::path(tmp, "R"))
  readr::write_file("# stale copy\n", fs::path(tmp, "R", "purl.R"))

  expect_warning(
    create_qmd(path = tmp, filename = "analysis.qmd", use_purl = TRUE),
    "already"
  )
})

# -- T16: the header is edited in place, not parsed and rewritten --------------

test_that("the example template's quoting and block scalar survive scaffolding", {
  tmp <- withr::local_tempdir()
  make_style_dir(tmp)

  create_qmd(
    path = tmp, filename = "analysis.qmd",
    include_examples = TRUE, use_style = TRUE, use_purl = TRUE
  )

  qmd_content <- readr::read_file(fs::path(tmp, "analysis.qmd"))

  expect_true(grepl('title: "Your Document Title"', qmd_content, fixed = TRUE))
  expect_true(grepl("abstract: |", qmd_content, fixed = TRUE))
  expect_true(grepl('  - "add"', qmd_content, fixed = TRUE))
})

test_that("YAML comments in the template survive scaffolding", {
  tmp <- withr::local_tempdir()

  create_qmd(path = tmp, filename = "analysis.qmd", include_examples = FALSE)

  qmd_content <- readr::read_file(fs::path(tmp, "analysis.qmd"))
  expect_true(grepl("# Keeps CSS, JS and images", qmd_content, fixed = TRUE))
})

test_that("the generated document's YAML header still parses", {
  tmp <- withr::local_tempdir()
  make_style_dir(tmp)

  create_qmd(
    path = tmp, filename = "analysis.qmd",
    include_examples = TRUE, use_style = TRUE, use_purl = TRUE
  )

  qmd_content <- readr::read_file(fs::path(tmp, "analysis.qmd"))
  header <- .split_yaml_header(qmd_content)$header
  parsed <- yaml::yaml.load(paste(header, collapse = "\n"))

  expect_true(parsed[["purl"]])
  expect_equal(parsed[["title"]], "Your Document Title")
  expect_equal(parsed[["format"]][["html"]][["css"]], "assets/styles.css")
  expect_true(parsed[["format"]][["html"]][["embed-resources"]])
})

# -- T17 reverted: the skeleton stays bare -------------------------------------
# The params stamp was removed in favour of resolve_input_path(), which
# handles an undeclared params: block wherever it occurs, including in
# documents that never went through create_qmd(). Stamping a key that
# nothing in a bare skeleton reads was scaffolding for its own sake.

test_that("use_purl = TRUE does not add params to a bare skeleton", {
  tmp <- withr::local_tempdir()

  create_qmd(
    path = tmp, filename = "analysis.qmd",
    include_examples = FALSE, use_purl = TRUE
  )

  qmd_content <- readr::read_file(fs::path(tmp, "analysis.qmd"))
  expect_false(grepl("params", qmd_content, fixed = TRUE))
  expect_true(grepl("purl: true", qmd_content, fixed = TRUE))
})

test_that("use_purl = TRUE leaves the example template's params block alone", {
  tmp <- withr::local_tempdir()

  create_qmd(
    path = tmp, filename = "analysis.qmd",
    include_examples = TRUE, use_purl = TRUE
  )

  header <- .split_yaml_header(
    readr::read_file(fs::path(tmp, "analysis.qmd"))
  )$header
  parsed <- yaml::yaml.load(paste(header, collapse = "\n"))

  expect_equal(parsed[["params"]][["input_file"]], "data-raw/sample.csv")
})

# -- T27: rendered documents travel without a _files/ sidecar ------------------

test_that("the skeleton template sets embed-resources: true", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd", include_examples = FALSE)

  qmd_content <- readr::read_file(fs::path(tmp, "analysis.qmd"))
  expect_true(grepl("embed-resources: true", qmd_content, fixed = TRUE))
  expect_false(grepl("embed-resources: false", qmd_content, fixed = TRUE))
})

test_that("the example template sets embed-resources: true", {
  tmp <- withr::local_tempdir()
  create_qmd(path = tmp, filename = "analysis.qmd", include_examples = TRUE)

  qmd_content <- readr::read_file(fs::path(tmp, "analysis.qmd"))
  expect_true(grepl("embed-resources: true", qmd_content, fixed = TRUE))
  expect_false(grepl("embed-resources: false", qmd_content, fixed = TRUE))
})

# -- Logical values supplied through header_defaults ----------------------------
# The older .substitute_yaml() test covering this passes trivially now that
# untouched keys are never reserialized, so this exercises the handler on a
# value the user actually supplies.

test_that("a logical supplied through header_defaults is written as true, not yes", {
  tmp <- withr::local_tempdir()
  yaml_file <- withr::local_tempfile(fileext = ".yml")
  readr::write_file("draft: true\n", yaml_file)

  create_qmd(
    path = tmp, filename = "analysis.qmd",
    include_examples = FALSE, header_defaults = yaml_file
  )

  qmd_content <- readr::read_file(fs::path(tmp, "analysis.qmd"))
  expect_true(grepl("draft: true", qmd_content, fixed = TRUE))
  expect_false(grepl("draft: yes", qmd_content, fixed = TRUE))
})

# -- T-G6: deep merge of mappings vs. wholesale replacement of sequences --------
# .substitute_yaml() used to build one .set_yaml_key() entry per TOP-LEVEL
# user-YAML key, so a nested mapping like format: html: ... was replaced as a
# single block -- silently discarding any sibling key (css from use_style,
# say) the header_defaults file didn't mention. These tests cover the fix:
# a mapping is now flattened and merged key by key; a sequence (author:,
# categories:) is still replaced as a whole, since merging a list element by
# element against the template's own list isn't a meaningful operation.

test_that("substitute_yaml() merges a nested mapping, preserving a sibling key not mentioned", {
  template <- paste0(
    "---\n",
    "format:\n",
    "  html:\n",
    "    toc: true\n",
    "    css: assets/styles.css\n",
    "---\n\n",
    "Body."
  )
  user_yaml <- list(format = list(html = list(toc = FALSE)))

  result <- .substitute_yaml(template, user_yaml)

  expect_true(grepl("toc: false", result, fixed = TRUE))
  expect_true(grepl("css: assets/styles.css", result, fixed = TRUE))
})

test_that("substitute_yaml() descends more than one level of nested mappings", {
  template <- paste0(
    "---\n",
    "format:\n",
    "  html:\n",
    "    toc: true\n",
    "    number-sections: true\n",
    "---\n\n",
    "Body."
  )
  user_yaml <- list(format = list(html = list(`number-sections` = FALSE)))

  result <- .substitute_yaml(template, user_yaml)

  expect_true(grepl("number-sections: false", result, fixed = TRUE))
  expect_true(grepl("toc: true", result, fixed = TRUE))
})

test_that("substitute_yaml() replaces a sequence wholesale rather than merging element by element", {
  template <- paste0(
    "---\n",
    "categories:\n",
    "  - alpha\n",
    "  - beta\n",
    "---\n\n",
    "Body."
  )
  user_yaml <- list(categories = list("gamma"))

  result <- .substitute_yaml(template, user_yaml)

  expect_true(grepl("gamma", result, fixed = TRUE))
  expect_false(grepl("alpha", result, fixed = TRUE))
  expect_false(grepl("beta", result, fixed = TRUE))
})

test_that(".is_yaml_mapping() distinguishes a named mapping from a sequence", {
  expect_true(.is_yaml_mapping(list(a = 1, b = 2)))
  expect_false(.is_yaml_mapping(list(1, 2)))
  expect_false(.is_yaml_mapping(list()))
  expect_false(.is_yaml_mapping("not a list"))
})

test_that(".flatten_yaml_keys() produces one leaf entry per mapping key", {
  entries <- .flatten_yaml_keys(list(format = list(html = list(toc = TRUE))))

  expect_length(entries, 1L)
  expect_equal(entries[[1L]]$path, c("format", "html", "toc"))
  expect_true(entries[[1L]]$value)
})

test_that(".flatten_yaml_keys() treats a sequence as a single leaf value, not a mapping to descend into", {
  entries <- .flatten_yaml_keys(list(categories = list("a", "b")))

  expect_length(entries, 1L)
  expect_equal(entries[[1L]]$path, "categories")
  expect_equal(entries[[1L]]$value, list("a", "b"))
})

test_that("create_qmd() preserves use_style's other keys when header_defaults sets a sibling format key", {
  tmp <- withr::local_tempdir()
  make_style_dir(tmp)

  yaml_file <- withr::local_tempfile(fileext = ".yml")
  readr::write_file("format:\n  html:\n    toc: false\n", yaml_file)

  create_qmd(
    path = tmp, filename = "analysis.qmd",
    include_examples = FALSE, use_style = TRUE, header_defaults = yaml_file
  )

  qmd_content <- readr::read_file(fs::path(tmp, "analysis.qmd"))
  expect_true(grepl("styles.css", qmd_content, fixed = TRUE))
  expect_true(grepl("toc: false", qmd_content, fixed = TRUE))
})

# -- T-I3: assets/logo.png follows the project's declared folders ---------------
# create_qmd(include_examples = TRUE) used to always copy the placeholder
# logo into assets/, even for a project scaffolded with
# init_project(branding = "none"), which declares no assets/ folder at all.

make_project_manifest <- function(path, folders) {
  yaml::write_yaml(
    list(
      schema_version = 1L,
      folders        = as.list(folders),
      conventions    = list(output_dir = "output", script_dir = "R", split_dir = "data/jobs")
    ),
    fs::path(path, "_toolero.yml")
  )
}

test_that("skips assets/logo.png when the project's _toolero.yml does not declare assets", {
  tmp <- withr::local_tempdir()
  make_project_manifest(tmp, folders = c("data-raw", "data", "R"))

  suppressMessages(
    create_qmd(path = tmp, filename = "analysis.qmd", include_examples = TRUE)
  )

  expect_false(fs::file_exists(fs::path(tmp, "assets", "logo.png")))
})

test_that("skipping the logo does not create an empty assets/ directory", {
  tmp <- withr::local_tempdir()
  make_project_manifest(tmp, folders = c("data-raw", "data"))

  suppressMessages(
    create_qmd(path = tmp, filename = "analysis.qmd", include_examples = TRUE)
  )

  expect_false(fs::dir_exists(fs::path(tmp, "assets")))
})

test_that("still copies data-raw/sample.csv when assets are declared off", {
  tmp <- withr::local_tempdir()
  make_project_manifest(tmp, folders = c("data-raw", "data", "R"))

  suppressMessages(
    create_qmd(path = tmp, filename = "analysis.qmd", include_examples = TRUE)
  )

  expect_true(fs::file_exists(fs::path(tmp, "data-raw", "sample.csv")))
})

test_that("writes assets/logo.png when the project's _toolero.yml declares assets", {
  tmp <- withr::local_tempdir()
  make_project_manifest(tmp, folders = c("data-raw", "data", "R", "assets"))

  create_qmd(path = tmp, filename = "analysis.qmd", include_examples = TRUE)

  expect_true(fs::file_exists(fs::path(tmp, "assets", "logo.png")))
})

test_that("writes assets/logo.png when there is no _toolero.yml at all", {
  tmp <- withr::local_tempdir()

  create_qmd(path = tmp, filename = "analysis.qmd", include_examples = TRUE)

  expect_true(fs::file_exists(fs::path(tmp, "assets", "logo.png")))
})

test_that("a _toolero.yml with no folders key at all is treated like no manifest", {
  tmp <- withr::local_tempdir()
  yaml::write_yaml(list(schema_version = 1L), fs::path(tmp, "_toolero.yml"))

  create_qmd(path = tmp, filename = "analysis.qmd", include_examples = TRUE)

  expect_true(fs::file_exists(fs::path(tmp, "assets", "logo.png")))
})

test_that("reports why the logo was skipped", {
  tmp <- withr::local_tempdir()
  make_project_manifest(tmp, folders = c("data-raw", "data"))

  expect_message(
    create_qmd(path = tmp, filename = "analysis.qmd", include_examples = TRUE),
    "does not declare"
  )
})
