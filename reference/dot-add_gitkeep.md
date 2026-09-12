# Place a .gitkeep in each empty directory

Internal helper used by
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
to keep a scaffolded folder structure under version control.

## Usage

``` r
.add_gitkeep(dirs)
```

## Arguments

- dirs:

  Character vector of directory paths.

## Value

The paths written, invisibly.

## Details

git tracks files, not directories, so a project consisting of empty
folders commits as nothing at all: the opening commit carries the files
at the project root and none of the layout, and a clone arrives with the
structure missing. A zero-byte `.gitkeep` in each otherwise empty folder
is the conventional remedy – git has no opinion about the name, it
simply needs a file to track.

Only empty directories get one. A folder that already has content, such
as `assets/` after branding files have been copied in, is tracked on the
strength of that content and does not need a placeholder.
