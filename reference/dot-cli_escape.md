# Escape cli markup in a data-derived string

Internal helper. Messages assembled from user data – folder names read
from a config file, filenames found on disk – are passed to `cli` as
message templates, where braces are interpreted as inline markup. A
folder literally named `output/{draft}` would otherwise be evaluated as
an R expression and abort the report. Doubling the braces escapes them.

## Usage

``` r
.cli_escape(x)
```

## Arguments

- x:

  A character string.

## Value

The string with braces escaped for cli.

## Details

Static messages containing intentional markup such as
`{.fn usethis::create_project}` must not pass through this helper.
