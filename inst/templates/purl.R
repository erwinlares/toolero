# Post-render hook installed by toolero::create_qmd(). Purls only the
# .qmd files that (a) were actually rendered in this pass and (b) carry
# `purl: true` in their own YAML header -- so enabling this for one
# document in a larger project does not purl every other document that
# happens to render alongside it.
#
# Output paths under R/ mirror each source .qmd's path relative to the
# project root, rather than flattening to just the filename. This matters
# for a directory-per-post convention (posts/<slug>/index.qmd), where
# multiple documents legitimately share a basename -- flattening would
# have every one of them overwrite the last one purled into R/index.R.

.qmd_wants_purl <- function(path) {
    content <- gsub("\r\n", "\n", readr::read_file(path), fixed = TRUE)
    yaml_pattern <- "(?s)^---\\n(.+?)\\n---"
    m <- regmatches(content, regexpr(yaml_pattern, content, perl = TRUE))
    if (length(m) == 0) return(FALSE)
    isTRUE(yaml::yaml.load(m)[["purl"]])
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

if (length(qmd_files) > 0) {
    for (input in qmd_files) {
        # Mirror the source's path (relative to the project root) under
        # R/, rather than flattening to just its filename -- so
        # posts/2026-08-04-giscus/index.qmd purls to
        # R/posts/2026-08-04-giscus/index.R, not R/index.R, and two
        # documents that happen to share a filename in different
        # directories don't overwrite each other's output.
        output <- fs::path("R", fs::path_ext_set(input, "R"))
        fs::dir_create(fs::path_dir(output))
        knitr::purl(input, output = output, documentation = 1)
    }
}
