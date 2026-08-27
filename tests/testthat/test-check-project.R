# tests/testthat/test-check-project.R

# -- helpers -------------------------------------------------------------------

make_project <- function(root,
                         folders  = c("data-raw", "data", "scripts",
                                      "output/figures", "output/tables",
                                      "reports"),
                         rproj    = TRUE,
                         gitignore = TRUE) {
    project <- fs::path(root, "my-project")
    fs::dir_create(project)

    if (isTRUE(rproj)) {
        writeLines("", fs::path(project, "my-project.Rproj"))
    }
    if (isTRUE(gitignore)) {
        writeLines("", fs::path(project, ".gitignore"))
    }
    for (folder in folders) {
        fs::dir_create(fs::path(project, folder))
    }

    project
}

make_config <- function(root, folders, filename = "profile.yml") {
    config_path <- fs::path(root, filename)
    yaml::write_yaml(list(folders = as.list(folders)), config_path)
    config_path
}

# -- path validation -----------------------------------------------------------

test_that("check_project() errors on a non-existent path", {
    expect_error(
        check_project(path = "nonexistent_path_xyz"),
        info = "should error when path does not exist"
    )
})

# -- return value --------------------------------------------------------------

test_that("check_project() returns a tibble with the expected columns", {
    root    <- withr::local_tempdir()
    project <- make_project(root)

    result <- check_project(path = project)

    expect_s3_class(result, "tbl_df")
    expect_named(result, c("check", "status", "message"))
})

test_that("check_project() returns character columns only", {
    root    <- withr::local_tempdir()
    project <- make_project(root)

    result <- check_project(path = project)

    expect_type(result$check, "character")
    expect_type(result$status, "character")
    expect_type(result$message, "character")
})

test_that("check_project() emits only recognized status values", {
    root    <- withr::local_tempdir()
    project <- make_project(root)

    result <- check_project(path = project)

    expect_true(all(result$status %in% c("pass", "warn", "fail", "info")))
})

test_that("check_project() returns invisibly", {
    root    <- withr::local_tempdir()
    project <- make_project(root)

    expect_invisible(check_project(path = project))
})

test_that("check_project() returns invisibly even when error = FALSE", {
    root    <- withr::local_tempdir()
    project <- make_project(root)

    expect_invisible(
        suppressWarnings(check_project(path = project, error = FALSE))
    )
})

# -- deprecation of the error argument -----------------------------------------

test_that("check_project() warns when error = FALSE is supplied", {
    root    <- withr::local_tempdir()
    project <- make_project(root)

    expect_warning(
        check_project(path = project, error = FALSE),
        class = "lifecycle_warning_deprecated"
    )
})

test_that("check_project() does not warn when error is left at its default", {
    root    <- withr::local_tempdir()
    project <- make_project(root)

    expect_no_warning(check_project(path = project))
})

test_that("check_project() does not warn when error = TRUE is supplied", {
    root    <- withr::local_tempdir()
    project <- make_project(root)

    expect_no_warning(check_project(path = project, error = TRUE))
})

test_that("check_project() returns the same results regardless of error", {
    root    <- withr::local_tempdir()
    project <- make_project(root)

    with_default    <- check_project(path = project)
    with_deprecated <- suppressWarnings(
        check_project(path = project, error = FALSE)
    )

    expect_equal(with_default, with_deprecated)
})

# -- standard folder checks ----------------------------------------------------

test_that("check_project() passes every folder in the standard set", {
    root    <- withr::local_tempdir()
    project <- make_project(root)

    result <- check_project(path = project)

    standard <- c("data-raw/", "data/", "scripts/",
                  "output/figures/", "output/tables/", "reports/")

    for (folder in standard) {
        expect_equal(
            result$status[result$check == folder],
            "pass",
            info = folder
        )
    }
})

test_that("check_project() warns on a missing standard folder", {
    root    <- withr::local_tempdir()
    project <- make_project(root, folders = c("data-raw", "data"))

    result <- check_project(path = project)

    expect_equal(result$status[result$check == "scripts/"], "warn")
    expect_equal(result$status[result$check == "reports/"], "warn")
})

test_that("check_project() checks nested standard folders independently", {
    root    <- withr::local_tempdir()
    project <- make_project(root, folders = "output/figures")

    result <- check_project(path = project)

    expect_equal(result$status[result$check == "output/figures/"], "pass")
    expect_equal(result$status[result$check == "output/tables/"], "warn")
})

# -- config-driven folder checks -----------------------------------------------

test_that("check_project() passes folders declared in a config", {
    root    <- withr::local_tempdir()
    project <- make_project(root, folders = c("models", "corpora"))
    config  <- make_config(root, c("models", "corpora"))

    result <- check_project(path = project, config = config)

    expect_equal(result$status[result$check == "models/"], "pass")
    expect_equal(result$status[result$check == "corpora/"], "pass")
})

test_that("check_project() fails rather than warns on a missing config folder", {
    root    <- withr::local_tempdir()
    project <- make_project(root, folders = character(0))
    config  <- make_config(root, "models")

    result <- check_project(path = project, config = config)

    expect_equal(result$status[result$check == "models/"], "fail")
})

test_that("check_project() replaces the standard folder set entirely", {
    root    <- withr::local_tempdir()
    project <- make_project(root)
    config  <- make_config(root, "models")

    result <- check_project(path = project, config = config)

    expect_true("models/" %in% result$check)
    expect_false("data-raw/" %in% result$check)
    expect_false("reports/" %in% result$check)
})

test_that("check_project() handles nested folders from a config", {
    root    <- withr::local_tempdir()
    project <- make_project(root, folders = "corpora/raw")
    config  <- make_config(root, c("corpora/raw", "corpora/tagged"))

    result <- check_project(path = project, config = config)

    expect_equal(result$status[result$check == "corpora/raw/"], "pass")
    expect_equal(result$status[result$check == "corpora/tagged/"], "fail")
})

test_that("check_project() deduplicates repeated folders in a config", {
    root    <- withr::local_tempdir()
    project <- make_project(root, folders = "models")
    config  <- make_config(root, c("models", "models"))

    result <- suppressMessages(check_project(path = project, config = config))

    expect_equal(sum(result$check == "models/"), 1L)
})

test_that("check_project() informs when a config contains duplicates", {
    root    <- withr::local_tempdir()
    project <- make_project(root, folders = "models")
    config  <- make_config(root, c("models", "models"))

    expect_message(check_project(path = project, config = config))
})

# -- config validation ---------------------------------------------------------

test_that("check_project() errors when the config file does not exist", {
    root    <- withr::local_tempdir()
    project <- make_project(root)

    expect_error(
        check_project(path = project, config = fs::path(root, "missing.yml")),
        info = "should error when the config path does not resolve"
    )
})

test_that("check_project() errors when config is not a single string", {
    root    <- withr::local_tempdir()
    project <- make_project(root)

    expect_error(
        check_project(path = project, config = c("a.yml", "b.yml")),
        info = "should error on a config vector of length > 1"
    )
})

test_that("check_project() errors when the config has no folders entry", {
    root        <- withr::local_tempdir()
    project     <- make_project(root)
    config_path <- fs::path(root, "empty.yml")
    yaml::write_yaml(list(other_key = "value"), config_path)

    expect_error(
        check_project(path = project, config = config_path),
        info = "should error when folders: is absent"
    )
})

test_that("check_project() errors when the folders entry is nested", {
    root        <- withr::local_tempdir()
    project     <- make_project(root)
    config_path <- fs::path(root, "nested.yml")
    yaml::write_yaml(
        list(folders = list(list(name = "models", description = "trained models"))),
        config_path
    )

    expect_error(
        check_project(path = project, config = config_path),
        info = "should error on a non-flat folders list"
    )
})

test_that("check_project() errors when the folders entry contains a blank", {
    root        <- withr::local_tempdir()
    project     <- make_project(root)
    config_path <- fs::path(root, "blank.yml")
    yaml::write_yaml(list(folders = list("models", "")), config_path)

    expect_error(
        check_project(path = project, config = config_path),
        info = "should error on an empty folder name"
    )
})

# -- hygiene checks run regardless of config -----------------------------------

test_that("check_project() runs hygiene checks whether or not a config is used", {
    root    <- withr::local_tempdir()
    project <- make_project(root)
    config  <- make_config(root, "models")

    without_config <- check_project(path = project)
    with_config    <- check_project(path = project, config = config)

    hygiene <- c(".Rproj file", "renv.lock", "git repository",
                 ".gitignore", "README")

    for (check in hygiene) {
        expect_true(check %in% without_config$check, info = check)
        expect_true(check %in% with_config$check, info = check)
        expect_equal(
            without_config$status[without_config$check == check],
            with_config$status[with_config$check == check],
            info = check
        )
    }
})

# -- cli markup injection ------------------------------------------------------

test_that("check_project() survives a config folder containing braces", {
    root    <- withr::local_tempdir()
    project <- make_project(root, folders = character(0))
    config  <- make_config(root, "output/{draft}")

    expect_error(
        check_project(path = project, config = config),
        NA,
        info = "braces in a folder name must not be evaluated as cli markup"
    )
})

test_that("check_project() survives a README filename containing braces", {
    root    <- withr::local_tempdir()
    project <- make_project(root)
    writeLines("", fs::path(project, "readme.{md}"))

    expect_error(
        check_project(path = project),
        NA,
        info = "braces in a filename must not be evaluated as cli markup"
    )
})

# -- .Rproj check --------------------------------------------------------------

test_that("check_project() passes the .Rproj check when the file exists", {
    root    <- withr::local_tempdir()
    project <- make_project(root)

    result <- check_project(path = project)

    expect_equal(result$status[result$check == ".Rproj file"], "pass")
})

test_that("check_project() fails the .Rproj check when the file is absent", {
    root    <- withr::local_tempdir()
    project <- make_project(root, rproj = FALSE)

    result <- check_project(path = project)

    expect_equal(result$status[result$check == ".Rproj file"], "fail")
})

test_that("check_project() ignores a directory named like an .Rproj file", {
    root    <- withr::local_tempdir()
    project <- make_project(root, rproj = FALSE)
    fs::dir_create(fs::path(project, "decoy.Rproj"))

    result <- check_project(path = project)

    expect_equal(result$status[result$check == ".Rproj file"], "fail")
})

# -- renv, git, gitignore ------------------------------------------------------

test_that("check_project() fails the renv.lock check when absent", {
    root    <- withr::local_tempdir()
    project <- make_project(root)

    result <- check_project(path = project)

    expect_equal(result$status[result$check == "renv.lock"], "fail")
})

test_that("check_project() passes the renv.lock check when present", {
    root    <- withr::local_tempdir()
    project <- make_project(root)
    writeLines("", fs::path(project, "renv.lock"))

    result <- check_project(path = project)

    expect_equal(result$status[result$check == "renv.lock"], "pass")
})

test_that("check_project() fails the git check when .git is absent", {
    root    <- withr::local_tempdir()
    project <- make_project(root)

    result <- check_project(path = project)

    expect_equal(result$status[result$check == "git repository"], "fail")
})

test_that("check_project() passes the git check when .git is present", {
    root    <- withr::local_tempdir()
    project <- make_project(root)
    fs::dir_create(fs::path(project, ".git"))

    result <- check_project(path = project)

    expect_equal(result$status[result$check == "git repository"], "pass")
})

test_that("check_project() passes the .gitignore check when present", {
    root    <- withr::local_tempdir()
    project <- make_project(root)

    result <- check_project(path = project)

    expect_equal(result$status[result$check == ".gitignore"], "pass")
})

test_that("check_project() warns when .gitignore is absent", {
    root    <- withr::local_tempdir()
    project <- make_project(root, gitignore = FALSE)

    result <- check_project(path = project)

    expect_equal(result$status[result$check == ".gitignore"], "warn")
})

# -- README detection ----------------------------------------------------------

test_that("check_project() warns when no README is present", {
    root    <- withr::local_tempdir()
    project <- make_project(root)

    result <- check_project(path = project)

    expect_equal(result$status[result$check == "README"], "warn")
})

test_that("check_project() detects README across casing and extensions", {
    variants <- c(
        "README.md", "readme.md", "Readme.md", "ReadMe.MD",
        "README", "readme", "ReadMe",
        "README.Rmd", "readme.rmd", "README.qmd",
        "README.txt", "README.pdf", "readme.docx", "README.tex", "readme.org"
    )

    for (variant in variants) {
        root    <- withr::local_tempdir()
        project <- make_project(root)
        writeLines("", fs::path(project, variant))

        result <- check_project(path = project)

        expect_equal(
            result$status[result$check == "README"],
            "pass",
            info = variant
        )
    }
})

test_that("check_project() does not treat a readme directory as a README", {
    root    <- withr::local_tempdir()
    project <- make_project(root)
    fs::dir_create(fs::path(project, "readme"))

    result <- check_project(path = project)

    expect_equal(result$status[result$check == "README"], "warn")
})

test_that("check_project() does not match a file merely starting with readme", {
    root    <- withr::local_tempdir()
    project <- make_project(root)
    writeLines("", fs::path(project, "readme-old.md"))

    result <- check_project(path = project)

    expect_equal(result$status[result$check == "README"], "warn")
})

test_that("check_project() does not match a double-extension readme", {
    root    <- withr::local_tempdir()
    project <- make_project(root)
    writeLines("", fs::path(project, "readme.tar.gz"))

    result <- check_project(path = project)

    expect_equal(
        result$status[result$check == "README"],
        "warn",
        info = "documented limitation: only a single extension is matched"
    )
})

# -- hidden file checks --------------------------------------------------------

test_that("check_project() reports .RData when present", {
    root    <- withr::local_tempdir()
    project <- make_project(root)
    writeLines("", fs::path(project, ".RData"))

    result <- check_project(path = project)

    expect_true(".RData" %in% result$check)
    expect_equal(result$status[result$check == ".RData"], "warn")
})

test_that("check_project() omits .RData when absent", {
    root    <- withr::local_tempdir()
    project <- make_project(root)

    result <- check_project(path = project)

    expect_false(".RData" %in% result$check)
})

test_that("check_project() reports .Rhistory when present", {
    root    <- withr::local_tempdir()
    project <- make_project(root)
    writeLines("", fs::path(project, ".Rhistory"))

    result <- check_project(path = project)

    expect_true(".Rhistory" %in% result$check)
    expect_equal(result$status[result$check == ".Rhistory"], "warn")
})

test_that("check_project() omits .Rhistory when absent", {
    root    <- withr::local_tempdir()
    project <- make_project(root)

    result <- check_project(path = project)

    expect_false(".Rhistory" %in% result$check)
})

test_that("check_project() reports .Rprofile when present", {
    root    <- withr::local_tempdir()
    project <- make_project(root)
    writeLines("", fs::path(project, ".Rprofile"))

    result <- check_project(path = project)

    expect_true(".Rprofile" %in% result$check)
    expect_equal(result$status[result$check == ".Rprofile"], "info")
})

test_that("check_project() reports .Renviron when present", {
    root    <- withr::local_tempdir()
    project <- make_project(root)
    writeLines("", fs::path(project, ".Renviron"))

    result <- check_project(path = project)

    expect_true(".Renviron" %in% result$check)
    expect_equal(result$status[result$check == ".Renviron"], "info")
})

# -- internal helpers ----------------------------------------------------------

test_that(".standard_folder_message() returns tailored text for known folders", {
    msg <- .standard_folder_message("data-raw")

    expect_type(msg, "character")
    expect_length(msg, 1L)
    expect_true(grepl("data-raw", msg, fixed = TRUE))
})

test_that(".standard_folder_message() falls back for unknown folders", {
    expect_error(.standard_folder_message("not-a-standard-folder"), NA)

    msg <- .standard_folder_message("not-a-standard-folder")

    expect_type(msg, "character")
    expect_length(msg, 1L)
    expect_true(grepl("not-a-standard-folder", msg, fixed = TRUE))
})

test_that(".cli_escape() doubles braces", {
    expect_equal(.cli_escape("output/{draft}"), "output/{{draft}}")
    expect_equal(.cli_escape("no braces here"), "no braces here")
})
