qmd_files <- fs::dir_ls(getwd(), glob = "*.qmd")

for (input in qmd_files) {
    output <- fs::path("R", fs::path_ext_set(fs::path_file(input), "R"))
    knitr::purl(input, output = output, documentation = 1)
}
