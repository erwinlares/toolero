# Find every .qmd stamped purl: true

Internal helper used by
[`check_project()`](https://erwinlares.github.io/toolero/reference/check_project.md)
to locate the documents its stale-purl check needs to look at. Searches
the project root without recursing, plus each declared folder with
recursion, the same shape
[`.project_has_sources()`](https://erwinlares.github.io/toolero/reference/dot-project_has_sources.md)
uses and for the same reason: a full recursive sweep would walk
`renv/library`, which is slow and holds no documents of the project's
own.

## Usage

``` r
.find_purled_qmds(path, folders)
```

## Arguments

- path:

  Character. Path to a project directory.

- folders:

  Character vector. Folders declared for this project.

## Value

A character vector of full paths to `.qmd` files whose header declares
`purl: true`, possibly empty.

## Details

A `.qmd`'s own header is read with `.split_yaml_header()` and parsed
with
[`yaml::yaml.load()`](https://yaml.r-lib.org/reference/yaml.load.html)
rather than matched with a regular expression, because
`.inject_purl_yaml()` always writes a real YAML boolean and this should
agree with however a reader would parse it, not with a pattern that
happens to work today.
