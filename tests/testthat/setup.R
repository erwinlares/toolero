# tests/testthat/setup.R

# renv's sandbox and covr do not get along.
#
# covr runs the suite in its own process with its own library path.
# test-init-project.R mocks renv::scaffold() through
# local_mocked_bindings(.package = "renv"), and mocking a binding in
# another package requires loading that package's namespace. renv's load
# hook then activates its sandbox and takes over .libPaths(), dropping
# both the project library and covr's temporary one.
#
# Packages already loaded survive; anything reached with :: afterwards
# does not. vroom (under readr::write_csv()), janitor, tidyr and dplyr
# all became invisible partway through the run and were reported as
# "not installed" while sitting in the project library.
#
# Remove this once init_project() takes an injectable scaffold function
# and the tests no longer reach into renv's namespace.
Sys.setenv(RENV_CONFIG_SANDBOX_ENABLED = "FALSE")
