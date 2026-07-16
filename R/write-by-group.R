#' Split a data frame by one or more grouping columns and write each group to a CSV file
#'
#' Splits a data frame by one or more grouping columns and writes each group
#' to a separate CSV file. Optionally writes a manifest file listing the
#' output files, their group values, and row counts.
#'
#' @param data A data frame or tibble to split and save.
#' @param group_col A character vector. The name(s) of the column(s) to
#'   group by. A single column name behaves exactly as in previous versions.
#'   When more than one column is supplied, groups are formed from the
#'   combinations of values actually present in the data (not the full
#'   cross-product of possible values).
#' @param output_dir A string or `NULL`. Path to the directory where output
#'   files will be written. Created if it does not exist. If `NULL`, the
#'   user must supply a path explicitly.
#' @param manifest A logical. Whether to write a `manifest.csv` file to
#'   `output_dir` listing the output files, group values, and row counts.
#'   Defaults to `FALSE`.
#' @param drop_na A logical. If `TRUE` (default), rows with a missing value
#'   in any grouping column are dropped before splitting, and a message
#'   reports how many rows were dropped and from which column(s). If
#'   `FALSE`, missing values are treated as their own group instead of
#'   being dropped.
#'
#' @return Invisibly returns `output_dir`.
#'
#' @details
#' Output filenames are derived from the group values of `group_col`.
#' Each value is sanitized independently: converted to lowercase, spaces
#' and special characters replaced with `-`, consecutive dashes collapsed,
#' and leading/trailing dashes stripped. When `group_col` has more than one
#' element, the sanitized values are joined with `--` in the order supplied
#' (e.g. `group_col = c("species", "sex")` on an Adelie male produces
#' `adelie--male.csv`). Because a single sanitized value can never itself
#' contain two consecutive dashes, `--` is an unambiguous separator between
#' columns.
#'
#' If `manifest = TRUE`, a `manifest.csv` is written to `output_dir`. For a
#' single grouping column, the manifest schema is unchanged from previous
#' versions: `group_value`, `n_rows`, `file_path`. For multiple grouping
#' columns, the manifest additionally includes one column per grouping
#' variable (holding the raw, unsanitized value), inserted before
#' `group_value`, which becomes a human-readable composite of the raw
#' values joined by `" | "` (e.g. `"Adelie | male"`).
#'
#' Note: `output_dir` has no default value. Always supply an explicit path
#' to avoid writing files to unexpected locations. Use `tempdir()` for
#' temporary output during testing or exploration.
#'
#' Note on group iteration order: groups are split on the sanitized,
#' character-coerced composite key, so iteration order follows the sort
#' order of that key rather than the original column's native type. For
#' single-column grouping this can differ from previous versions when
#' `group_col` is numeric with values of differing digit length (e.g.
#' `9, 10, 11` sorts numerically in earlier versions but lexicographically
#' as `10, 11, 9` here) or when case affects locale-specific sort order.
#' File contents and manifest row counts are unaffected -- only the order
#' in which groups are written and reported.
#'
#' @export
#'
#' @examples
#' \donttest{
#' # Split a small data frame by group and write to a temp directory
#' data <- data.frame(
#'   species = c("Adelie", "Adelie", "Gentoo"),
#'   mass    = c(3750, 3800, 5000)
#' )
#' write_by_group(data, group_col = "species", output_dir = tempdir())
#'
#' # Same but also write a manifest
#' write_by_group(data, group_col = "species",
#'                output_dir = tempdir(), manifest = TRUE)
#'
#' # Group by more than one column
#' data2 <- data.frame(
#'   species = c("Adelie", "Adelie", "Gentoo"),
#'   sex     = c("male", "female", "male"),
#'   mass    = c(3750, 3550, 5000)
#' )
#' write_by_group(data2, group_col = c("species", "sex"),
#'                output_dir = tempdir(), manifest = TRUE)
#' }
write_by_group <- function(
        data,
        group_col,
        output_dir = NULL,
        manifest = FALSE,
        drop_na = TRUE) {

    # -- 0. Validate output_dir -------------------------------------------------
    if (is.null(output_dir)) {
        cli::cli_abort(
            "{.arg output_dir} must be supplied. Use {.code tempdir()} for temporary
       output or provide an explicit path."
        )
    }

    # -- 1. Validate data -------------------------------------------------------
    if (!is.data.frame(data)) {
        cli::cli_abort(
            "{.arg data} must be a data frame or tibble, not {.cls {class(data)}}."
        )
    }

    # -- 2. Validate group_col ----------------------------------------------------
    if (!is.character(group_col) || length(group_col) < 1L || anyNA(group_col)) {
        cli::cli_abort(
            "{.arg group_col} must be a non-NA character vector of column names."
        )
    }

    if (anyDuplicated(group_col) > 0) {
        cli::cli_abort(
            "{.arg group_col} contains duplicated column name{?s}:
       {.val {unique(group_col[duplicated(group_col)])}}."
        )
    }

    missing_cols <- setdiff(group_col, names(data))
    if (length(missing_cols) > 0) {
        cli::cli_abort(
            "{length(missing_cols)} column{?s} not found in {.arg data}: {.val {missing_cols}}.
       Available columns: {.val {names(data)}}."
        )
    }

    is_list_col <- vapply(data[group_col], is.list, logical(1))
    if (any(is_list_col)) {
        cli::cli_abort(
            "{.arg group_col} cannot include list-column{?s}: {.val {group_col[is_list_col]}}."
        )
    }

    if (manifest) {
        reserved_names <- c("group_value", "n_rows", "file_path")
        reserved_hits  <- intersect(group_col, reserved_names)
        if (length(reserved_hits) > 0) {
            cli::cli_abort(
                "{length(reserved_hits)} column name{?s} in {.arg group_col} {?is/are}
         reserved for the manifest: {.val {reserved_hits}}. This only matters
         when {.code manifest = TRUE}."
            )
        }
    }

    # -- 3. Create output_dir if needed -----------------------------------------
    fs::dir_create(output_dir)

    # -- 4. Handle NA rows in grouping columns -----------------------------------
    na_mask <- rowSums(is.na(data[group_col])) > 0

    if (drop_na && any(na_mask)) {
        cli::cli_alert_info(
            "Dropped {sum(na_mask)} row{?s} with missing values in grouping
       column{?s} {.val {group_col}}."
        )
        data <- data[!na_mask, , drop = FALSE]
    }

    # -- 5. Build raw and sanitized composite grouping keys -----------------------
    # NA is coerced to the literal string "NA" before sanitizing, so that when
    # drop_na = FALSE, missing values form their own group instead of being
    # silently dropped by split() further down.
    raw_cols <- lapply(group_col, function(col) {
        val <- as.character(data[[col]])
        ifelse(is.na(val), "NA", val)
    })
    names(raw_cols) <- group_col

    sanitized_cols <- lapply(raw_cols, sanitize_filename)

    composite_sanitized <- do.call(paste, c(sanitized_cols, sep = "--"))
    composite_raw        <- do.call(paste, c(raw_cols, sep = " | "))

    # -- 6. Split row indices by the sanitized composite key -----------------------
    # Splitting on the already-sanitized key means only combinations actually
    # present in the data are realized (no unobserved-level cross-product),
    # and the split key doubles directly as the filename stem.
    row_index <- split(seq_len(nrow(data)), composite_sanitized)

    # -- 7. Write each group to CSV, assembling manifest rows ----------------------
    manifest_rows <- purrr::map(names(row_index), function(sanitized_key) {
        rows      <- row_index[[sanitized_key]]
        subset    <- data[rows, , drop = FALSE]
        first_row <- rows[[1]]

        file_path <- fs::path(output_dir, paste0(sanitized_key, ".csv"))
        readr::write_csv(subset, file_path)

        cli::cli_alert_success(
            "Written {.val {composite_raw[[first_row]]}} ({nrow(subset)} rows) to {.path {file_path}}"
        )

        if (length(group_col) == 1L) {
            # Single grouping column: manifest schema is byte-for-byte
            # unchanged from previous versions.
            tibble::tibble(
                group_value = raw_cols[[group_col]][[first_row]],
                n_rows      = nrow(subset),
                file_path   = as.character(file_path)
            )
        } else {
            row_data <- lapply(group_col, function(col) raw_cols[[col]][[first_row]])
            names(row_data) <- group_col
            row_data$group_value <- composite_raw[[first_row]]
            row_data$n_rows      <- nrow(subset)
            row_data$file_path   <- as.character(file_path)

            tibble::as_tibble(row_data)
        }
    })

    # -- 8. Write manifest if requested -----------------------------------------
    if (manifest) {
        manifest_df   <- purrr::list_rbind(manifest_rows)
        manifest_path <- fs::path(output_dir, "manifest.csv")
        readr::write_csv(manifest_df, manifest_path)
        cli::cli_alert_success("Manifest written to {.path {manifest_path}}")
    }

    invisible(output_dir)
}


# -- Helper: sanitize a string for use as a filename -------------------------

sanitize_filename <- function(x) {
    x |>
        tolower() |>
        gsub(pattern = "[^a-z0-9]+", replacement = "-", x = _) |>
        gsub(pattern = "^-+|-+$",    replacement = "",  x = _)
}
