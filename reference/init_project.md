# Initialize a new R project with a standard folder structure

`init_project()` creates a new R project at the given path with an
opinionated folder structure suited for research workflows. It
optionally initializes `renv` for package management and git for version
control, and records the structure it resolved in a project manifest at
the project root.

## Usage

``` r
init_project(
  path,
  use_renv = TRUE,
  use_git = TRUE,
  custom_folders = NULL,
  config = NULL,
  open = FALSE,
  branding = "none",
  uw_branding = deprecated(),
  use_readme = TRUE
)
```

## Arguments

- path:

  A character string with the path and name of the new project (e.g.,
  `"~/Documents/my-project"`).

- use_renv:

  Logical. If `TRUE`, initializes `renv` in the new project. Defaults to
  `TRUE`.

- use_git:

  Logical. If `TRUE`, initializes a git repository in the new project.
  Defaults to `TRUE`.

- custom_folders:

  A character vector of folder names to add to or remove from the
  project structure after the base set is resolved. Bare names (e.g.,
  `"models"`) add a folder. Names prefixed with `"-"` (e.g.,
  `"-output/figures"`) suppress creation of that folder. When removing
  from the built-in default set, only the named leaf is suppressed –
  parent directories are preserved, so `"-output/figures"` still leaves
  an `output/` folder behind. When removing from a set supplied via
  `config`, parents are not preserved: a config is an explicit and
  complete statement of the structure, so nothing is added back that the
  author did not ask for. Duplicates of existing folders generate a
  message and are skipped. References to non-existent folders via `"-"`
  generate a warning. Defaults to `NULL`.

- config:

  A character string. Path to a YAML project config file produced by
  [`generate_project_config()`](https://erwinlares.github.io/toolero/reference/generate_project_config.md).
  When supplied, the folder list in the config replaces the built-in
  standard structure entirely, and any `conventions:` it declares
  override the defaults key by key. `custom_folders` is still applied on
  top of the config-derived set. Defaults to `NULL`.

- open:

  Logical. If `TRUE`, opens the new project in RStudio after creation.
  Defaults to `FALSE`.

- branding:

  Character or logical. Controls whether an `assets/` folder is created
  and populated. `TRUE` populates it with generic placeholder branding
  files (`logo.png`, `favicon.png`, `header.html`, `footer.html`,
  `styles.css`). `"uw-madison"` populates it with UW-Madison RCI
  branding files under the same standardized names. `"none"` or `FALSE`
  creates no `assets/` folder. Defaults to `"none"`. When branding is
  enabled, `assets/` joins the project's folder set and is recorded in
  the project manifest alongside every other folder, so downstream
  packages can find the branding files without being told about them
  separately. Note that `favicon.png` is included in the asset set but
  is not automatically wired into Quarto output – favicons are a
  website-project option set in `_quarto.yml` rather than a per-document
  HTML option.

- uw_branding:

  **\[deprecated\]** Use `branding` instead. `uw_branding = TRUE` now
  maps to `branding = "uw-madison"`; `uw_branding = FALSE` maps to
  `branding = "none"`.

- use_readme:

  Logical or character. Controls whether a README file is created at the
  project root. `TRUE` creates `README.md` from the generalist toolero
  template. `FALSE` creates no README file. `"plain"` creates
  `README.txt` with the same generalist content as `README.md` – only
  the extension differs, not the content. Defaults to `TRUE`.

## Value

Called for its side effects. Invisibly returns `path`.

## The project manifest

**\[experimental\]**

`init_project()` writes `_toolero.yml` to the project root, recording
the folder set it resolved and the naming conventions in force. The file
records the *resolved* structure, never the inputs that produced it, so
a project built from a `config`, one built with `custom_folders`, and
one built from the defaults all produce the same shape of file and a
reader never has to replay anything to learn what the project looks
like.

It exists because the structure is configurable.
[`check_project()`](https://erwinlares.github.io/toolero/reference/check_project.md)
can audit a customized project without being handed the same config
again, and `containr` and `submitr` can resolve where code, data, and
outputs live rather than assuming. Commit the file: it describes the
project, not the machine it was created on.

The format is experimental and may gain keys before it settles. The
`schema_version` field exists so that a reader can tell whether it
understands what it is holding.

## Dependency discovery and `renv`

When `use_renv = TRUE`, `init_project()` calls
[`renv::init()`](https://rstudio.github.io/renv/reference/init.html) and
stops there. Earlier versions additionally wrote a `.renvignore`
containing `*.qmd` and took a second snapshot. Both are gone as of
v0.5.0.

The `.renvignore` excluded `.qmd` files from `renv`'s dependency
discovery, which meant that a project whose
[`library()`](https://rdrr.io/r/base/library.html) calls live in its
Quarto source – the arrangement this package recommends – could snapshot
a lockfile with none of the analysis packages in it, and
`containr::generate_dockerfile()` would then build an image that could
not run the analysis. Note that at the moment the file was written there
were no `.qmd` files in the project yet, so it never affected the
snapshot taken at creation time; its only effect was on every snapshot
the user took afterwards.

Take a snapshot yourself once the project has code in it, and before
containerizing:

    renv::snapshot()

## See also

[`check_project()`](https://erwinlares.github.io/toolero/reference/check_project.md),
[`generate_project_config()`](https://erwinlares.github.io/toolero/reference/generate_project_config.md)

## Examples

``` r
if (FALSE) { # \dontrun{
init_project(path = file.path(tempdir(), "project1"),
             use_renv = FALSE, use_git = FALSE)

# Generic placeholder branding
init_project(path = file.path(tempdir(), "project2"),
             branding = TRUE, use_renv = FALSE, use_git = FALSE)

# UW-Madison RCI branding
init_project(path = file.path(tempdir(), "project2b"),
             branding = "uw-madison", use_renv = FALSE, use_git = FALSE)

# Add a folder and suppress one from the standard set
init_project(path = file.path(tempdir(), "project3"),
             custom_folders = c("models", "-output/figures"),
             use_renv = FALSE, use_git = FALSE)

# Drive structure entirely from a config file
init_project(path = file.path(tempdir(), "project4"),
             config = "~/linguistics-project.yml",
             use_renv = FALSE, use_git = FALSE)

# Plain-text README instead of Markdown (same content, README.txt)
init_project(path = file.path(tempdir(), "project5"),
             use_readme = "plain", use_renv = FALSE, use_git = FALSE)

# Skip the README entirely
init_project(path = file.path(tempdir(), "project6"),
             use_readme = FALSE, use_renv = FALSE, use_git = FALSE)
} # }
```
