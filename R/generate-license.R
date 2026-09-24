#' Generate a LICENSE file
#'
#' Writes a plain-text `LICENSE` file at the project root, using one of a
#' small set of common license templates with the copyright holder and year
#' filled in.
#'
#' Note that this is different from how an R package normally carries a
#' license. A package's `DESCRIPTION` declares `License: MIT + file LICENSE`
#' and pairs a two-line CRAN stub (`LICENSE`) with the full text in a
#' separate `LICENSE.md`. The projects [init_project()] scaffolds are
#' research compendia, not packages -- there is no `DESCRIPTION` to
#' reference a license from -- so `generate_license()` instead writes one
#' self-contained file carrying the license text directly, the way a plain
#' GitHub repository does.
#'
#' @param license A character string. One of `"MIT"`, `"CC0"`, or `"GPL-3"`.
#'   Only this small, common set is supported; write a `LICENSE` file by
#'   hand for anything else. Defaults to `"MIT"`.
#' @param holder A character string. The copyright holder -- a person or an
#'   institution. Must be supplied explicitly; there is no default, since
#'   guessing it wrong is worse than asking.
#' @param year A character string. The copyright year. Defaults to the
#'   current year.
#' @param path A character string. Directory in which to write the file.
#'   Defaults to `"."` (the current working directory).
#' @param overwrite Logical. If `TRUE`, overwrites an existing `LICENSE`
#'   file at the same location. Defaults to `FALSE`.
#'
#' @section GPL-3:
#' The GNU General Public License's full text runs to several hundred
#' lines. Rather than risk an inaccurate transcription of it,
#' `license = "GPL-3"` writes the license notice the Free Software
#' Foundation itself recommends attaching to a program, together with a
#' link to the canonical full text at
#' <https://www.gnu.org/licenses/gpl-3.0.txt>. `"MIT"` and `"CC0"` are both
#' short enough to reproduce here in full, and are written that way.
#'
#' @return Invisibly returns the full path to the written file.
#' @seealso [init_project()], [generate_data_doc()]
#' @export
#'
#' @examples
#' \dontrun{
#' generate_license(license = "MIT", holder = "Jane Researcher")
#'
#' generate_license(license = "CC0", holder = "Example Lab",
#'                   path = "~/Documents/my-project")
#' }
generate_license <- function(license   = "MIT",
                             holder    = NULL,
                             year      = format(Sys.Date(), "%Y"),
                             path      = ".",
                             overwrite = FALSE) {

    # -- 1. Validate license ---------------------------------------------------
    valid_licenses <- c("MIT", "CC0", "GPL-3")
    if (length(license) != 1L || !license %in% valid_licenses) {
        cli::cli_abort(c(
            "{.arg license} must be one of {.val {valid_licenses}}, not {.val {license}}.",
            "i" = "Only a small, common set is supported; write a LICENSE file by
                   hand for anything else."
        ))
    }

    # -- 2. Validate holder ------------------------------------------------
    if (is.null(holder) || !is.character(holder) ||
        length(holder) != 1L || !nzchar(holder)) {
        cli::cli_abort(
            "{.arg holder} must be supplied, e.g. {.code holder = \"Jane Researcher\"}."
        )
    }

    # -- 3. Validate path -------------------------------------------------
    if (!fs::dir_exists(path)) {
        cli::cli_abort(c(
            "{.path {path}} does not exist.",
            "i" = "Create the project first, e.g. with {.fn init_project}."
        ))
    }

    # -- 4. Resolve destination -------------------------------------------
    dest <- fs::path_abs(fs::path(path, "LICENSE"))

    # -- 5. Guard against overwriting --------------------------------------
    if (fs::file_exists(dest) && !overwrite) {
        cli::cli_abort(c(
            "{.path {dest}} already exists.",
            "i" = "Use {.code overwrite = TRUE} to replace it."
        ))
    }

    # -- 6. Fill in the template and write ----------------------------------
    writeLines(.license_text(license, holder, year), dest)

    cli::cli_alert_success("Created {.path {dest}}")
    cli::cli_inform(c(
        "i" = "If this project is later turned into a package or shared
               publicly, record the same license in its {.file DESCRIPTION}
               or {.file README} as well."
    ))

    invisible(dest)
}


# -- Helper: fill in a license template ----------------------------------------

#' Fill in a license template
#'
#' Internal helper backing [generate_license()]. Returns the full text of
#' one of a small set of common license templates, with the holder and
#' year substituted in.
#'
#' @param license A character string. One of `"MIT"`, `"CC0"`, `"GPL-3"`.
#' @param holder A character string. The copyright holder.
#' @param year A character string. The copyright year.
#'
#' @return A character vector, one element per line.
#'
#' @keywords internal
.license_text <- function(license, holder, year) {
    switch(license,
           "MIT" = c(
               "MIT License",
               "",
               paste0("Copyright (c) ", year, " ", holder),
               "",
               "Permission is hereby granted, free of charge, to any person obtaining a copy",
               "of this software and associated documentation files (the \"Software\"), to",
               "deal in the Software without restriction, including without limitation the",
               "rights to use, copy, modify, merge, publish, distribute, sublicense, and/or",
               "sell copies of the Software, and to permit persons to whom the Software is",
               "furnished to do so, subject to the following conditions:",
               "",
               "The above copyright notice and this permission notice shall be included in",
               "all copies or substantial portions of the Software.",
               "",
               "THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR",
               "IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,",
               "FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE",
               "AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER",
               "LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING",
               "FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS",
               "IN THE SOFTWARE."
           ),
           "CC0" = c(
               paste0("Copyright (c) ", year, " ", holder),
               "",
               "To the extent possible under law, the person who associated CC0 with this",
               "work has waived all copyright and related or neighboring rights to this",
               "work.",
               "",
               "This work is dedicated to the public domain under the Creative Commons",
               "CC0 1.0 Universal Public Domain Dedication. To view a copy of this",
               "dedication, visit https://creativecommons.org/publicdomain/zero/1.0/"
           ),
           "GPL-3" = c(
               paste0("Copyright (c) ", year, " ", holder),
               "",
               "This program is free software: you can redistribute it and/or modify",
               "it under the terms of the GNU General Public License as published by",
               "the Free Software Foundation, either version 3 of the License, or",
               "(at your option) any later version.",
               "",
               "This program is distributed in the hope that it will be useful,",
               "but WITHOUT ANY WARRANTY; without even the implied warranty of",
               "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the",
               "GNU General Public License for more details.",
               "",
               "You should have received a copy of the GNU General Public License",
               "along with this program. If not, see <https://www.gnu.org/licenses/>.",
               "",
               "The full text of the license is available at",
               "https://www.gnu.org/licenses/gpl-3.0.txt"
           )
    )
}
