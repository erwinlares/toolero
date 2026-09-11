# Name of the project manifest file

Internal helper returning the filename
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
writes to the project root and
[`check_project()`](https://erwinlares.github.io/toolero/reference/check_project.md)
looks for. Centralized so the name appears once rather than in every
function that touches it.

## Usage

``` r
.project_yml_name()
```

## Value

A single character string.
