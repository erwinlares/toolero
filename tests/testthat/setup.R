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

testthat::set_state_inspector(function() {
    list(libpaths = .libPaths())
})
