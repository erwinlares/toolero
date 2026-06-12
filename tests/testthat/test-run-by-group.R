# Tests for run_by_group()
# Organized by: input validation, data source dispatch, output shape,
#               parallel execution, verbose messaging

# -- Shared fixtures -----------------------------------------------------------

# Minimal well-formed data: two groups, identical structure.
grp_a <- tibble::tibble(x = 1:3, y = c(10, 20, 30), label = "a")
grp_b <- tibble::tibble(x = 4:6, y = c(40, 50, 60), label = "b")

valid_groups <- list(alpha = grp_a, beta = grp_b)

# Analysis functions used across multiple test blocks.
summarise_fn  <- function(data) tibble::tibble(n = nrow(data), mean_x = mean(data$x))
nontabular_fn <- function(data) lm(y ~ x, data = data)
identity_fn   <- function(data) data

# Helper: write a minimal manifest + subset CSVs into a temp directory.
# Returns a list with slots $dir, $manifest_path, $file_paths.
make_manifest <- function(root, groups = valid_groups) {
    group_names <- names(groups)
    file_paths  <- fs::path(root, paste0(group_names, ".csv"))

    purrr::walk2(groups, file_paths, \(df, path) readr::write_csv(df, path))

    manifest_path <- fs::path(root, "manifest.csv")
    readr::write_csv(
        tibble::tibble(group_value = group_names, file_path = file_paths),
        manifest_path
    )

    list(dir = root, manifest_path = manifest_path, file_paths = file_paths)
}

# File-level temp dir: scoped to the test file, passed into helpers so that
# withr::local_tempdir() inside a helper does not evict it at function exit.
tmp <- withr::local_tempdir()


# -- 1. Input validation -------------------------------------------------------

test_that(".f must be a function", {
    expect_error(
        run_by_group(groups = valid_groups, .f = "not_a_function"),
        class = "rlang_error"
    )
})

test_that(".read_fn must be a function", {
    mf <- make_manifest(tmp)
    expect_error(
        run_by_group(manifest = mf$manifest_path, .f = summarise_fn, .read_fn = "csv"),
        class = "rlang_error"
    )
})

test_that("workers = 0 is rejected", {
    expect_error(
        run_by_group(groups = valid_groups, .f = summarise_fn, workers = 0L),
        class = "rlang_error"
    )
})

test_that("workers = -1 is rejected", {
    expect_error(
        run_by_group(groups = valid_groups, .f = summarise_fn, workers = -1L),
        class = "rlang_error"
    )
})

test_that("workers above physical core ceiling is rejected", {
    max_workers <- parallel::detectCores(logical = FALSE) - 1L
    expect_error(
        run_by_group(groups = valid_groups, .f = summarise_fn,
                     workers = max_workers + 1L),
        class = "rlang_error"
    )
})

test_that("groups must be a list", {
    expect_error(
        run_by_group(groups = grp_a, .f = summarise_fn),
        class = "rlang_error"
    )
})

test_that("groups must not be empty", {
    expect_error(
        run_by_group(groups = list(), .f = summarise_fn),
        class = "rlang_error"
    )
})

test_that("groups elements must all be data frames", {
    bad_groups <- list(alpha = grp_a, beta = "not_a_df")
    expect_error(
        run_by_group(groups = bad_groups, .f = summarise_fn),
        class = "rlang_error"
    )
})

test_that("groups elements must have identical column names", {
    different_names <- list(
        alpha = grp_a,
        beta  = tibble::tibble(x = 4:6, z = c(40, 50, 60), label = "b")
    )
    expect_error(
        run_by_group(groups = different_names, .f = summarise_fn),
        class = "rlang_error"
    )
})

test_that("groups elements must have identical column types", {
    different_types <- list(
        alpha = grp_a,
        beta  = tibble::tibble(x = c("a", "b", "c"), y = c(40, 50, 60), label = "b")
    )
    expect_error(
        run_by_group(groups = different_types, .f = summarise_fn),
        class = "rlang_error"
    )
})

test_that("manifest path that does not exist is rejected", {
    expect_error(
        run_by_group(manifest = "/no/such/file.csv", .f = summarise_fn),
        class = "rlang_error"
    )
})

test_that("manifest missing required columns is rejected", {
    bad_manifest <- tibble::tibble(wrong_col = "a", also_wrong = "/path/a.csv")
    expect_error(
        run_by_group(manifest = bad_manifest, .f = summarise_fn),
        class = "rlang_error"
    )
})

test_that("manifest with zero rows is rejected", {
    empty_manifest <- tibble::tibble(group_value = character(), file_path = character())
    expect_error(
        run_by_group(manifest = empty_manifest, .f = summarise_fn),
        class = "rlang_error"
    )
})

test_that("manifest referencing missing subset files is rejected", {
    ghost_manifest <- tibble::tibble(
        group_value = c("alpha", "beta"),
        file_path   = c("/no/such/alpha.csv", "/no/such/beta.csv")
    )
    expect_error(
        run_by_group(manifest = ghost_manifest, .f = summarise_fn),
        class = "rlang_error"
    )
})

test_that("neither manifest nor groups supplied is rejected", {
    expect_error(
        run_by_group(.f = summarise_fn),
        class = "rlang_error"
    )
})


# -- 2. Data source dispatch ---------------------------------------------------

test_that("groups takes priority over manifest when both are supplied", {
    mf <- make_manifest(tmp)
    expect_warning(
        result <- run_by_group(
            manifest = mf$manifest_path,
            groups   = valid_groups,
            .f       = summarise_fn
        ),
        regexp = "manifest.*ignored"
    )
    # Result should come from groups (2 rows -- one per group)
    expect_equal(nrow(result), 2L)
})

test_that("unnamed groups receive fallback names with a warning", {
    unnamed_groups <- list(grp_a, grp_b)
    expect_warning(
        result <- run_by_group(groups = unnamed_groups, .f = summarise_fn),
        regexp = "fallback"
    )
    expect_true("group_id" %in% names(result))
    expect_equal(result$group_id, c("group_1", "group_2"))
})

test_that("manifest CSV on disk produces correct group names in output", {
    mf <- make_manifest(tmp)
    result <- run_by_group(manifest = mf$manifest_path, .f = summarise_fn)
    expect_equal(sort(result$group_id), sort(names(valid_groups)))
})

test_that("manifest supplied as a data frame works correctly", {
    mf <- make_manifest(tmp)
    manifest_df <- readr::read_csv(mf$manifest_path, show_col_types = FALSE)
    result <- run_by_group(manifest = manifest_df, .f = summarise_fn)
    expect_equal(nrow(result), 2L)
})

test_that("groups path and manifest path produce identical results", {
    mf <- make_manifest(tmp)
    result_groups   <- run_by_group(groups = valid_groups, .f = summarise_fn)
    result_manifest <- run_by_group(manifest = mf$manifest_path, .f = summarise_fn)
    # Sort by group_id before comparing so row order does not matter.
    expect_equal(
        dplyr::arrange(result_groups,   group_id),
        dplyr::arrange(result_manifest, group_id)
    )
})


# -- 3. Output shape -----------------------------------------------------------

test_that("tabular .f returns a flat tibble", {
    result <- run_by_group(groups = valid_groups, .f = summarise_fn)
    expect_s3_class(result, "tbl_df")
    expect_true("group_id" %in% names(result))
    expect_false("results" %in% names(result))
})

test_that("tabular .f result has one row per group when .f returns one row", {
    result <- run_by_group(groups = valid_groups, .f = summarise_fn)
    expect_equal(nrow(result), length(valid_groups))
})

test_that("tabular .f result has n rows per group when .f returns multiple rows", {
    result <- run_by_group(groups = valid_groups, .f = identity_fn)
    expect_equal(nrow(result), nrow(grp_a) + nrow(grp_b))
})

test_that("non-tabular .f returns a nested tibble with a results list-column", {
    result <- run_by_group(groups = valid_groups, .f = nontabular_fn)
    expect_s3_class(result, "tbl_df")
    expect_true("results" %in% names(result))
    expect_type(result$results, "list")
})

test_that("non-tabular results list contains the expected object type", {
    result <- run_by_group(groups = valid_groups, .f = nontabular_fn)
    expect_true(all(vapply(result$results, inherits, logical(1), "lm")))
})

test_that(".id argument renames the group column", {
    result <- run_by_group(groups = valid_groups, .f = summarise_fn, .id = "species")
    expect_true("species" %in% names(result))
    expect_false("group_id" %in% names(result))
})

test_that("mixed return types across groups raises an error", {
    mixed_fn <- function(data) {
        if (data$label[[1]] == "a") tibble::tibble(n = nrow(data)) else lm(y ~ x, data = data)
    }
    expect_error(
        run_by_group(groups = valid_groups, .f = mixed_fn),
        class = "rlang_error"
    )
})

test_that("... arguments are passed through to .f on every call", {
    fn_with_extra <- function(data, multiplier) {
        tibble::tibble(result = mean(data$x) * multiplier)
    }
    result <- run_by_group(groups = valid_groups, .f = fn_with_extra, multiplier = 10)
    expect_equal(result$result, c(mean(grp_a$x) * 10, mean(grp_b$x) * 10))
})

test_that("group names appear correctly in output", {
    result <- run_by_group(groups = valid_groups, .f = summarise_fn)
    expect_setequal(result$group_id, c("alpha", "beta"))
})


# -- 4. Parallel execution -----------------------------------------------------

test_that("workers = 2L produces same output as workers = 1L", {
    skip_on_cran()
    skip_on_ci()

    result_seq <- run_by_group(groups = valid_groups, .f = summarise_fn, workers = 1L)
    result_par <- run_by_group(groups = valid_groups, .f = summarise_fn, workers = 2L)

    expect_equal(
        dplyr::arrange(result_seq, group_id),
        dplyr::arrange(result_par, group_id)
    )
})

test_that("seed produces reproducible results in parallel", {
    skip_on_cran()
    skip_on_ci()

    random_fn <- function(data) tibble::tibble(val = sample(1:1000, 1))

    result_1 <- run_by_group(groups = valid_groups, .f = random_fn,
                             workers = 2L, seed = 42L)
    result_2 <- run_by_group(groups = valid_groups, .f = random_fn,
                             workers = 2L, seed = 42L)

    expect_equal(result_1$val, result_2$val)
})

test_that("different seeds produce different results in parallel", {
    skip_on_cran()
    skip_on_ci()

    # Build groups large enough that the probability of a collision is negligible.
    large_groups <- purrr::map(
        setNames(letters[1:4], letters[1:4]),
        \(l) tibble::tibble(x = 1:10, label = l)
    )
    random_fn <- function(data) tibble::tibble(val = sample(1:1e6, 1))

    result_a <- run_by_group(groups = large_groups, .f = random_fn,
                             workers = 2L, seed = 1L)
    result_b <- run_by_group(groups = large_groups, .f = random_fn,
                             workers = 2L, seed = 2L)

    expect_false(identical(result_a$val, result_b$val))
})


# -- 5. Verbose messaging ------------------------------------------------------

test_that("verbose = TRUE emits one message per group in sequential mode", {
    expect_message(
        run_by_group(groups = valid_groups, .f = summarise_fn, verbose = TRUE),
        regexp = "Processing group"
    )
})

test_that("verbose = FALSE emits no messages in sequential mode", {
    expect_no_message(
        run_by_group(groups = valid_groups, .f = summarise_fn, verbose = FALSE)
    )
})

test_that("verbose = TRUE emits a parallel summary message when workers > 1", {
    skip_on_cran()
    skip_on_ci()

    expect_message(
        run_by_group(groups = valid_groups, .f = summarise_fn,
                     workers = 2L, verbose = TRUE),
        regexp = "parallel"
    )
})
