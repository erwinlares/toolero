#' Apply a function to each group in a manifest or named list
#'
#' `run_by_group()` applies a function to each subset of a dataset and
#' collects the results. Subsets can be supplied in two ways: as files
#' listed in a manifest produced by [write_by_group()], or as a named
#' list of data frames already in memory. When the function returns
#' tabular output (a data frame or tibble), the results are automatically
#' unnested into a flat tibble with a group-id column. When the function
#' returns non-tabular output (a model, a plot, a file path), the results
#' are returned as a nested tibble with a group-id column and a `results`
#' list-column.
#'
#' @param manifest A character string, data frame, or `NULL`. If a
#'   string, the path to a manifest CSV produced by
#'   `write_by_group(manifest = TRUE)`. Must contain a `group_value`
#'   and a `file_path` column. If a data frame, used directly. If
#'   `groups` is supplied, `manifest` is ignored with a warning and
#'   may be omitted entirely.
#' @param .f A function to apply to each subset. Must accept a data
#'   frame as its first argument. Additional arguments can be passed
#'   via `...`.
#' @param ... Additional arguments passed to `.f` on every call. Forwarded
#'   unevaluated when running sequentially, so `.f` receives them exactly as
#'   it would from a direct call and tidy evaluation works. Materialized when
#'   `workers > 1`, which parallel execution requires. See the section on
#'   passing arguments below.
#' @param groups A named list of data frames, or `NULL` (the default).
#'   When supplied, `manifest` is ignored and `.f` is applied directly
#'   to each list element. All elements must be data frames with
#'   identical column names and column types -- consistent with subsets
#'   produced by [write_by_group()]. If the list is unnamed, groups are
#'   assigned fallback names `group_1`, `group_2`, etc. with a warning.
#' @param .id A character string. Name of the column that identifies
#'   each group in the output. Defaults to `"group_id"`.
#' @param .read_fn A function used to read each subset file when
#'   `manifest` is used. Defaults to [read_clean_csv()]. Ignored when
#'   `groups` is supplied.
#' @param workers A positive integer, or `NULL`. Number of parallel R
#'   sessions to use. When `1L` (the default) or `NULL`, subsets are
#'   processed sequentially with `purrr::map()`; `NULL` is accepted as a
#'   way of saying "do not parallelize" and is treated as `1L`. When
#'   greater than `1`, subsets are processed in parallel with
#'   `furrr::future_map()`. Requires the `furrr` and `future` packages.
#'   The maximum allowed value is
#'   `max(1L, parallelly::availableCores() - 1L)` to reserve one core
#'   for the main R session. A good starting value is the number of
#'   groups or that core ceiling, whichever is smaller.
#' @param seed An integer or `NULL`. Random seed for reproducible
#'   parallel execution. Only relevant when `workers > 1` and `.f`
#'   involves randomness (e.g. simulations, bootstrapping). When `NULL`
#'   (the default), no seed management is applied. Ignored when
#'   `workers = 1L`.
#' @param verbose Logical. If `TRUE`, prints a progress message before
#'   processing each group. When `workers > 1`, per-group progress is
#'   replaced by a single summary message showing the worker count.
#'   Defaults to `FALSE`.
#'
#' @return A tibble. If `.f` returns tabular output, the tibble is flat
#'   with a `.id` column prepended. If `.f` returns non-tabular output,
#'   the tibble has two columns: `.id` and `results` (a list-column).
#'
#' @section The split-apply pattern:
#' `run_by_group()` is the apply half of the split-apply workflow in
#' toolero. The split half is [write_by_group()], which partitions a
#' data frame by a grouping column and writes one file per group along
#' with a manifest.
#'
#' ```r
#' # Split to disk
#' write_by_group(penguins, group_col = "species",
#'                output_dir = "data/jobs", manifest = TRUE)
#'
#' # Apply from disk via manifest
#' results <- run_by_group(
#'   manifest = "data/jobs/manifest.csv",
#'   .f       = my_analysis
#' )
#'
#' # Apply from memory via named list
#' subsets <- penguins |>
#'   dplyr::group_split(species) |>
#'   setNames(c("Adelie", "Chinstrap", "Gentoo"))
#'
#' results <- run_by_group(
#'   groups = subsets,
#'   .f     = my_analysis
#' )
#' ```
#'
#' The split is done once. The apply step can be run many times as you
#' iterate on the analysis function.
#'
#' @section What .f receives and returns:
#' `.f` receives a single data frame as its first argument. It can
#' return anything, but the return type must be consistent across all
#' groups. Consistency is evaluated by bucket: either all groups return
#' a data frame (tabular) or none do (non-tabular). Mixed returns cause
#' an error identifying which groups returned unexpected types.
#'
#' Common return types and their output shape:
#' - A one-row tibble of summary statistics -- unnested into a flat table
#' - A multi-row tibble (e.g. model coefficients) -- unnested with the
#'   group ID repeated per row
#' - A model object -- returned as a list-column
#' - A ggplot object -- returned as a list-column
#' - A file path -- returned as a list-column
#'
#' @section Passing arguments through to `.f`:
#' Most arguments need nothing special. A number, a string, a logical, a
#' file path, a function: these are ordinary values, and they reach `.f`
#' in both modes exactly as you would expect. `run_by_group()` imposes no
#' requirement on how `.f` is written.
#'
#' ```r
#' scale_group <- function(data, multiplier) {
#'   dplyr::summarise(data, total = sum(x) * multiplier)
#' }
#'
#' run_by_group(groups = subsets, .f = scale_group, multiplier = 10)
#' ```
#'
#' One case is different, and only one: an argument that is a bare *column
#' name*. A symbol like `flipper_length_mm` has no meaning until it meets
#' the data, so a function that accepts one has to capture it rather than
#' evaluate it, which is what `{{ }}` does. That is a property of how `.f`
#' is written rather than anything `run_by_group()` asks for -- calling
#' such a function directly has the same requirement.
#'
#' ```r
#' plot_group <- function(data, x, y) {
#'   ggplot2::ggplot(data, ggplot2::aes(x = {{ x }}, y = {{ y }})) +
#'     ggplot2::geom_point()
#' }
#'
#' run_by_group(
#'   groups = subsets,
#'   .f     = plot_group,
#'   x      = flipper_length_mm,
#'   y      = body_mass_g
#' )
#' ```
#'
#' Run sequentially, which is the default, `...` is forwarded *unevaluated*,
#' so `flipper_length_mm` stays a symbol until `{{ }}` captures it inside
#' `plot_group()` and evaluates it against the group's data. Versions before
#' 0.5.0 evaluated `...` in `run_by_group()`'s own frame, where that symbol
#' means nothing, so the call above failed with
#' `object 'flipper_length_mm' not found` before `plot_group()` was reached.
#'
#' If you would rather not write `.f` that way, pass the column name as a
#' string and index with it. A string is an ordinary value, so it needs no
#' tidy evaluation and works in both modes:
#'
#' ```r
#' plot_group <- function(data, x, y) {
#'   ggplot2::ggplot(data, ggplot2::aes(x = .data[[x]], y = .data[[y]])) +
#'     ggplot2::geom_point()
#' }
#'
#' run_by_group(
#'   groups = subsets,
#'   .f     = plot_group,
#'   x      = "flipper_length_mm",
#'   y      = "body_mass_g"
#' )
#' ```
#'
#' **Bare column names do not survive `workers > 1`.** Parallel execution
#' sends the work to separate R sessions, which means every argument has to
#' be materialized and serialized first. An argument whose value exists only
#' inside the data mask `.f` builds has nothing to serialize, so it cannot
#' make the trip. `run_by_group()` reports this directly rather than letting
#' it surface from inside `future`'s globals inspection. Ordinary values,
#' strings included, are unaffected.
#'
#' The portable form for a bare column name moves it inside `.f`, which
#' works in both modes:
#'
#' ```r
#' run_by_group(
#'   groups  = subsets,
#'   .f      = \(d) plot_group(d, x = flipper_length_mm, y = body_mass_g),
#'   workers = 4
#' )
#' ```
#'
#' Two smaller consequences of forwarding rather than forcing, both matching
#' what a direct call to `.f` does, and both sequential-only: an argument
#' with a side effect is evaluated at most once for the whole call rather
#' than once per group, and an argument `.f` never touches is never
#' evaluated at all.
#'
#' @importFrom rlang :=
#' @importFrom parallelly availableCores
#' @export
#'
#' @examples
#' \donttest{
#' sample_path <- system.file("templates", "sample.csv", package = "toolero")
#' penguins <- read_clean_csv(sample_path)
#'
#' # Split the data to disk
#' tmp <- tempdir()
#' write_by_group(penguins, group_col = "species",
#'                output_dir = tmp, manifest = TRUE)
#'
#' # Define an analysis function
#' summarise_species <- function(data) {
#'   dplyr::summarise(data,
#'     n            = dplyr::n(),
#'     mean_mass    = mean(body_mass_g, na.rm = TRUE),
#'     mean_flipper = mean(flipper_length_mm, na.rm = TRUE)
#'   )
#' }
#'
#' # Apply via manifest -- returns a flat tibble
#' results <- run_by_group(
#'   manifest = file.path(tmp, "manifest.csv"),
#'   .f       = summarise_species
#' )
#'
#' # Apply via named list in memory
#' subsets <- penguins |>
#'   dplyr::group_split(species) |>
#'   setNames(c("Adelie", "Chinstrap", "Gentoo"))
#'
#' results <- run_by_group(
#'   groups = subsets,
#'   .f     = summarise_species
#' )
#'
#' # Apply a function that returns a model -- returns a nested tibble
#' fit_model <- function(data) {
#'   lm(body_mass_g ~ flipper_length_mm, data = data)
#' }
#'
#' models <- run_by_group(
#'   manifest = file.path(tmp, "manifest.csv"),
#'   .f       = fit_model
#' )
#'
#' # Parallel execution using available cores
#' workers <- max(1L, parallelly::availableCores() - 1L)
#'
#' results <- run_by_group(
#'   manifest = file.path(tmp, "manifest.csv"),
#'   .f       = summarise_species,
#'   workers  = workers
#' )
#'
#' # Reproducible parallel execution with a fixed seed
#' random_summary <- function(data) {
#'   tibble::tibble(val = sample(seq_len(nrow(data)), 1))
#' }
#'
#' results <- run_by_group(
#'   manifest = file.path(tmp, "manifest.csv"),
#'   .f       = random_summary,
#'   workers  = workers,
#'   seed     = 1234
#' )
#' }

run_by_group <- function(manifest = NULL,
                         .f,
                         ...,
                         groups   = NULL,
                         .id      = "group_id",
                         .read_fn = read_clean_csv,
                         workers  = 1L,
                         seed     = NULL,
                         verbose  = FALSE) {

    # -- 1. Validate .f and .read_fn -----------------------------------------------
    if (!is.function(.f)) {
        cli::cli_abort(
            "{.arg .f} must be a function. Got {.cls {class(.f)}}."
        )
    }

    if (!is.function(.read_fn)) {
        cli::cli_abort(
            "{.arg .read_fn} must be a function. Got {.cls {class(.read_fn)}}."
        )
    }

    # -- 2. Validate workers -------------------------------------------------------
    # This block establishes an invariant the rest of the function relies on:
    # past it, `workers` is a single integer of at least one. That is worth
    # stating because the only use of it is `if (workers > 1L)` roughly a
    # hundred and sixty lines below. Anything that reaches there without
    # being a length-one value fails at that line rather than here, and
    # `NULL > 1L` is `logical(0)`, which raises "argument is of length zero"
    # -- an error that says nothing about workers at all.
    #
    # NULL is coerced rather than rejected: it is a natural way to say "do
    # not parallelize", and one is what that means. Bare doubles like
    # workers = 2 are coerced for the same reason, so that comparisons
    # behave.

    if (is.null(workers)) {
        workers <- 1L
    }

    if (length(workers) != 1L) {
        cli::cli_abort(
            c("`workers` must be a single positive integer, or NULL.",
              "i" = "Received a value of length {length(workers)}."),
            class = "toolero_error"
        )
    }

    workers <- suppressWarnings(as.integer(workers))

    if (is.na(workers) || workers < 1L) {
        cli::cli_abort(
            c("`workers` must be a positive integer.",
              "i" = "Requested: {workers} workers."),
            class = "toolero_error"
        )
    }

    max_workers <- max(1L, parallelly::availableCores() - 1L)

    if (workers > max_workers) {
        cli::cli_abort(
            c("`workers` exceeds the recommended maximum for this machine.",
              "i" = "Requested: {workers} workers.",
              "i" = "Maximum allowed: {max_workers} ({parallelly::availableCores()} \\
           available cores minus 1 reserved for the main session).",
              "i" = "Reduce `workers` to {max_workers} or fewer."),
            class = "toolero_error"
        )
    }

    # -- 3. Resolve data source: groups (memory) or manifest (disk) ---------------
    if (!is.null(groups)) {

        # Warn if manifest was also supplied -- it will be ignored.
        if (!is.null(manifest)) {
            cli::cli_warn(
                "Both {.arg groups} and {.arg manifest} were supplied. {.arg manifest} is ignored when {.arg groups} is present."
            )
        }

        if (!is.list(groups)) {
            cli::cli_abort(
                "{.arg groups} must be a named list of data frames. Got {.cls {class(groups)}}."
            )
        }

        if (length(groups) == 0L) {
            cli::cli_abort("{.arg groups} must contain at least one element.")
        }

        # Require all elements to be data frames.
        not_df <- !vapply(groups, is.data.frame, logical(1))
        if (any(not_df)) {
            bad <- which(not_df)
            cli::cli_abort(c(
                "All elements of {.arg groups} must be data frames.",
                "i" = "{length(bad)} element{?s} {?is/are} not a data frame: position{?s} {.val {bad}}."
            ))
        }

        # Validate structural consistency: same column names and types across all
        # elements. The assumption is that groups come from splitting one dataset,
        # so any divergence in names or types indicates a preparation problem.
        ref_names <- names(groups[[1]])
        ref_types <- vapply(groups[[1]], function(col) class(col)[[1]], character(1))

        for (i in seq_along(groups)[-1]) {
            elem_names <- names(groups[[i]])
            elem_types <- vapply(groups[[i]], function(col) class(col)[[1]], character(1))

            if (!identical(ref_names, elem_names)) {
                cli::cli_abort(c(
                    "Element {i} of {.arg groups} has different column names than element 1.",
                    "i" = "Expected: {.val {ref_names}}.",
                    "i" = "Got: {.val {elem_names}}.",
                    "i" = "All elements must come from the same source dataset."
                ))
            }

            if (!identical(ref_types, elem_types)) {
                mismatched <- ref_names[ref_types != elem_types]
                cli::cli_abort(c(
                    "Element {i} of {.arg groups} has different column types than element 1.",
                    "i" = "Mismatched column{?s}: {.val {mismatched}}.",
                    "i" = "All elements must come from the same source dataset."
                ))
            }
        }

        # Assign fallback names if the list is unnamed.
        group_names <- names(groups)
        if (is.null(group_names) || any(group_names == "")) {
            fallback <- paste0("group_", seq_along(groups))
            cli::cli_warn(
                "{.arg groups} is unnamed or partially unnamed. Assigning fallback names: {.val {fallback}}."
            )
            group_names <- fallback
        }

        data_list <- groups

    } else {

        # -- manifest path -----------------------------------------------------------
        if (is.null(manifest)) {
            cli::cli_abort(
                "Either {.arg manifest} or {.arg groups} must be supplied."
            )
        }

        if (is.character(manifest)) {
            if (!file.exists(manifest)) {
                cli::cli_abort(
                    "Manifest file {.path {manifest}} does not exist."
                )
            }
            manifest_df <- readr::read_csv(manifest, show_col_types = FALSE)
        } else if (is.data.frame(manifest)) {
            manifest_df <- manifest
        } else {
            cli::cli_abort(
                "{.arg manifest} must be a file path or a data frame."
            )
        }

        required_cols <- c("group_value", "file_path")
        missing_cols  <- setdiff(required_cols, names(manifest_df))

        if (length(missing_cols) > 0L) {
            cli::cli_abort(c(
                "Manifest is missing required column{?s}: {.val {missing_cols}}.",
                "i" = "Use {.fn write_by_group} with {.code manifest = TRUE}",
                " " = "  to produce a compatible manifest."
            ))
        }

        if (nrow(manifest_df) == 0L) {
            cli::cli_abort("Manifest contains no rows.")
        }

        file_paths  <- manifest_df[["file_path"]]
        group_names <- manifest_df[["group_value"]]

        missing_files <- file_paths[!file.exists(file_paths)]
        if (length(missing_files) > 0L) {
            cli::cli_abort(c(
                "{length(missing_files)} subset file{?s} listed in the manifest {?was/were} not found.",
                "i" = "Missing path{?s}: {.path {missing_files}}.",
                "i" = "Check that {.fn write_by_group} output is still in place."
            ))
        }

        # Read all subset files into a named list. Names are set here so that
        # data_list mirrors the structure produced by the groups path -- both
        # branches produce a named list and the apply step below is identical
        # for both sources.
        data_list        <- purrr::map(file_paths, .read_fn)
        names(data_list) <- group_names
    }

    # -- 4. Apply .f to each subset ------------------------------------------------
    # The two paths handle `...` differently, and the difference is forced by
    # what each one can do rather than by preference.
    #
    # Sequentially, `...` is forwarded unevaluated. Each argument stays a
    # promise, which is exactly what `.f` would have received from a direct
    # call, so a bare column name survives for `{{ }}` to capture inside
    # `.f`. The previous implementation captured `list(...)` up front, which
    # forced every argument in this frame, where a column name means
    # nothing, and failed before `.f` was entered.
    #
    # In parallel it cannot work that way. `future` inspects the worker
    # function for globals and materializes them so they can be sent to the
    # worker sessions, and `...` is one of them. An argument whose value
    # only exists inside `.f`'s data mask has nothing to send. That is
    # inherent to crossing a process boundary, not a `furrr` quirk, so the
    # parallel branch materializes `...` deliberately and explains itself
    # when an argument cannot survive it.

    if (workers > 1L) {
        rlang::check_installed("furrr",  reason = "for parallel execution")
        rlang::check_installed("future", reason = "for parallel execution")

        # Materialized here rather than inside the worker so the failure is
        # caught in this frame, where there is enough context to explain it.
        # Left to `future`, the same failure surfaces from six frames down
        # inside globals::globalsOf() as a bare "object 'x' not found".
        dots <- tryCatch(
            list(...),
            error = function(cnd) .abort_parallel_dots(cnd)
        )

        old_plan <- future::plan(future::multisession, workers = workers)
        on.exit(future::plan(old_plan), add = TRUE)

        # Prevent worker sessions from attempting to activate the renv environment.
        # Without this, workers launched by future on renv-managed projects may
        # try to load the project's renv autoloader, which can fail silently or
        # produce library-path conflicts when the worker session diverges from the
        # main session. withr::local_envvar() captures and restores the prior
        # value of the variable correctly, unlike Sys.unsetenv() which would
        # delete it entirely if the user already had it set.
        withr::local_envvar(RENV_CONFIG_AUTOLOADER_ENABLED = "false")

        if (verbose) {
            cli::cli_inform(
                "Running {length(data_list)} group{?s} in parallel across {workers} worker{?s}. Per-group progress is not available during parallel execution."
            )
        }

        furrr_opts <- furrr::furrr_options(seed = seed)

        results_list <- furrr::future_map(
            seq_along(data_list),
            function(i) do.call(.f, c(list(data_list[[i]]), dots)),
            .options = furrr_opts
        )

    } else {

        results_list <- purrr::map(
            seq_along(data_list),
            function(i) {
                if (verbose) {
                    cli::cli_inform(
                        "Processing group {.val {group_names[[i]]}} ({i}/{length(data_list)})"
                    )
                }
                .f(data_list[[i]], ...)
            }
        )
    }

    names(results_list) <- group_names

    # -- 5. Check return type consistency ------------------------------------------
    # Classify each result as tabular (data frame) or non-tabular. All groups
    # must fall into the same bucket -- mixed returns indicate a bug in .f.
    is_tabular <- vapply(results_list, is.data.frame, logical(1))

    if (length(unique(is_tabular)) > 1L) {
        tabular_groups     <- group_names[is_tabular]
        non_tabular_groups <- group_names[!is_tabular]

        cli::cli_abort(c(
            "The function returned mixed types across groups.",
            "i" = "These groups returned a data frame: {.val {tabular_groups}}.",
            "i" = "These groups did not: {.val {non_tabular_groups}}.",
            "i" = "Check that your function returns the same type for every input."
        ))
    }

    # -- 6. Assemble output tibble -------------------------------------------------
    output <- tibble::tibble(
        !!.id   := group_names,
        results  = results_list
    )

    # -- 7. Auto-unnest if results are tabular -------------------------------------
    if (all(is_tabular)) {
        output <- tidyr::unnest(output, results)
    }

    output
}


# -- Helper: explain a ... argument that cannot cross a process boundary -------

#' Report a `...` argument that cannot be sent to a parallel worker
#'
#' Internal helper used by [run_by_group()] when materializing `...` for
#' parallel execution fails. The usual cause is a bare column name intended
#' for `.f` to capture with `{{ }}`: it has no value outside the data mask
#' `.f` builds, so there is nothing to send to a worker session.
#'
#' @param cnd The condition raised while evaluating `...`.
#'
#' @return Never returns; aborts.
#'
#' @keywords internal
.abort_parallel_dots <- function(cnd) {
    cli::cli_abort(
        c(
            "An argument in {.arg ...} could not be evaluated for parallel
             execution.",
            "x" = conditionMessage(cnd),
            "i" = "With {.code workers > 1}, {.arg ...} has to be materialized
                   so it can be sent to the worker sessions. An argument that
                   only means something inside {.arg .f} -- a bare column name
                   for tidy evaluation to capture -- has no value to send.",
            "i" = "Run sequentially with {.code workers = 1}, where {.arg ...}
                   is forwarded unevaluated and tidy evaluation works.",
            "i" = "Or move the argument inside {.arg .f}, which works in both
                   modes: {.code .f = function(d) my_fn(d, x = my_column)}."
        ),
        class  = "toolero_error",
        parent = cnd
    )
}
