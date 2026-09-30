# Turn a parsed output record into rows

Internal helper used by
[`read_output_records()`](https://erwinlares.github.io/toolero/reference/read_output_records.md).

## Usage

``` r
.output_record_rows(record, version, source)
```

## Arguments

- record:

  A parsed output record, as returned in
  [`.parse_output_record()`](https://erwinlares.github.io/toolero/reference/dot-parse_output_record.md)'s
  `record` element.

- version:

  Integer. The record's schema version.

- source:

  Character. The label for these rows.

## Value

A data frame on
[`.output_records_template()`](https://erwinlares.github.io/toolero/reference/dot-output_records_template.md).
