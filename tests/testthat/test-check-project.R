# -- shared project ------------------------------------------------------------

make_project <- function(root) {
    project <- fs::path(root, "my-project")
    fs::dir_create(project)
    writeLines("", fs::path(project, "my-project.Rproj"))
    writeLines("", fs::path(project, ".gitignore"))
    fs::dir_create(fs::path(project, "data-raw"))
    fs::dir_create(fs::path(project, "data"))
    fs::dir_create(fs::path(project, "docs"))
    fs::dir_create(fs::path(project, "R"))
    fs::dir_create(fs::path(project, "scripts"))
    project
}
root    <- withr::local_tempdir()
project <- make_project(root)

# -- path validation -----------------------------------------------------------

test_that("check_project() errors on non-existent path", {
    expect_error(
        check_project(path = "nonexistent_path_xyz"),
        info = "should error when path does not exist"
    )
})

# -- return value --------------------------------------------------------------

test_that("check_project() returns a tibble", {
    result <- check_project(path = project, error = FALSE)
    expect_s3_class(result, "tbl_df")
})

test_that("check_project() tibble has correct columns", {
    result <- check_project(path = project, error = FALSE)
    expect_named(result, c("check", "status", "message"))
})

test_that("check_project() returns invisibly when error = TRUE", {
    expect_invisible(check_project(path = project, error = TRUE))
})

test_that("check_project() returns visibly when error = FALSE", {
    result <- check_project(path = project, error = FALSE)
    expect_visible(result)
})

# -- pass checks ---------------------------------------------------------------

test_that("check_project() passes .Rproj check", {
    result <- check_project(path = project, error = FALSE)
    expect_equal(result$status[result$check == ".Rproj file"], "pass")
})

test_that("check_project() passes data-raw/ check", {
    result <- check_project(path = project, error = FALSE)
    expect_equal(result$status[result$check == "data-raw/"], "pass")
})

test_that("check_project() passes data/ check", {
    result <- check_project(path = project, error = FALSE)
    expect_equal(result$status[result$check == "data/"], "pass")
})

test_that("check_project() passes docs/ check", {
    result <- check_project(path = project, error = FALSE)
    expect_equal(result$status[result$check == "docs/"], "pass")
})

test_that("check_project() passes code folder check", {
    result <- check_project(path = project, error = FALSE)
    expect_equal(result$status[result$check == "code folder"], "pass")
})

test_that("check_project() passes .gitignore check", {
    result <- check_project(path = project, error = FALSE)
    expect_equal(result$status[result$check == ".gitignore"], "pass")
})

# -- fail checks ---------------------------------------------------------------

test_that("check_project() fails renv.lock check when file is absent", {
    result <- check_project(path = project, error = FALSE)
    expect_equal(result$status[result$check == "renv.lock"], "fail")
})

test_that("check_project() fails git check when .git is absent", {
    result <- check_project(path = project, error = FALSE)
    expect_equal(result$status[result$check == "git repository"], "fail")
})

test_that("check_project() warns when README is missing", {
    result <- check_project(path = project, error = FALSE)
    expect_equal(result$status[result$check == "README"], "warn")
})

# -- mutating checks: adding files ---------------------------------------------

test_that("check_project() passes renv.lock check when file is added", {
    renv_path <- fs::path(project, "renv.lock")
    writeLines("", renv_path)
    withr::defer(fs::file_delete(renv_path))
    result <- check_project(path = project, error = FALSE)
    expect_equal(result$status[result$check == "renv.lock"], "pass")
})

test_that("check_project() passes git check when .git is added", {
    git_path <- fs::path(project, ".git")
    fs::dir_create(git_path)
    withr::defer(fs::dir_delete(git_path))
    result <- check_project(path = project, error = FALSE)
    expect_equal(result$status[result$check == "git repository"], "pass")
})

test_that("check_project() passes README check when README.md is added", {
    readme_path <- fs::path(project, "README.md")
    writeLines("", readme_path)
    withr::defer(fs::file_delete(readme_path))
    result <- check_project(path = project, error = FALSE)
    expect_equal(result$status[result$check == "README"], "pass")
})

test_that("check_project() passes README check when README.qmd is added", {
    readme_path <- fs::path(project, "README.qmd")
    writeLines("", readme_path)
    withr::defer(fs::file_delete(readme_path))
    result <- check_project(path = project, error = FALSE)
    expect_equal(result$status[result$check == "README"], "pass")
})

# -- mutating checks: removing files -------------------------------------------

test_that("check_project() warns when .gitignore is missing", {
    gitignore_path <- fs::path(project, ".gitignore")
    content        <- readLines(gitignore_path)
    fs::file_delete(gitignore_path)
    withr::defer(writeLines(content, gitignore_path))
    result <- check_project(path = project, error = FALSE)
    expect_equal(result$status[result$check == ".gitignore"], "warn")
})

test_that("check_project() warns when code folder is missing", {
    r_path       <- fs::path(project, "R")
    scripts_path <- fs::path(project, "scripts")
    fs::dir_delete(r_path)
    fs::dir_delete(scripts_path)
    withr::defer(fs::dir_create(r_path))
    withr::defer(fs::dir_create(scripts_path))
    result <- check_project(path = project, error = FALSE)
    expect_equal(result$status[result$check == "code folder"], "warn")
})

# -- hidden file checks --------------------------------------------------------

test_that("check_project() reports .RData when present", {
    rdata_path <- fs::path(project, ".RData")
    writeLines("", rdata_path)
    withr::defer(fs::file_delete(rdata_path))
    result <- check_project(path = project, error = FALSE)
    expect_true(".RData" %in% result$check)
    expect_equal(result$status[result$check == ".RData"], "warn")
})

test_that("check_project() does not report .RData when absent", {
    result <- check_project(path = project, error = FALSE)
    expect_false(".RData" %in% result$check)
})

test_that("check_project() reports .Rhistory when present", {
    rhistory_path <- fs::path(project, ".Rhistory")
    writeLines("", rhistory_path)
    withr::defer(fs::file_delete(rhistory_path))
    result <- check_project(path = project, error = FALSE)
    expect_true(".Rhistory" %in% result$check)
    expect_equal(result$status[result$check == ".Rhistory"], "warn")
})

test_that("check_project() does not report .Rhistory when absent", {
    result <- check_project(path = project, error = FALSE)
    expect_false(".Rhistory" %in% result$check)
})

test_that("check_project() reports .Rprofile when present", {
    rprofile_path <- fs::path(project, ".Rprofile")
    writeLines("", rprofile_path)
    withr::defer(fs::file_delete(rprofile_path))
    result <- check_project(path = project, error = FALSE)
    expect_true(".Rprofile" %in% result$check)
    expect_equal(result$status[result$check == ".Rprofile"], "info")
})

test_that("check_project() reports .Renviron when present", {
    renviron_path <- fs::path(project, ".Renviron")
    writeLines("", renviron_path)
    withr::defer(fs::file_delete(renviron_path))
    result <- check_project(path = project, error = FALSE)
    expect_true(".Renviron" %in% result$check)
    expect_equal(result$status[result$check == ".Renviron"], "info")
})

# -- cli output ----------------------------------------------------------------

test_that("check_project() returns invisibly when error = TRUE", {
    expect_invisible(check_project(path = project, error = TRUE))
})
