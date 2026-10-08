# tests/testthat/test-project-root-writers.R
#
# T42: every function that writes reads a relative path from the project
# root, wherever the code runs. Each test works from reports/, one level
# below the root, so a path read from the working directory would land in
# the wrong place and the test would say so. Absolute paths are covered in
# each function's own test file; they pass through untouched.

# -- write_clean_csv() ----------------------------------------------------------

test_that("write_clean_csv() writes a relative path under the project root", {
    root <- local_project(subdirs = c("reports", "data"))
    withr::local_dir(fs::path(root, "reports"))

    suppressMessages(write_clean_csv(data.frame(a = 1), "data/out.csv"))

    expect_true(fs::file_exists(fs::path(root, "data", "out.csv")))
    expect_false(fs::file_exists(fs::path(root, "reports", "data", "out.csv")))
})

test_that("write_clean_csv() returns the resolved path", {
    root <- local_project(subdirs = c("reports", "data"))
    withr::local_dir(fs::path(root, "reports"))

    out <- suppressMessages(write_clean_csv(data.frame(a = 1), "data/out.csv"))

    expect_equal(as.character(out), as.character(fs::path(root, "data", "out.csv")))
})

test_that("write_clean_csv() names the resolved path when the file exists", {
    root <- local_project(subdirs = c("reports", "data"))
    fs::file_create(fs::path(root, "data", "out.csv"))
    withr::local_dir(fs::path(root, "reports"))

    expect_error(
        write_clean_csv(data.frame(a = 1), "data/out.csv"),
        "already exists"
    )
})

# -- write_by_group() -----------------------------------------------------------

test_that("write_by_group() writes a relative output_dir under the project root", {
    root <- local_project()
    withr::local_dir(fs::path(root, "reports"))
    data <- tibble::tibble(g = c("a", "b"), v = 1:2)

    suppressMessages(write_by_group(data, "g", output_dir = "data/jobs"))

    expect_true(fs::file_exists(fs::path(root, "data", "jobs", "a.csv")))
    expect_false(fs::dir_exists(fs::path(root, "reports", "data")))
})

test_that("write_by_group() records manifest paths relative to the project root", {
    root <- local_project()
    withr::local_dir(fs::path(root, "reports"))
    data <- tibble::tibble(g = c("a", "b"), v = 1:2)

    suppressMessages(
        write_by_group(data, "g", output_dir = "data/jobs", manifest = TRUE)
    )

    manifest <- readr::read_csv(
        fs::path(root, "data", "jobs", "manifest.csv"),
        show_col_types = FALSE
    )
    expect_equal(sort(manifest$file_path), c("data/jobs/a.csv", "data/jobs/b.csv"))
})

test_that("write_by_group() records an absolute manifest path for a folder outside the project", {
    root    <- local_project()
    outside <- withr::local_tempdir()
    data    <- tibble::tibble(g = c("a", "b"), v = 1:2)

    suppressMessages(
        write_by_group(data, "g", output_dir = outside, manifest = TRUE)
    )

    manifest <- readr::read_csv(fs::path(outside, "manifest.csv"), show_col_types = FALSE)
    expect_true(all(fs::is_absolute_path(manifest$file_path)))
})

test_that("write_by_group() reads a relative split_dir convention from the config's folder", {
    root   <- local_project()
    config <- fs::path(root, "_toolero.yml")
    yaml::write_yaml(
        list(
            schema_version = 1L,
            folders        = list("data"),
            conventions    = list(split_dir = "data/jobs")
        ),
        config
    )
    withr::local_dir(fs::path(root, "reports"))
    data <- tibble::tibble(g = c("a", "b"), v = 1:2)

    suppressMessages(write_by_group(data, "g", config = config))

    expect_true(fs::file_exists(fs::path(root, "data", "jobs", "a.csv")))
    expect_false(fs::dir_exists(fs::path(root, "reports", "data")))
})

# -- qmd_to_r() -----------------------------------------------------------------

make_qmd <- function(path) {
    fs::dir_create(fs::path_dir(path))
    writeLines(c("---", "title: t", "---", "", "```{r}", "1 + 1", "```"), path)
    path
}

test_that("qmd_to_r() writes an explicit relative output under the project root", {
    skip_if_not_installed("knitr")
    root <- local_project()
    input <- make_qmd(as.character(fs::path(root, "analysis.qmd")))
    withr::local_dir(fs::path(root, "reports"))

    suppressMessages(qmd_to_r(input, output = "R/analysis.R"))

    expect_true(fs::file_exists(fs::path(root, "R", "analysis.R")))
    expect_false(fs::dir_exists(fs::path(root, "reports", "R")))
})

test_that("qmd_to_r() still writes the default output beside the input", {
    skip_if_not_installed("knitr")
    root  <- local_project()
    input <- make_qmd(as.character(fs::path(root, "reports", "analysis.qmd")))

    suppressMessages(qmd_to_r(input))

    expect_true(fs::file_exists(fs::path(root, "reports", "analysis.R")))
})

# -- arborize() -----------------------------------------------------------------
# Rendering needs Quarto and Typst, so these tests stop at the existing-file
# check, which runs before any rendering and names the resolved path.

test_that("arborize() resolves a relative output from the project root", {
    root <- local_project(subdirs = c("reports", "figures"))
    fs::file_create(fs::path(root, "figures", "tree.png"))
    withr::local_dir(fs::path(root, "reports"))

    expect_error(
        arborize("[NP [Det the] [N cat]]", output = "figures/tree.png"),
        "already exists"
    )
})

# -- generators with a target directory -----------------------------------------

test_that("generate_license() writes LICENSE at the root when called from a subfolder", {
    root <- local_project()
    withr::local_dir(fs::path(root, "reports"))

    suppressMessages(generate_license(holder = "Jane Researcher"))

    expect_true(fs::file_exists(fs::path(root, "LICENSE")))
    expect_false(fs::file_exists(fs::path(root, "reports", "LICENSE")))
})

test_that("generate_citation() writes CITATION.cff at the root when called from a subfolder", {
    root <- local_project()
    withr::local_dir(fs::path(root, "reports"))

    suppressMessages(generate_citation())

    expect_true(fs::file_exists(fs::path(root, "CITATION.cff")))
    expect_false(fs::file_exists(fs::path(root, "reports", "CITATION.cff")))
})

test_that("generate_project_config() writes at the root when called from a subfolder", {
    root <- local_project()
    withr::local_dir(fs::path(root, "reports"))

    suppressMessages(generate_project_config("my-project.yml"))

    expect_true(fs::file_exists(fs::path(root, "my-project.yml")))
    expect_false(fs::file_exists(fs::path(root, "reports", "my-project.yml")))
})

test_that("generate_data_doc() defaults to the root's data/ folder", {
    root <- local_project(subdirs = c("reports", "data"))
    withr::local_dir(fs::path(root, "reports"))

    suppressMessages(generate_data_doc("survey.csv"))

    expect_true(fs::file_exists(fs::path(root, "data", "survey.md")))
    expect_false(fs::file_exists(fs::path(root, "reports", "survey.md")))
})

test_that("generate_profile() reads a relative path from the project root", {
    root <- local_project(subdirs = c("reports", "profiles"))
    withr::local_dir(fs::path(root, "reports"))

    suppressMessages(generate_profile("me.yml", path = "profiles"))

    expect_true(fs::file_exists(fs::path(root, "profiles", "me.yml")))
})

test_that("create_qmd() writes a relative filename under the project root", {
    root <- local_project()
    withr::local_dir(fs::path(root, "reports"))

    suppressMessages(create_qmd("analysis.qmd", include_examples = FALSE))

    expect_true(fs::file_exists(fs::path(root, "analysis.qmd")))
    expect_false(fs::file_exists(fs::path(root, "reports", "analysis.qmd")))
})

test_that("create_qmd() takes a subfolder through path, relative to the root", {
    root <- local_project(subdirs = c("reports", "docs"))
    withr::local_dir(fs::path(root, "reports"))

    suppressMessages(
        create_qmd("analysis.qmd", path = "docs", include_examples = FALSE)
    )

    expect_true(fs::file_exists(fs::path(root, "docs", "analysis.qmd")))
})

test_that("a path argument outside any project falls back to the working directory", {
    dir <- withr::local_tempdir()
    withr::local_dir(dir)

    suppressMessages(generate_license(holder = "Jane Researcher"))

    expect_true(fs::file_exists(fs::path(dir, "LICENSE")))
})
