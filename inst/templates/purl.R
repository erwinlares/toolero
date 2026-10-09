# Post-render hook installed by toolero::create_qmd(). Purls only the
# .qmd files that (a) were actually rendered in this pass and (b) carry
# `purl: true` in their own YAML header -- so enabling this for one
# document in a larger project does not purl every other document that
# happens to render alongside it.
#
# Where the script lands under R/ depends on the kind of project. In an
# ordinary project it is flat: reports/analysis.qmd purls to
# R/analysis.R. In a Quarto website or book, where documents routinely
# share a filename (posts/<slug>/index.qmd), the script mirrors the
# document's path relative to the project root, so
# posts/<slug>/index.qmd purls to R/posts/<slug>/index.R and no document
# overwrites another's output. The kind of project is read from
# `project: type:` in _quarto.yml.
#
# Every script starts with a line naming the document it came from. In
# the flat layout the hook uses that line to avoid overwriting a file it
# did not write: a hand-written R/analysis.R, or one generated from a
# different document that has the same filename. A script whose named
# document no longer exists (because it was moved or renamed) is stale,
# not someone else's, and is replaced.

.qmd_wants_purl <- function(path) {
    content <- gsub("\r\n", "\n", readr::read_file(path), fixed = TRUE)
    yaml_pattern <- "(?s)^---\\n(.+?)\\n---"
    m <- regmatches(content, regexpr(yaml_pattern, content, perl = TRUE))
    if (length(m) == 0) return(FALSE)
    isTRUE(yaml::yaml.load(m)[["purl"]])
}

# "mirror" for a Quarto website or book, "flat" for everything else,
# including a project with no _quarto.yml, or one with no `type:`.
.purl_layout <- function() {
    quarto_yml <- c("_quarto.yml", "_quarto.yaml")
    quarto_yml <- quarto_yml[file.exists(quarto_yml)]
    if (length(quarto_yml) == 0L) return("flat")

    config <- tryCatch(yaml::read_yaml(quarto_yml[[1L]]), error = function(cnd) NULL)
    if (!is.list(config)) return("flat")

    type <- config[["project"]][["type"]]
    if (is.character(type) && length(type) == 1L && type %in% c("website", "book")) {
        "mirror"
    } else {
        "flat"
    }
}

# The first line of every purled script.
.purl_marker <- function(input) {
    paste0(
        "# Generated from ", input, " by R/purl.R. Edit that document, ",
        "not this file; changes made here are overwritten at the next render."
    )
}

# Which document an existing script says it was generated from.
# NA: the file does not exist. "": it exists but carries no marker, so
# something other than this hook wrote it.
.purl_source_of <- function(output) {
    if (!file.exists(output)) return(NA_character_)
    first <- readLines(output, n = 1L, warn = FALSE)
    if (length(first) == 0L) return("")
    found <- regmatches(first, regexec("^# Generated from (.+) by R/purl[.]R[.]", first))[[1L]]
    if (length(found) == 2L) found[[2L]] else ""
}

output_files <- Sys.getenv("QUARTO_PROJECT_OUTPUT_FILES")
output_dir   <- Sys.getenv("QUARTO_PROJECT_OUTPUT_DIR")

if (identical(output_files, "")) {
    # Not running as an actual Quarto post-render script (e.g. sourced
    # by hand while testing) -- fall back to scanning the project root,
    # still filtered by the purl: true header check below. Recursive,
    # so a manual/local run over a nested project (posts/<slug>/index.qmd)
    # finds the same documents a real render would, via
    # QUARTO_PROJECT_OUTPUT_FILES, in the branch below. Everything
    # dir_ls() finds already exists by construction, so the missing-
    # source case below cannot occur on this branch. Relativize to the
    # project root so output paths mirror source paths the same way as
    # the QUARTO_PROJECT_OUTPUT_FILES branch below.
    qmd_candidates <- fs::path_rel(
        fs::dir_ls(getwd(), recurse = TRUE, glob = "*.qmd"),
        start = getwd()
    )
} else {
    output_files <- strsplit(output_files, "\n", fixed = TRUE)[[1]]

    # Output paths are relative to the project root and, for
    # website/book/manuscript projects, nested under output-dir (e.g.
    # "_site/"). Strip that prefix so the path lines up with the source
    # .qmd's location relative to the project root.
    if (nzchar(output_dir)) {
        output_files <- fs::path_rel(output_files, start = output_dir)
    }

    qmd_candidates <- fs::path_ext_set(output_files, "qmd")

    # A rendered output with no matching source .qmd isn't necessarily
    # wrong -- a document with its own output-file: override in YAML
    # will land here every time, by design, not by mistake. Report it
    # quietly (cli_inform(), not cli_warn()) so a legitimate override
    # doesn't produce a warning on every render.
    missing <- qmd_candidates[!fs::file_exists(qmd_candidates)]
    if (length(missing) > 0) {
        cli::cli_inform(
            "Could not find a source {.file .qmd} for {length(missing)}
       rendered output{?s}: {.path {missing}}. Skipping."
        )
    }

    qmd_candidates <- qmd_candidates[fs::file_exists(qmd_candidates)]
}

qmd_files <- qmd_candidates[vapply(qmd_candidates, .qmd_wants_purl, logical(1))]

layout <- .purl_layout()

if (length(qmd_files) > 0) {
    for (input in qmd_files) {
        input <- as.character(input)

        if (identical(layout, "mirror")) {
            # Website or book: mirror the source's path (relative to the
            # project root) under R/, so posts/2026-08-04-giscus/index.qmd
            # purls to R/posts/2026-08-04-giscus/index.R, not R/index.R,
            # and documents that share a filename in different
            # directories don't overwrite each other's output.
            output <- fs::path("R", fs::path_ext_set(input, "R"))
        } else {
            # Ordinary project: reports/analysis.qmd purls to
            # R/analysis.R. Leave alone any file at that path that was
            # not generated from this document.
            output <- fs::path("R", fs::path_ext_set(fs::path_file(input), "R"))

            source_doc <- .purl_source_of(output)
            orphaned   <- !is.na(source_doc) && nzchar(source_doc) &&
                !identical(source_doc, input) && !file.exists(source_doc)

            if (orphaned) {
                cli::cli_inform(
                    "Replacing {.file {output}}: it was generated from {.file {source_doc}}, which no longer exists."
                )
            } else if (!is.na(source_doc) && !identical(source_doc, input)) {
                why <- if (nzchar(source_doc)) {
                    "It was generated from {.file {source_doc}}, which still exists. Rename one of the two documents so each has its own script."
                } else {
                    "It has no {.code Generated from} line, so it looks hand-written. Move it, or rename the document."
                }
                cli::cli_warn(c(
                    "!" = "Not purling {.file {input}}: {.file {output}} already exists and was not generated from it.",
                    "i" = why
                ))
                next
            }
        }

        fs::dir_create(fs::path_dir(output))
        knitr::purl(input, output = output, documentation = 1)

        script <- readLines(output, warn = FALSE, encoding = "UTF-8")
        writeLines(c(.purl_marker(input), script), output, useBytes = TRUE)
    }
}
