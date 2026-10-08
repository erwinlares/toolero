# tests/testthat/test-project-root-readers.R
#
# T43: every function that reads reads a relative path from the project
# root, wherever the code runs. Each test works from reports/, one level
# below the root. A relative path that exists only relative to the working
# directory still works, once, with a message: that is the migration
# fallback for documents written before the rule. Absolute paths pass
# through; they are covered in each function's own test file.

write_project_yml_file <- function(path, ...) {
    yaml::write_yaml(
        list(
            schema_version = 1L,
            folders        = list("data"),
            conventions    = list(...)
        ),
        path
    )
    path
}

# -- read_clean_csv() -----------------------------------------------------------

test_that("read_clean_csv() reads a relative path from the project root", {
    root <- local_project(subdirs = c("reports", "data-raw"))
    readr::write_file("a,b\n1,2\n", fs::path(root, "data-raw", "sample.csv"))
    withr::local_dir(fs::path(root, "reports"))

    expect_no_message(out <- read_clean_csv("data-raw/sample.csv"))
    expect_equal(nrow(out), 1L)
})

test_that("read_clean_csv() falls back to the working directory and says so", {
    root <- local_project()
    readr::write_file("a,b\n1,2\n", fs::path(root, "reports", "local.csv"))
    withr::local_dir(fs::path(root, "reports"))

    expect_message(out <- read_clean_csv("local.csv"), "working directory")
    expect_equal(nrow(out), 1L)
})

test_that("read_clean_csv() names the root path when the file is nowhere", {
    root <- local_project()
    withr::local_dir(fs::path(root, "reports"))

    expect_error(
        read_clean_csv("data-raw/none.csv"),
        "does not exist"
    )
})

# -- run_by_group() and the write_by_group() manifest ---------------------------

count_rows <- function(df) tibble::tibble(n = nrow(df))

test_that("run_by_group() reads a root-relative manifest written by write_by_group()", {
    root <- local_project()
    withr::local_dir(fs::path(root, "reports"))
    data <- tibble::tibble(g = c("a", "b"), v = 1:2)

    suppressMessages(
        write_by_group(data, "g", output_dir = "data/jobs", manifest = TRUE)
    )
    out <- suppressMessages(
        run_by_group(manifest = "data/jobs/manifest.csv", .f = count_rows)
    )

    expect_equal(nrow(out), 2L)
    expect_equal(out$n, c(1L, 1L))
})

test_that("run_by_group() reads relative file_path entries of a manifest data frame from the root", {
    root <- local_project(subdirs = c("reports", "data/jobs"))
    readr::write_csv(tibble::tibble(v = 1:3), fs::path(root, "data", "jobs", "a.csv"))
    withr::local_dir(fs::path(root, "reports"))

    manifest <- tibble::tibble(group_value = "a", file_path = "data/jobs/a.csv")
    out <- run_by_group(manifest = manifest, .f = count_rows)

    expect_equal(out$n, 3L)
})

test_that("run_by_group() falls back to the working directory for an older manifest, and says so", {
    root <- local_project(subdirs = c("reports", "reports/old"))
    readr::write_csv(tibble::tibble(v = 1:2), fs::path(root, "reports", "old", "a.csv"))
    withr::local_dir(fs::path(root, "reports"))

    manifest <- tibble::tibble(group_value = "a", file_path = "old/a.csv")

    expect_message(
        out <- run_by_group(manifest = manifest, .f = count_rows),
        "working directory"
    )
    expect_equal(out$n, 2L)
})

# -- generate_manifest(), save_output() and read_output_records() ---------------

test_that("config is read from the project root", {
    root   <- local_project()
    config <- write_project_yml_file(fs::path(root, "_toolero.yml"), output_dir = "results")
    withr::local_dir(fs::path(root, "reports"))

    suppressMessages(
        save_output(mtcars, "results/a.rds", .f = saveRDS, config = "_toolero.yml")
    )
    suppressMessages(generate_manifest(config = "_toolero.yml"))

    expect_true(fs::file_exists(fs::path(root, "results", "project-manifest.json")))
})

test_that("read_output_records() reads a relative folder from the root and labels it as typed", {
    root <- local_project()
    withr::local_dir(fs::path(root, "reports"))

    suppressMessages(save_output(mtcars, "output/a.rds", .f = saveRDS))
    suppressMessages(generate_manifest())

    out <- read_output_records("output")

    expect_equal(nrow(out), 1L)
    expect_equal(out$source, "output")
})

test_that("read_output_records() keeps the names of a named vector as labels", {
    root <- local_project()
    withr::local_dir(fs::path(root, "reports"))

    suppressMessages(save_output(mtcars, "output/a.rds", .f = saveRDS))
    suppressMessages(generate_manifest())

    out <- read_output_records(c(mine = "output"))

    expect_equal(out$source, "mine")
})

test_that("read_output_records() resolves a vector of folders", {
    root <- local_project()
    withr::local_dir(fs::path(root, "reports"))

    suppressMessages(save_output(mtcars, "output/a.rds", .f = saveRDS))
    suppressMessages(generate_manifest())

    out <- read_output_records(c("output", as.character(fs::path(root, "output"))))

    expect_equal(nrow(out), 2L)
    expect_equal(out$source[1L], "output")
})

test_that("generate_manifest() resolves git_root from the project root", {
    root <- local_project()
    withr::local_dir(fs::path(root, "reports"))

    suppressMessages(save_output(mtcars, "output/a.rds", .f = saveRDS))

    seen <- NULL
    local_mocked_bindings(
        .git_commit = function(path = ".") {
            seen <<- path
            NULL
        }
    )
    suppressMessages(generate_manifest())

    expect_equal(as.character(seen), root)
})

# -- qmd_to_r(), generate_kb_xml() ----------------------------------------------

test_that("qmd_to_r() reads a relative input from the project root", {
    skip_if_not_installed("knitr")
    root <- local_project()
    writeLines(c("---", "title: t", "---", "", "```{r}", "1 + 1", "```"),
               fs::path(root, "analysis.qmd"))
    withr::local_dir(fs::path(root, "reports"))

    out <- suppressMessages(qmd_to_r("analysis.qmd"))

    expect_true(fs::file_exists(fs::path(root, "analysis.R")))
    expect_equal(as.character(out), as.character(fs::path(root, "analysis.R")))
})

test_that("generate_kb_xml() finds a relative html_path at the root before it looks for the qmd", {
    root <- local_project()
    writeLines("<html><body>x</body></html>", fs::path(root, "page.html"))
    withr::local_dir(fs::path(root, "reports"))

    # No page.qmd exists, so the call stops there, before any rendering.
    # Reaching that message means html_path was found at the root.
    expect_error(generate_kb_xml("page.html"), "page.qmd")
})

# -- check_project() ------------------------------------------------------------

test_that("check_project() audits the project root when called from a subfolder", {
    root <- local_project()
    suppressMessages(generate_project_config("_toolero.yml", path = root))
    withr::local_dir(fs::path(root, "reports"))

    out <- suppressMessages(check_project())

    expect_equal(out$status[out$check == "_toolero.yml"], "pass")
})

# -- create_qmd() and generate_citation() ---------------------------------------

test_that("create_qmd() reads a relative header_defaults from the project root", {
    root <- local_project()
    yaml::write_yaml(list(title = "From Profile"), fs::path(root, "defaults.yml"))
    withr::local_dir(fs::path(root, "reports"))

    expect_no_error(
        suppressMessages(
            create_qmd("analysis.qmd", header_defaults = "defaults.yml",
                       include_examples = FALSE)
        )
    )
    expect_true(fs::file_exists(fs::path(root, "analysis.qmd")))
})

test_that("generate_citation() reads a relative profile from the project root", {
    root <- local_project()
    yaml::write_yaml(
        list(author = list(list(
            name = "Jane Researcher",
            affiliation = "A University",
            orcid = "0000-0000-0000-0000"
        ))),
        fs::path(root, "me.yml")
    )
    withr::local_dir(fs::path(root, "reports"))

    suppressMessages(generate_citation(profile = "me.yml"))

    content <- paste(readLines(fs::path(root, "CITATION.cff")), collapse = "\n")
    expect_true(grepl("Researcher", content, fixed = TRUE))
})
