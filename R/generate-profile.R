# R/generate-profile.R

#' Generate a personal defaults file for create_qmd()
#'
#' Writes a YAML skeleton, pre-filled with placeholders and explanatory
#' comments, covering the author information and formatting preferences
#' that tend to be identical across every document you create with
#' [create_qmd()]. Edit the result with your own values, then pass its path
#' to `create_qmd(header_defaults = )` instead of retyping the same author
#' block and format options on every call.
#'
#' @param filename Character. Name of the file to write, e.g.
#'   `"profile.yml"` or a personal name like `"erwinlares.yml"`. Must be
#'   supplied explicitly -- there is no default, so that keeping more than
#'   one profile (a personal one and a work one, say) under different
#'   filenames is a normal thing to do, not a workaround.
#' @param path Character. Directory to write the file into. Defaults to
#'   the user's home directory (`fs::path_home()`), not `"."` -- unlike
#'   [generate_project_config()], this file's whole purpose is being
#'   reusable across every project rather than tied to one, so it belongs
#'   somewhere that outlives any single project directory. Pass `path = "."`
#'   if you'd rather keep a copy inside a specific project instead.
#' @param overwrite Logical. When `FALSE` (default), an existing file at
#'   the destination is an error rather than being replaced.
#'
#' @return The path to the written file, invisibly.
#'
#' @details
#' The written file has two sections. Personal information becomes the
#' document's `author:` block: name, affiliation, ORCID, email, and a
#' website URL, the fields Quarto's default HTML title block already knows
#' how to render. Document settings covers the recurring, non-personal
#' choices `create_qmd()` doesn't otherwise remember for you: `date`/
#' `date-modified`, `categories`, `lang`, `execute` options for quiet and
#' reproducible rendering, and a `format: html:` block of layout
#' preferences. Neither section touches `css`, `include-before-body`, or
#' `include-after-body` -- those are [create_qmd()]'s `use_style` argument's
#' job, reading from a project's own `assets/` folder, and a profile that
#' also tried to set them would collide with a specific project's branding
#' rather than complementing it.
#'
#' The file is a plain copy of the packaged template, not a form filled in
#' programmatically -- this function does not prompt for values. Open the
#' written file, replace the placeholder values with your own, and delete
#' any key you don't want pre-filled; `create_qmd()` leaves a deleted key's
#' template placeholder untouched.
#'
#' A phone number and mailing address are deliberately not among the
#' placeholders. Documents built from this file are the kind that tend to
#' get rendered to HTML and published, and neither belongs in something
#' public.
#'
#' @seealso [create_qmd()], whose `header_defaults` argument reads the file
#'   this writes; [generate_citation()], which can also draw on it.
#'
#' @examples
#' \donttest{
#' generate_profile("my-profile.yml", path = tempdir())
#' }
#'
#' @export
generate_profile <- function(filename, path = fs::path_home(), overwrite = FALSE) {

    if (missing(filename) || is.null(filename)) {
        cli::cli_abort(
            "{.arg filename} must be supplied, e.g. {.code filename = \"profile.yml\"}."
        )
    }

    if (!rlang::is_string(filename)) {
        cli::cli_abort(c(
            "{.arg filename} must be a single character string.",
            "x" = "Received {.obj_type_friendly {filename}} of length {length(filename)}."
        ))
    }

    if (!fs::dir_exists(path)) {
        cli::cli_abort(
            "Directory {.path {path}} does not exist.
       Create it first or choose an existing path."
        )
    }

    dest <- fs::path(path, filename)

    if (fs::file_exists(dest) && !overwrite) {
        cli::cli_abort(
            "{.path {dest}} already exists.
       Use {.code overwrite = TRUE} to replace it, or choose a different
       {.arg filename} to keep more than one profile."
        )
    }

    src <- .package_template("profile.yml")
    fs::file_copy(src, dest, overwrite = overwrite)

    cli::cli_inform(c(
        "v" = "Wrote {.path {dest}}.",
        "i" = "Open it and replace the placeholder values with your own.",
        "i" = "Then pass it to {.fn create_qmd} as {.code header_defaults = \"{dest}\"}."
    ))

    invisible(dest)
}
