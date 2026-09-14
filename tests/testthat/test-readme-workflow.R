# tests/testthat/test-readme-workflow.R
#
# The README's first workflow is the first code a new user meets, and it has
# been broken before: it read an input.csv nothing created, called an
# undefined my_analysis, and wrote the derived script somewhere the package
# no longer recommends. This test extracts that block from README.md and
# runs it, so the one block everybody sees is the one block that is
# verified.
#
# It reads the README rather than holding a copy, because a copy is how the
# two drift apart again. That means the test can only run where README.md is
# on disk: under devtools::test() and on CI from a source checkout, but not
# from a built tarball where the README may have been excluded. It skips
# rather than fails in that case, which is the right trade for a
# developer-time guard.


# Helper: pull the first fenced r block out of a named markdown section.
extract_r_block <- function(path, heading) {
    lines <- readLines(path, warn = FALSE)

    start <- which(trimws(lines) == heading)
    if (length(start) == 0L) {
        return(NULL)
    }

    after <- lines[seq.int(start[[1L]] + 1L, length(lines))]
    opens <- which(trimws(after) == "```r")
    if (length(opens) == 0L) {
        return(NULL)
    }

    body  <- after[seq.int(opens[[1L]] + 1L, length(after))]
    close <- which(trimws(body) == "```")
    if (length(close) == 0L) {
        return(NULL)
    }

    body[seq_len(close[[1L]] - 1L)]
}


test_that("the README's first workflow runs end to end", {
    skip_on_cran()
    skip_if_not_installed("dplyr")

    readme <- testthat::test_path("..", "..", "README.md")
    skip_if_not(file.exists(readme), "README.md is not on disk in this build")

    block <- extract_r_block(readme, "## A first workflow")
    skip_if(is.null(block), "could not locate the first workflow block")

    # Guard against the extraction silently finding the wrong block, which
    # would turn this into a test that passes by running nothing.
    joined <- paste(block, collapse = "\n")
    expect_match(joined, "init_project(", fixed = TRUE)
    expect_match(joined, "generate_manifest(", fixed = TRUE)

    # Run it in its own environment so nothing leaks into the test file, and
    # with the working directory somewhere disposable, since save_output()'s
    # output_dir default is relative to it.
    withr::local_dir(withr::local_tempdir())
    env <- new.env(parent = globalenv())

    expect_no_error(
        suppressMessages(suppressWarnings(
            eval(parse(text = joined), envir = env)
        ))
    )

    # The block builds project_dir itself; confirm the artifacts the prose
    # around it promises actually arrived.
    project_dir <- get("project_dir", envir = env)

    expect_true(fs::file_exists(fs::path(project_dir, "_toolero.yml")))
    expect_true(fs::file_exists(fs::path(project_dir, "analysis.qmd")))
    expect_true(fs::file_exists(fs::path(project_dir, "R", "analysis.R")))
    expect_true(fs::file_exists(fs::path(project_dir, "data", "clean.csv")))
    expect_true(fs::file_exists(
        fs::path(project_dir, "data", "jobs", "manifest.csv")
    ))
    expect_true(fs::file_exists(
        fs::path(project_dir, "output", "accumulator.csv")
    ))
    expect_true(fs::file_exists(
        fs::path(project_dir, "output", "project-manifest.json")
    ))
})
