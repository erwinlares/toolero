# Read one element of read_output_records()'s path

Internal helper that reads one folder (or one output record file),
falling back to the folder's accumulator when there is no usable output
record, and returns its rows on
[`.output_records_template()`](https://erwinlares.github.io/toolero/reference/dot-output_records_template.md).
Problems with the folder's contents are warnings, never errors, so that
one incomplete folder does not stop the rest from being read.

## Usage

``` r
.read_output_source(path, source, filename)
```

## Arguments

- path:

  Character. An output folder, or an output record file.

- source:

  Character. The label for this element's rows.

- filename:

  Character. Name of the output record within a folder.

## Value

A data frame on
[`.output_records_template()`](https://erwinlares.github.io/toolero/reference/dot-output_records_template.md).
