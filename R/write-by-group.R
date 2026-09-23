#' Split a data frame by one or more grouping columns and write each group to a CSV file
#'
#' Splits a data frame by one or more grouping columns and writes each group
#' to a separate CSV file. Optionally writes a job manifest listing the
#' output files, their group values, and row counts.
#'
#' @param data A data frame or tibble to split and save.
#' @param group_col A character vector. The name(s) of the column(s) to
#'   group by. When more than one column is supplied, groups are formed from
#'   the combinations of values actually present in the data (not the full
#'   cross-product of possible values).
#' @param output_dir A string or `NULL`. Path to the directory where output
#'   files will be written. Created if it does not exist. If `NULL`, resolved
#'   from `config`'s `split_dir` convention when `config` is supplied;
#'   otherwise the user must supply a path explicitly.
#' @param manifest A logical. Whether to write a `manifest.csv` file to
#'   `output_dir` listing the output files, group values, and row counts.
#'   Defaults to `FALSE`.
#' @param drop_na A logical. If `TRUE` (default), rows with a missing value
#'   in any grouping column are dropped before splitting, and a message
#'   reports how many rows were dropped and from which column(s). If
#'   `FALSE`, missing values are treated as their own group instead of
#'   being dropped.
#' @param prefix A string or `NULL`. An optional namespace prepended to every
#'   output filename, sanitized the same way group values are and joined with
#'   a single `-`. `prefix = "data"` grouping on one column turns `a.csv` into
#'   `data-a.csv`; grouping on two turns `a--female.csv` into
#'   `data-a--female.csv`. Defaults to `NULL`, which leaves filenames
#'   unchanged.
#' @param config A string or `NULL`. Path to a project configuration file
#'   (typically a project's own `_toolero.yml`, as written by
#'   [init_project()]). When supplied, and `output_dir` is not, `output_dir`
#'   defaults to the config's `split_dir` convention. An explicit `output_dir`
#'   always wins over `config`; `config` only fills in what you didn't
#'   supply. Defaults to `NULL`, which leaves today's behavior unchanged:
#'   `output_dir` must be supplied directly, config or no config. Placed last
#'   in the signature, along with `prefix`, so that adding either does not
#'   shift any existing positional argument.
#'
#' @return Invisibly returns `output_dir`.
#'
#' @details
#' Output filenames are derived from the group values of `group_col`. Each
#' value is sanitized independently: converted to lowercase, runs of
#' non-alphanumeric characters replaced with a single `-`, and
#' leading/trailing dashes stripped. When `group_col` has more than one
#' element, the sanitized values are joined with `--` in the order supplied,
#' so `group_col = c("species", "sex")` on an Adelie male produces
#' `adelie--male.csv`. A `prefix`, if supplied, is sanitized the same way and
#' joined to the front with a single `-`.
#'
#' @section Why the separators differ:
#' Because a run of non-alphanumeric characters collapses to exactly one
#' dash, a sanitized value can contain a single `-` but never two in a row.
#' That is what makes `--` safe between columns: it can only ever appear
#' where this function put it.
#'
#' The alternative would lose data rather than merely look untidy. Joined
#' with a single dash, the groups `("a-b", "c")` and `("a", "b-c")` both
#' produce the key `a-b-c`, and since the split is performed on that key the
#' two groups would be merged into one file and reported as one manifest
#' row. Joined with `--` they are `a-b--c` and `a--b-c`, and stay distinct.
#'
#' `prefix` is joined with a single `-` instead, because it is constant
#' across every file in a call and so cannot create a collision: prepending
#' the same string to two keys leaves them exactly as distinct as they were.
#' It is a namespace for the whole split rather than another field of the
#' group, and reads better as one.
#'
#' @section The job manifest:
#' If `manifest = TRUE`, a `manifest.csv` is written to `output_dir`. This is
#' the *job manifest*: a list of inputs to a computation that has not
#' happened yet, and the file consumed by [run_by_group()] and by
#' `submitr::htc_gen_submit()` in multiple-job mode. It is a different
#' document from the *project manifest* that [generate_manifest()] writes,
#' which records outputs from a computation that already has.
#'
#' The schema is one column per grouping variable, holding the raw
#' unsanitized value, followed by `group_value`, `n_rows`, and `file_path`.
#' Grouping on one column therefore produces a manifest whose first column
#' repeats `group_value` exactly. That redundancy is deliberate: one schema
#' with a varying column count is easier to read, validate and rely on than
#' two schemas selected by how many columns you happened to group on.
#'
#' `group_value` is a human-readable composite of the raw values joined by
#' `" | "`, so `"Adelie | male"` for two columns and simply `"Adelie"` for
#' one.
#'
#' @section Row order:
#' Groups are written, and manifest rows recorded, in order of first
#' appearance in `data`. This matters downstream: `submitr` writes its
#' `subdatasets.csv` in manifest order, HTCondor assigns `ProcId` in that
#' order, and log filenames are reconstructed from position, so manifest row
#' order is the mapping from a job number back to a group.
#'
#' @section Missing values:
#' With `drop_na = TRUE` (the default), rows with a missing value in any
#' grouping column are removed before splitting and a message reports how
#' many.
#'
#' With `drop_na = FALSE`, missing values are coerced to the string `"NA"` so
#' that they form their own group rather than being dropped silently by
#' `split()`. A column that also contains a literal `"NA"` value -- North
#' America, Not Applicable, a country code -- would then have two
#' semantically different groups collapse into one file. Rather than merge
#' them, `write_by_group()` aborts and names the column.
#'
#' Note: `output_dir` has no default value of its own. Supply it directly, or
#' supply `config` and let it resolve from the project's `split_dir`
#' convention. Use `tempdir()` for temporary output during testing or
#' exploration.
#'
#' @section Project conventions:
#' `config` is entirely opt-in. A project never scaffolded by [init_project()]
#' behaves exactly as before: pass `output_dir` and nothing about `config`
#' changes. When `config` is supplied but the file cannot be read, this
#' aborts with the same message [init_project()] gives for a bad `config`,
#' rather than silently falling back to a built-in default -- a config you
#' asked for and didn't get should never look identical to not asking.
#'
#' @seealso [run_by_group()], the apply half of this pair.
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
#' # Same but also write a job manifest
#' write_by_group(data, group_col = "species",
#'                output_dir = tempdir(), manifest = TRUE)
#'
#' # Namespace the filenames -- adelie.csv becomes penguins-adelie.csv
#' write_by_group(data, group_col = "species", prefix = "penguins",
#'                output_dir = tempdir())
#'
#' # Group by more than one column
#' data2 <- data.frame(
#'   species = c("Adelie", "Adelie", "Gentoo"),
#'   sex     = c("male", "female", "male"),
#'   mass    = c(3750, 3550, 5000)
#' )
#' write_by_group(data2, group_col = c("species", "sex"),
#'                output_dir = tempdir(), manifest = TRUE)
#'
#' # Let a project's own _toolero.yml supply output_dir via split_dir
#' write_by_group(data, group_col = "species", config = "_toolero.yml")
#' }
write_by_group <- function(
        data,
        group_col,
        output_dir = NULL,
        manifest = FALSE,
        drop_na = TRUE,
        prefix = NULL,
        config = NULL) {

    # -- 0. Resolve output_dir, from config's split_dir if not supplied ---------
    if (is.null(output_dir) && !is.null(config)) {
        resolved     <- .read_config_file(config, arg = "config")
        output_dir   <- resolved$conventions$split_dir
        cli::cli_inform("Using {.field split_dir} ({.val {output_dir}}) from {.path {config}}.")
    }

    if (is.null(output_dir)) {
        cli::cli_abort(
            "{.arg output_dir} must be supplied, or resolvable from {.arg config}.
       Use {.code tempdir()} for temporary output or provide an explicit path."
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

    # -- 3. Validate prefix -------------------------------------------------------
    prefix_key <- NULL

    if (!is.null(prefix)) {
        if (!is.character(prefix) || length(prefix) != 1L || is.na(prefix)) {
            cli::cli_abort(
                "{.arg prefix} must be a single, non-missing character string, or
         {.code NULL}."
            )
        }

        prefix_key <- .sanitize_filename(prefix)

        if (!nzchar(prefix_key)) {
            cli::cli_abort(c(
                "{.arg prefix} sanitizes to an empty string.",
                "x" = "Received {.val {prefix}}.",
                "i" = "A prefix must contain at least one letter or digit."
            ))
        }
    }

    # -- 4. Guard against the NA-versus-\"NA\" collision ----------------------------
    # Only reachable when drop_na = FALSE: missing values are coerced to the
    # string "NA" below so they form their own group, and a column holding a
    # literal "NA" would otherwise merge two different groups into one file.
    # With drop_na = TRUE the missing rows are gone before the coercion, so no
    # collision is possible.
    if (!drop_na) {
        collides <- vapply(group_col, function(col) {
            values <- data[[col]]
            anyNA(values) && any(as.character(values) == "NA", na.rm = TRUE)
        }, logical(1L))

        if (any(collides)) {
            offending <- group_col[collides]
            cli::cli_abort(c(
                "{length(offending)} grouping column{?s} contain{?s/} both missing
         values and the literal string {.val NA}: {.val {offending}}.",
                "x" = "Both would be written to the same file, silently merging two
           different groups.",
                "i" = "Use {.code drop_na = TRUE} to drop the missing rows, or recode
           the literal {.val NA} values to something distinguishable."
            ))
        }
    }

    # -- 5. Create output_dir if needed -----------------------------------------
    fs::dir_create(output_dir)

    # -- 6. Handle NA rows in grouping columns -----------------------------------
    na_mask <- rowSums(is.na(data[group_col])) > 0

    if (drop_na && any(na_mask)) {
        cli::cli_alert_info(
            "Dropped {sum(na_mask)} row{?s} with missing values in grouping
       column{?s} {.val {group_col}}."
        )
        data <- data[!na_mask, , drop = FALSE]
    }

    # -- 7. Build raw and sanitized composite grouping keys -----------------------
    # NA is coerced to the literal string "NA" before sanitizing, so that when
    # drop_na = FALSE, missing values form their own group instead of being
    # silently dropped by split() further down. Step 4 has already established
    # that no column holds both a missing value and a literal "NA".
    raw_cols <- lapply(group_col, function(col) {
        val <- as.character(data[[col]])
        ifelse(is.na(val), "NA", val)
    })
    names(raw_cols) <- group_col

    sanitized_cols <- lapply(raw_cols, .sanitize_filename)

    composite_sanitized <- do.call(paste, c(sanitized_cols, sep = "--"))
    composite_raw        <- do.call(paste, c(raw_cols, sep = " | "))

    # -- 8. Split row indices by the sanitized composite key -----------------------
    # Splitting on the already-sanitized key means only combinations actually
    # present in the data are realized (no unobserved-level cross-product),
    # and the split key doubles directly as the filename stem.
    #
    # split() returns groups in sort order of the key. Reordering by the first
    # row each group occupies puts them back in the order they appear in the
    # data, which is both what a reader expects and what downstream job
    # numbering is derived from.
    row_index <- split(seq_len(nrow(data)), composite_sanitized)
    row_index <- row_index[order(vapply(row_index, min, integer(1L)))]

    # -- 9. Write each group to CSV, assembling manifest rows ----------------------
    manifest_rows <- purrr::map(names(row_index), function(sanitized_key) {
        rows      <- row_index[[sanitized_key]]
        subset    <- data[rows, , drop = FALSE]
        first_row <- rows[[1]]

        file_stem <- if (is.null(prefix_key)) {
            sanitized_key
        } else {
            paste0(prefix_key, "-", sanitized_key)
        }

        file_path <- fs::path(output_dir, paste0(file_stem, ".csv"))
        readr::write_csv(subset, file_path)

        cli::cli_alert_success(
            "Written {.val {composite_raw[[first_row]]}} ({nrow(subset)} rows) to {.path {file_path}}"
        )

        # One manifest schema regardless of how many grouping columns were
        # supplied: one column per grouping variable holding the raw value,
        # then group_value, n_rows, file_path. For a single grouping column
        # the first column repeats group_value, which is the price of not
        # having two schemas to tell apart.
        row_data <- lapply(group_col, function(col) raw_cols[[col]][[first_row]])
        names(row_data) <- group_col

        row_data$group_value <- composite_raw[[first_row]]
        row_data$n_rows      <- nrow(subset)
        row_data$file_path   <- as.character(file_path)

        tibble::as_tibble(row_data)
    })

    # -- 10. Write manifest if requested -----------------------------------------
    if (manifest) {
        manifest_df   <- purrr::list_rbind(manifest_rows)
        manifest_path <- fs::path(output_dir, "manifest.csv")
        readr::write_csv(manifest_df, manifest_path)
        cli::cli_alert_success("Manifest written to {.path {manifest_path}}")
    }

    invisible(output_dir)
}


# -- Helper: sanitize a string for use as a filename -------------------------

#' Sanitize a string for use in a filename
#'
#' Lowercases, replaces every run of non-alphanumeric characters with a
#' single `-`, and strips leading and trailing dashes.
#'
#' The collapsing is what the rest of [write_by_group()]'s filename scheme
#' rests on: because a run of separators becomes exactly one dash, a
#' sanitized value can contain a single `-` but never two consecutive ones.
#' That leaves `--` free to mark the boundary between grouping columns
#' without any possibility of colliding with content.
#'
#' Not exported. Confirmed as internal-only against the package's own
#' `NAMESPACE` (0.5.1.9000) rather than assumed: nothing outside
#' [write_by_group()], the only place that calls it, needs this directly.
#'
#' @param x A character vector.
#'
#' @return A character vector of the same length.
#'
#' @keywords internal
.sanitize_filename <- function(x) {
    x |>
        tolower() |>
        gsub(pattern = "[^a-z0-9]+", replacement = "-", x = _) |>
        gsub(pattern = "^-+|-+$",    replacement = "",  x = _)
}
