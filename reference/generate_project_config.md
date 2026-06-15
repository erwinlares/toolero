# Generate a project configuration file

Writes a YAML configuration file pre-filled with the standard toolero
folder structure. Edit the file to define a custom project layout, then
pass its path to
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
via the `config` argument.

## Usage

``` r
generate_project_config(filename, path = ".", overwrite = FALSE)
```

## Arguments

- filename:

  A character string. Name of the YAML file to create (e.g.,
  `"linguistics-project.yml"`). Must be supplied explicitly.

- path:

  A character string. Directory in which to write the file. Defaults to
  `"."` (the current working directory). Consider using `"~"` (your home
  directory) so the file is easy to reference in future
  [`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
  calls regardless of which project is active.

- overwrite:

  Logical. If `TRUE`, overwrites an existing file at the same location.
  Defaults to `FALSE`.

## Value

Invisibly returns the full path to the written file.

## Examples

``` r
if (FALSE) { # \dontrun{
# Write to the current working directory
generate_project_config("my-project.yml")

# Write to home directory for easy reuse across projects
generate_project_config("linguistics-project.yml", path = "~")

# Overwrite an existing config
generate_project_config("my-project.yml", overwrite = TRUE)
} # }
```
