# tests/testthat/test-generate-citation.R

# -- helpers ----------------------------------------------------------------------

make_profile <- function(path, authors) {
    yaml::write_yaml(list(author = authors), path)
    path
}

single_author <- list(list(
    name        = "Erwin Lares",
    affiliation = "RCI, UW-Madison",
    orcid       = "0000-0002-3284-828X",
    email       = "erwin.lares@wisc.edu"
))

# -- .split_personal_name() --------------------------------------------------------

test_that(".split_personal_name() splits a two-word name on the last space", {
    result <- .split_personal_name("Erwin Lares")

    expect_equal(result$given, "Erwin")
    expect_equal(result$family, "Lares")
})

test_that(".split_personal_name() puts every word but the last into given", {
    result <- .split_personal_name("Erwin Alexander Lares")

    expect_equal(result$given, "Erwin Alexander")
    expect_equal(result$family, "Lares")
})

test_that(".split_personal_name() treats a single-word name as family only", {
    result <- .split_personal_name("Cher")

    expect_equal(result$given, "")
    expect_equal(result$family, "Cher")
})

test_that(".split_personal_name() collapses repeated internal whitespace", {
    result <- .split_personal_name("Erwin   Lares")

    expect_equal(result$given, "Erwin")
    expect_equal(result$family, "Lares")
})

# -- .normalize_orcid() ------------------------------------------------------------

test_that(".normalize_orcid() prefixes a bare ORCID with the full URL", {
    expect_equal(
        .normalize_orcid("0000-0002-3284-828X"),
        "https://orcid.org/0000-0002-3284-828X"
    )
})

test_that(".normalize_orcid() leaves an already-full URL unchanged", {
    full <- "https://orcid.org/0000-0002-3284-828X"
    expect_equal(.normalize_orcid(full), full)
})

test_that(".normalize_orcid() recognizes an http URL as already full", {
    full <- "http://orcid.org/0000-0002-3284-828X"
    expect_equal(.normalize_orcid(full), full)
})

# -- .cff_author_block() -----------------------------------------------------------

test_that(".cff_author_block() renders name, affiliation, orcid and email", {
    lines <- .cff_author_block(single_author[[1L]])
    block <- paste(lines, collapse = "\n")

    expect_true(grepl("family-names: \"Lares\"", block, fixed = TRUE))
    expect_true(grepl("given-names: \"Erwin\"", block, fixed = TRUE))
    expect_true(grepl("orcid: \"https://orcid.org/0000-0002-3284-828X\"", block, fixed = TRUE))
    expect_true(grepl("affiliation: \"RCI, UW-Madison\"", block, fixed = TRUE))
    expect_true(grepl("email: \"erwin.lares@wisc.edu\"", block, fixed = TRUE))
})

test_that(".cff_author_block() omits fields that are absent", {
    lines <- .cff_author_block(list(name = "Cher"))
    block <- paste(lines, collapse = "\n")

    expect_true(grepl("family-names: \"Cher\"", block, fixed = TRUE))
    expect_false(grepl("orcid:", block, fixed = TRUE))
    expect_false(grepl("affiliation:", block, fixed = TRUE))
    expect_false(grepl("email:", block, fixed = TRUE))
})

test_that(".cff_author_block() falls back to a placeholder name when name is absent", {
    # "Your Name" is split on its last space like any other name, so the
    # literal two-word string never appears together -- it comes out as
    # family-names "Name" and given-names "Your" on separate lines.
    lines <- .cff_author_block(list(affiliation = "Somewhere"))
    block <- paste(lines, collapse = "\n")

    expect_true(grepl("family-names: \"Name\"", block, fixed = TRUE))
    expect_true(grepl("given-names: \"Your\"", block, fixed = TRUE))
})

# -- input validation ---------------------------------------------------------------

test_that("errors when filename is not a single string", {
    tmp <- withr::local_tempdir()

    expect_error(
        generate_citation(filename = c("a.cff", "b.cff"), path = tmp),
        "single character string"
    )
})

test_that("errors when path does not exist", {
    expect_error(
        generate_citation(path = "/no/such/directory"),
        "does not exist"
    )
})

test_that("errors when the destination already exists and overwrite = FALSE", {
    tmp <- withr::local_tempdir()
    generate_citation(path = tmp)

    expect_error(
        generate_citation(path = tmp),
        "already exists"
    )
})

test_that("errors when profile does not exist", {
    tmp <- withr::local_tempdir()

    expect_error(
        generate_citation(path = tmp, profile = "/no/such/profile.yml"),
        "does not exist"
    )
})

# -- writing behavior, no profile ---------------------------------------------------

test_that("writes CITATION.cff by default", {
    tmp <- withr::local_tempdir()
    generate_citation(path = tmp)

    expect_true(fs::file_exists(fs::path(tmp, "CITATION.cff")))
})

test_that("returns the destination path invisibly", {
    tmp <- withr::local_tempdir()
    expect_invisible(generate_citation(path = tmp))
})

test_that("honours a custom filename", {
    tmp <- withr::local_tempdir()
    generate_citation(filename = "citation.cff", path = tmp)

    expect_true(fs::file_exists(fs::path(tmp, "citation.cff")))
})

test_that("overwrite = TRUE replaces an existing file", {
    tmp <- withr::local_tempdir()
    generate_citation(path = tmp)
    readr::write_file("sentinel", fs::path(tmp, "CITATION.cff"))

    generate_citation(path = tmp, overwrite = TRUE)

    content <- readr::read_file(fs::path(tmp, "CITATION.cff"))
    expect_false(identical(content, "sentinel"))
})

test_that("writes a generic placeholder author when no profile is supplied", {
    tmp <- withr::local_tempdir()
    generate_citation(path = tmp)

    # "Your Name" is split into family-names/given-names like any other
    # name, so it never appears as a contiguous string in the output.
    content <- readr::read_file(fs::path(tmp, "CITATION.cff"))
    expect_true(grepl("family-names: \"Name\"", content, fixed = TRUE))
    expect_true(grepl("given-names: \"Your\"", content, fixed = TRUE))
})

test_that("fills in today's date as date-released", {
    tmp <- withr::local_tempdir()
    generate_citation(path = tmp)

    content <- readr::read_file(fs::path(tmp, "CITATION.cff"))
    expect_true(grepl(format(Sys.Date()), content, fixed = TRUE))
    expect_false(grepl("{{date_released}}", content, fixed = TRUE))
})

test_that("substitutes the {{authors}} placeholder rather than leaving it literal", {
    tmp <- withr::local_tempdir()
    generate_citation(path = tmp)

    content <- readr::read_file(fs::path(tmp, "CITATION.cff"))
    expect_false(grepl("{{authors}}", content, fixed = TRUE))
})

test_that("the written file has required top-level CFF fields", {
    tmp <- withr::local_tempdir()
    generate_citation(path = tmp)

    content <- readr::read_file(fs::path(tmp, "CITATION.cff"))
    expect_true(grepl("cff-version:", content, fixed = TRUE))
    expect_true(grepl("(?m)^authors:", content, perl = TRUE))
})

# -- writing behavior, with profile --------------------------------------------------

test_that("pulls author information from a supplied profile", {
    tmp <- withr::local_tempdir()
    profile <- make_profile(fs::path(tmp, "profile.yml"), single_author)

    generate_citation(path = tmp, profile = profile)

    content <- readr::read_file(fs::path(tmp, "CITATION.cff"))
    expect_true(grepl("family-names: \"Lares\"", content, fixed = TRUE))
    expect_true(grepl("https://orcid.org/0000-0002-3284-828X", content, fixed = TRUE))
})

test_that("writes one CFF author entry per profile author entry", {
    tmp <- withr::local_tempdir()
    two_authors <- list(
        list(name = "Erwin Lares"),
        list(name = "Ada Lovelace")
    )
    profile <- make_profile(fs::path(tmp, "profile.yml"), two_authors)

    generate_citation(path = tmp, profile = profile)

    content <- readr::read_file(fs::path(tmp, "CITATION.cff"))
    expect_true(grepl("family-names: \"Lares\"", content, fixed = TRUE))
    expect_true(grepl("family-names: \"Lovelace\"", content, fixed = TRUE))
})

test_that("warns and falls back to a placeholder when the profile has no author field", {
    tmp <- withr::local_tempdir()
    profile <- fs::path(tmp, "profile.yml")
    yaml::write_yaml(list(lang = "en"), profile)

    expect_warning(
        generate_citation(path = tmp, profile = profile),
        "author"
    )

    # "Your Name" is split into family-names/given-names like any other
    # name, so it never appears as a contiguous string in the output.
    content <- readr::read_file(fs::path(tmp, "CITATION.cff"))
    expect_true(grepl("family-names: \"Name\"", content, fixed = TRUE))
    expect_true(grepl("given-names: \"Your\"", content, fixed = TRUE))
})

test_that("a generate_profile()-written file round-trips through generate_citation()", {
    tmp <- withr::local_tempdir()
    generate_profile("profile.yml", path = tmp)

    generate_citation(path = tmp, profile = fs::path(tmp, "profile.yml"))

    content <- readr::read_file(fs::path(tmp, "CITATION.cff"))
    expect_true(grepl("family-names:", content, fixed = TRUE))
    expect_true(grepl("given-names:", content, fixed = TRUE))
})
