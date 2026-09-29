# Schema version of the output record

Internal helper returning the schema version
[`generate_manifest()`](https://erwinlares.github.io/toolero/reference/generate_manifest.md)
writes as the first key of the output record. Like
[`.project_yml_schema_version()`](https://erwinlares.github.io/toolero/reference/dot-project_yml_schema_version.md)
for the project config, this is a schema version, not a package version:
it increments only when an existing key is removed, renamed, or changes
meaning or type, so a reader can decide whether it understands a file
without guessing from the toolero version that wrote it. Output records
written before the key existed (toolero 0.5.x) carry no `schema_version`
and are read as version 1.

## Usage

``` r
.output_record_schema_version()
```

## Value

A single integer.
