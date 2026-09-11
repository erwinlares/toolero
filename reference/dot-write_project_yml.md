# Write a project manifest

Internal helper that renders `inst/templates/_toolero.yml` with a folder
list and a conventions block and writes the result to `dest`. Used by
both
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md),
which writes the resolved structure of a project it has just created,
and
[`generate_project_config()`](https://erwinlares.github.io/toolero/reference/generate_project_config.md),
which writes the defaults as a starting point for hand editing. One
writer, one format.

## Usage

``` r
.write_project_yml(
  dest,
  folders = .default_folders(),
  conventions = .default_conventions()
)
```

## Arguments

- dest:

  Character. Full path of the file to write.

- folders:

  Character vector. Folder paths relative to the project root.

- conventions:

  Named list of single character strings.

## Value

`dest`, invisibly.
