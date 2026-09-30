# Column template for read_output_records()

Internal helper returning a zero-row data frame with the columns
[`read_output_records()`](https://erwinlares.github.io/toolero/reference/read_output_records.md)
returns, in order and with their types. Every per-folder result is built
on it, so the stacked table has the same shape however many folders
contributed rows, including none.

## Usage

``` r
.output_records_template()
```

## Value

A data frame with no rows.
