#' Split a data frame by a grouping column and write each group to a CSV file
#'
#' Splits a data frame by a single grouping column and writes each group to
#' a separate CSV file. Optionally writes a manifest file listing the output
#' files, their group values, and row counts.
#'
#' @param data A data frame or tibble to split and save.
#' @param group_col A string. The name of the column to group by.
#' @param output_dir A string or `NULL`. Path to the directory where output
#'   files will be written. Created if it does not exist. If `NULL`, the
#'   user must supply a path explicitly.
#' @param manifest A logical. Whether to write a `manifest.csv` file to
#'   `output_dir` listing the output files, group values, and row counts.
#'   Defaults to `FALSE`.
#'
#' @return Invisibly returns `output_dir`.
#'
#' @details
#' Output filenames are derived from the group values of `group_col`.
#' Values are sanitized before use as filenames: converted to lowercase,
#' spaces and special characters replaced with `_`, consecutive underscores
#' collapsed, and leading/trailing underscores stripped.
#'
#' If `manifest = TRUE`, a `manifest.csv` is written to `output_dir`
#' containing three columns: `group_value`, `n_rows`, and `file_path`.
#'
#' Note: `output_dir` has no default value. Always supply an explicit path
#' to avoid writing files to unexpected locations. Use `tempdir()` for
#' temporary output during testing or exploration.
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
#' }
write_by_group <- function(
        data,
        group_col,
        output_dir = NULL,
        manifest = FALSE) {

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

    # -- 2. Validate group_col --------------------------------------------------
    if (!group_col %in% names(data)) {
        cli::cli_abort(
            "Column {.val {group_col}} not found in {.arg data}.
       Available columns: {.val {names(data)}}."
        )
    }

    # -- 3. Create output_dir if needed -----------------------------------------
    fs::dir_create(output_dir)

    # -- 4. Split data by group_col ---------------------------------------------
    groups <- split(data, data[[group_col]])

    # -- 5 & 6. Sanitize names and write each group to CSV ----------------------
    manifest_rows <- purrr::map(names(groups), function(group_value) {
        sanitized <- sanitize_filename(group_value)
        file_path  <- fs::path(output_dir, paste0(sanitized, ".csv"))

        readr::write_csv(groups[[group_value]], file_path)
        cli::cli_alert_success(
            "Written {.val {group_value}} ({nrow(groups[[group_value]])} rows) to {.path {file_path}}"
        )

        tibble::tibble(
            group_value = group_value,
            n_rows      = nrow(groups[[group_value]]),
            file_path   = as.character(file_path)
        )
    })

    # -- 7. Write manifest if requested -----------------------------------------
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
        gsub(pattern = "[^a-z0-9]+", replacement = "_", x = _) |>
        gsub(pattern = "^_+|_+$",    replacement = "",  x = _)
}
