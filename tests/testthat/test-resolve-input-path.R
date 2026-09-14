# tests/testthat/test-resolve-input-path.R
#
# `context` is supplied directly throughout rather than simulated through
# detect_execution_context(), since what is under test here is what happens
# once the branch has been chosen.

# Helper: a real file to resolve to, so must_exist has something to find.
local_input_file <- function(env = parent.frame()) {
    dir <- withr::local_tempdir(.local_envir = env)
    path <- fs::path(dir, "sample.csv")
    readr::write_file("a,b\n1,2\n", path)
    as.character(path)
}


# -- Branch selection ----------------------------------------------------------

test_that("the interactive branch is returned in the interactive context", {
    file <- local_input_file()

    expect_equal(
        resolve_input_path(interactive = file, context = "interactive"),
        file
    )
})

test_that("the quarto branch is returned in the quarto context", {
    file <- local_input_file()

    expect_equal(
        resolve_input_path(quarto = file, context = "quarto"),
        file
    )
})

test_that("the rscript branch is returned in the rscript context", {
    file <- local_input_file()

    expect_equal(
        resolve_input_path(rscript = file, context = "rscript"),
        file
    )
})

test_that("only the selected branch is evaluated", {
    file <- local_input_file()
    forced <- character(0)

    touch <- function(label) {
        forced <<- c(forced, label)
        file
    }

    result <- resolve_input_path(
        interactive = touch("interactive"),
        quarto      = touch("quarto"),
        rscript     = touch("rscript"),
        context     = "rscript"
    )

    expect_equal(result, file)
    expect_equal(forced, "rscript")
})

test_that("an unselected branch may reference an object that does not exist", {
    # This is the property that makes the pattern safe under Rscript, where
    # `params` is undefined. The promise is never forced.
    file <- local_input_file()

    expect_no_error(
        resolve_input_path(
            quarto  = no_such_object$input_file,
            rscript = file,
            context = "rscript"
        )
    )
})


# -- must_exist ----------------------------------------------------------------

test_that("a path that does not exist is an error by default", {
    expect_error(
        resolve_input_path(rscript = "no/such/file.csv", context = "rscript"),
        "does not exist"
    )
})

test_that("the missing-path error names the context and the working directory", {
    expect_error(
        resolve_input_path(rscript = "no/such/file.csv", context = "rscript"),
        "rscript"
    )
    # Single words, since cli wraps the bullets at the console width and a
    # phrase can be split across the break.
    expect_error(
        resolve_input_path(rscript = "no/such/file.csv", context = "rscript"),
        "Relative"
    )
})

test_that("must_exist = FALSE accepts a path that is not on disk", {
    expect_equal(
        resolve_input_path(rscript = "s3://bucket/data.csv",
                           context = "rscript", must_exist = FALSE),
        "s3://bucket/data.csv"
    )
})


# -- Unusable branch values ----------------------------------------------------

test_that("NA from commandArgs() is reported as a missing argument", {
    expect_error(
        resolve_input_path(rscript = NA_character_, context = "rscript"),
        "No input path was given"
    )
})

test_that("the rscript message points at submitr's data_files", {
    expect_error(
        resolve_input_path(rscript = NA_character_, context = "rscript"),
        "data_files"
    )
})

test_that("a NULL params value is reported against the params block", {
    expect_error(
        resolve_input_path(quarto = NULL, context = "quarto"),
        "input_file"
    )
})

test_that("an empty string is treated as unresolved", {
    expect_error(
        resolve_input_path(interactive = "", context = "interactive"),
        "No input path is available"
    )
    expect_error(
        resolve_input_path(interactive = "   ", context = "interactive"),
        "No input path is available"
    )
})

test_that("a multi-element value is treated as unresolved", {
    expect_error(
        resolve_input_path(rscript = c("a.csv", "b.csv"), context = "rscript"),
        "No input path was given"
    )
})


# -- A branch expression that errors when forced -------------------------------

test_that("a missing params object produces a message about the header", {
    # The reason this is a function and not a documented switch(): the
    # promise is forced inside resolve_input_path(), so the error is
    # catchable somewhere that knows what params is for.
    expect_error(
        resolve_input_path(quarto = params$input_file, context = "quarto"),
        "does not declare a"
    )
})

test_that("the missing-params message mentions the YAML header", {
    expect_error(
        resolve_input_path(quarto = params$input_file, context = "quarto"),
        "header"
    )
})

test_that("any other branch error is reported with its own message", {
    expect_error(
        resolve_input_path(rscript = stop("something else broke"),
                           context = "rscript"),
        "something else broke"
    )
})


# -- Defaults ------------------------------------------------------------------

test_that("the rscript branch defaults to the first command line argument", {
    # No argument is passed when testthat runs, so the default resolves to
    # NA and the missing-argument message is what surfaces.
    expect_error(
        resolve_input_path(context = "rscript"),
        "No input path was given"
    )
})

test_that("an omitted quarto branch falls back to params$input_file", {
    file <- local_input_file()
    params <- list(input_file = file)

    expect_equal(resolve_input_path(context = "quarto"), file)
})

test_that("an omitted interactive branch falls back to params$input_file", {
    # This is what makes the YAML header the single source of truth: the
    # path is written once, in the header, rather than there and again in
    # a chunk that has to be kept in step with it.
    file <- local_input_file()
    params <- list(input_file = file)

    expect_equal(resolve_input_path(context = "interactive"), file)
})

test_that("an omitted branch with no params at all is reported cleanly", {
    expect_error(
        resolve_input_path(context = "interactive"),
        "No input path is available"
    )
})

test_that("a params object without input_file is reported cleanly", {
    params <- list(seed = 42)

    expect_error(
        resolve_input_path(context = "quarto"),
        "input_file"
    )
})

test_that("a supplied branch beats the params fallback", {
    file <- local_input_file()
    params <- list(input_file = "should-not-be-used.csv")

    expect_equal(
        resolve_input_path(interactive = file, context = "interactive"),
        file
    )
})

test_that("an explicit NULL is not treated as omitted", {
    params <- list(input_file = "should-not-be-used.csv")

    expect_error(
        resolve_input_path(interactive = NULL, context = "interactive"),
        "No input path is available"
    )
})


# -- context argument ----------------------------------------------------------

test_that("context defaults to detect_execution_context()", {
    file <- local_input_file()

    local_mocked_bindings(
        detect_execution_context = function(...) "rscript"
    )

    expect_equal(resolve_input_path(rscript = file), file)
})

test_that("an invalid context is rejected", {
    expect_error(resolve_input_path(context = "knitr"), "must be one of")
    expect_error(resolve_input_path(context = 1L), "must be one of")
    expect_error(
        resolve_input_path(context = c("quarto", "rscript")),
        "must be one of"
    )
})


# -- .params_input_file() helper -----------------------------------------------

test_that("params_input_file() returns NULL when there is no params object", {
    env <- new.env(parent = emptyenv())
    expect_null(.params_input_file(env))
})

test_that("params_input_file() returns NULL when params is not a list", {
    env <- new.env(parent = emptyenv())
    assign("params", "not a list", envir = env)
    expect_null(.params_input_file(env))
})

test_that("params_input_file() reads input_file out of a params list", {
    env <- new.env(parent = emptyenv())
    assign("params", list(input_file = "data-raw/x.csv"), envir = env)
    expect_equal(.params_input_file(env), "data-raw/x.csv")
})

test_that("params_input_file() searches enclosing environments", {
    # knitr assigns params into the environment the document is knit in,
    # which is an enclosure of the chunk's own frame rather than the frame
    # itself.
    outer <- new.env(parent = emptyenv())
    assign("params", list(input_file = "data-raw/x.csv"), envir = outer)
    inner <- new.env(parent = outer)

    expect_equal(.params_input_file(inner), "data-raw/x.csv")
})
