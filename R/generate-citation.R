# R/generate-citation.R

#' Split a full name into given and family names
#'
#' Internal helper used by [generate_citation()] to fill the
#' `given-names`/`family-names` fields the Citation File Format requires,
#' from the single `name` field a profile's `author:` block carries (the
#' same field Quarto's own author schema uses).
#'
#' The split is the last space in the string: everything after it is the
#' family name, everything before it is the given name(s). This is right
#' for the common case and wrong for some real names -- multi-word family
#' names ("van der Berg"), single-word names, and family-name-first
#' orderings all defeat it. [generate_citation()] flags this in its own
#' message rather than pretending the split is reliable.
#'
#' @param name Character. A single full name, e.g. `"Erwin Lares"`.
#'
#' @return A named list with elements `given` and `family`, both character.
#'
#' @keywords internal
.split_personal_name <- function(name) {
    parts <- trimws(strsplit(name, "\\s+")[[1]])

    if (length(parts) <= 1L) {
        return(list(given = "", family = if (length(parts) == 1L) parts else ""))
    }

    list(
        given  = paste(parts[-length(parts)], collapse = " "),
        family = parts[[length(parts)]]
    )
}

#' Normalize an ORCID to CFF's full-URL form
#'
#' Internal helper used by [generate_citation()]. A profile written by
#' [generate_profile()] stores a bare ORCID (`"0000-0000-0000-0000"`),
#' matching Quarto's own author schema, but the Citation File Format
#' expects the full URL. Returns `orcid` unchanged if it already looks like
#' a URL.
#'
#' @param orcid Character. A bare ORCID iD or a full ORCID URL.
#'
#' @return A single character string, the full `https://orcid.org/...` URL.
#'
#' @keywords internal
.normalize_orcid <- function(orcid) {
    if (grepl("^https?://", orcid)) {
        return(orcid)
    }
    paste0("https://orcid.org/", orcid)
}

#' Render one CFF author entry
#'
#' Internal helper used by [generate_citation()] to render a single
#' `authors:` list item from one entry of a profile's `author:` block (or
#' from a generic placeholder when no profile was supplied).
#'
#' @param author A named list, typically one element of a profile's
#'   `author:` field, with any of `name`, `affiliation`, `orcid`, `email`.
#'   Missing fields are simply omitted from the rendered block.
#'
#' @return A character vector of YAML lines, indented as a single
#'   `authors:` sequence item.
#'
#' @keywords internal
.cff_author_block <- function(author) {
    name_parts <- .split_personal_name(author$name %||% "Your Name")

    lines <- c(
        paste0("  - family-names: \"", name_parts$family, "\""),
        paste0("    given-names: \"", name_parts$given, "\"")
    )

    if (!is.null(author$orcid) && nzchar(author$orcid)) {
        lines <- c(lines, paste0("    orcid: \"", .normalize_orcid(author$orcid), "\""))
    }

    if (!is.null(author$affiliation) && nzchar(author$affiliation)) {
        lines <- c(lines, paste0("    affiliation: \"", author$affiliation, "\""))
    }

    if (!is.null(author$email) && nzchar(author$email)) {
        lines <- c(lines, paste0("    email: \"", author$email, "\""))
    }

    lines
}

#' Generate a CITATION.cff file
#'
#' Writes a Citation File Format (`CITATION.cff`) skeleton, optionally
#' pre-filled with author information from a profile written by
#' [generate_profile()], so a project's citation metadata doesn't mean
#' retyping the same name, affiliation, and ORCID a third time.
#'
#' @param filename Character. Name of the file to write. Defaults to
#'   `"CITATION.cff"`, the name tools that read this format expect;
#'   changing it means those tools will not find the file automatically.
#' @param path Character. Directory to write the file into. Defaults to
#'   `"."` (the current working directory), matching the rest of the
#'   family's project-scaffolding functions.
#' @param profile Character or `NULL`. Path to a profile file, typically
#'   one written by [generate_profile()]. When supplied, every entry in the
#'   profile's `author:` block becomes an author entry in the generated
#'   file. When `NULL` (the default), a single generic placeholder author
#'   is written instead.
#' @param overwrite Logical. When `FALSE` (default), an existing file at
#'   the destination is an error rather than being replaced.
#'
#' @return The path to the written file, invisibly.
#'
#' @details
#' `title`, `version`, `repository-code`, `url`, and `license` are project
#' facts a personal profile has no way to know, so they are left as
#' placeholders (some commented out) regardless of `profile`. `date-released`
#' is filled in with today's date, since that much is always knowable at
#' generation time; edit it later if the actual release date differs.
#'
#' The given-names/family-names split needed by the Citation File Format is
#' done by splitting a profile's single `name` field on its last space,
#' which is right for the ordinary case and wrong for some real names.
#' Review the generated file's `given-names`/`family-names` fields before
#' relying on them, especially for a multi-word family name.
#'
#' @seealso [generate_profile()], the function that writes the file this
#'   one can read from.
#'
#' @examples
#' \donttest{
#' generate_citation(path = tempdir())
#'
#' profile_file <- tempfile(fileext = ".yml")
#' writeLines(
#'   'author:\n  - name: "Erwin Lares"\n    affiliation: "RCI, UW-Madison"\n    orcid: "0000-0002-3284-828X"',
#'   profile_file
#' )
#' generate_citation(path = tempdir(), profile = profile_file, overwrite = TRUE)
#' }
#'
#' @export
generate_citation <- function(filename = "CITATION.cff",
                              path = ".",
                              profile = NULL,
                              overwrite = FALSE) {

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
       Use {.code overwrite = TRUE} to replace it."
        )
    }

    authors <- list(list(
        name = "Your Name",
        affiliation = "Your Institution",
        orcid = "0000-0000-0000-0000"
    ))

    used_profile <- FALSE

    if (!is.null(profile)) {
        if (!fs::file_exists(profile)) {
            cli::cli_abort("profile file {.path {profile}} does not exist.")
        }

        parsed <- yaml::read_yaml(profile)

        if (!is.null(parsed$author) && length(parsed$author) > 0L) {
            authors <- parsed$author
            used_profile <- TRUE
        } else {
            cli::cli_warn(c(
                "!" = "{.path {profile}} has no {.field author} field.",
                "i" = "Writing a generic placeholder author instead."
            ))
        }
    }

    author_lines <- unlist(lapply(authors, .cff_author_block))

    template <- readLines(.package_template("CITATION.cff"), warn = FALSE)

    # {{authors}} occupies a line of its own, like _toolero.yml's own
    # {{folders}}/{{conventions}} placeholders, so .substitute_block() (a
    # whole-line replacement) applies directly. {{date_released}} instead
    # sits inline within date-released: "{{date_released}}", so it is
    # substituted with a plain string replacement, not a block one.
    out <- .substitute_block(template, "{{authors}}", author_lines)
    out <- gsub("{{date_released}}", format(Sys.Date()), out, fixed = TRUE)

    writeLines(out, dest)

    cli::cli_inform(c(
        "v" = "Wrote {.path {dest}}.",
        if (used_profile) {
            c("i" = "Author information came from {.path {profile}} -- double-check the given-names/family-names split.")
        } else {
            c("i" = "Wrote a placeholder author -- edit {.path {dest}} directly, or supply {.arg profile}.")
        },
        "i" = "Fill in {.field title} and, when they're true of this project, the commented-out fields."
    ))

    invisible(dest)
}
