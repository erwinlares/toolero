input <- Sys.getenv("QUARTO_DOCUMENT_PATH")
knitr::purl(input, output = fs::path_ext_set(input, "R"), documentation = 1)
