# tests/testthat/setup.R

# T35 (see covr-renv-incident.md): a permanent guard against a repeat of
# the covr/renv incident. That incident's real damage was renv's load hook
# silently repointing .libPaths() mid-suite -- surfacing three files away
# from the test that triggered it, as a misleading "package not installed"
# error rather than anything pointing at .libPaths(). testthat's own state
# inspector already catches tests that leave options(), the working
# directory, or attached packages changed; .libPaths() just isn't one of
# the things it checks by default. Any test that changes it without
# restoring the change now fails immediately and names the offending test.

# T41: two more guards for the project-root rule.
#
# 1. _CONDOR_SCRATCH_DIR is unset for the whole suite. On an HTCondor
#    execute node .project_root() returns that directory before it looks
#    at any marker, so a suite run inside a job would otherwise see the
#    scratch directory as the root of every temporary project. Tests that
#    want it set it themselves with withr::local_envvar().
#
# 2. The state inspector also records the listing of the package root and
#    of tests/testthat. A test that passes a relative path while its
#    working directory is still tests/testthat writes into the source
#    tree, and until now the only evidence was git status afterwards. With
#    this guard the test that did it fails, by name. A stray Rplots.pdf
#    from a graphics call is caught the same way, and is a real finding.

withr::local_envvar(
    c("_CONDOR_SCRATCH_DIR" = NA),
    .local_envir = testthat::teardown_env()
)

local({
    tests_dir    <- normalizePath(getwd())
    package_root <- normalizePath(file.path(tests_dir, "..", ".."))

    listing <- function(dir) {
        sort(list.files(dir, all.files = TRUE, no.. = TRUE))
    }

    testthat::set_state_inspector(function() {
        list(
            libpaths     = .libPaths(),
            tests_dir    = listing(tests_dir),
            package_root = listing(package_root)
        )
    })
})
