# tests/testthat/test-detect_execution_context.R

test_that("returns 'rscript' when not interactive and QUARTO_DOCUMENT_PATH is unset", {
    withr::with_envvar(
        c(QUARTO_DOCUMENT_PATH = ""),
        {
            result <- detect_execution_context(interactive_fn = function() FALSE)
            expect_equal(result, "rscript")
        }
    )
})

test_that("returns 'quarto' when QUARTO_DOCUMENT_PATH is set", {
    withr::with_envvar(
        c(QUARTO_DOCUMENT_PATH = "/some/path/document.qmd"),
        {
            result <- detect_execution_context(interactive_fn = function() FALSE)
            expect_equal(result, "quarto")
        }
    )
})

test_that("returns 'interactive' when session is interactive", {
    result <- detect_execution_context(interactive_fn = function() TRUE)
    expect_equal(result, "interactive")
})

# The priority order is documented, and this pins it, but the case is not
# reachable in practice: every path that renders a Quarto document runs the
# R code in a process that is not interactive, and running chunks inline in
# RStudio leaves QUARTO_DOCUMENT_PATH unset (checked September 2026). The
# test exists so that a future reordering is a deliberate act rather than an
# accident, not because the ordering is observable.
test_that("'interactive' takes priority over QUARTO_DOCUMENT_PATH being set", {
    withr::with_envvar(
        c(QUARTO_DOCUMENT_PATH = "/some/path/document.qmd"),
        {
            result <- detect_execution_context(interactive_fn = function() TRUE)
            expect_equal(result, "interactive")
        }
    )
})

test_that("returns a single character string", {
    withr::with_envvar(
        c(QUARTO_DOCUMENT_PATH = ""),
        {
            result <- detect_execution_context(interactive_fn = function() FALSE)
            expect_type(result, "character")
            expect_length(result, 1)
        }
    )
})
