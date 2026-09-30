# Parse an output record file

Internal helper that parses one output record and checks the few things
a reader needs before it can trust the file at all: that it is a JSON
object, that `schema_version` (when present) is a single number, and
that `artifacts` is an array of objects. A record with a version this
toolero does not know is returned with a warning, to be read as far as
possible.

## Usage

``` r
.parse_output_record(record_path)
```

## Arguments

- record_path:

  Character. Path to the output record.

## Value

A list with elements `record` (the parsed list), `version` (an integer),
and `problem` (`NULL`, or a short description of why the file cannot be
read).
