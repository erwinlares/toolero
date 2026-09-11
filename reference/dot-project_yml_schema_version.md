# Schema version of the project manifest

Internal helper returning the schema version this version of toolero
writes and understands. This is a schema version, not a package version:
it increments only when the shape of `_toolero.yml` changes, which is
expected to be rare, and it lets a reader decide whether it can parse a
file rather than guessing from the package that wrote it.

## Usage

``` r
.project_yml_schema_version()
```

## Value

A single integer.
