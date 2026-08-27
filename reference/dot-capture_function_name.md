# Capture a readable name for a save function

Internal helper used by
[`save_output()`](https://erwinlares.github.io/toolero/reference/save_output.md)
to turn the unevaluated `.f` argument into a readable label for the
accumulator's `function_used` column. Named and namespaced functions are
recorded as written at the call site. Anonymous functions fall back to a
single-line, length-capped label rather than a bare multi-line dump of
the function body.

## Usage

``` r
.capture_function_name(f_expr, max_chars = 200L)
```

## Arguments

- f_expr:

  A character vector, the result of `deparse(substitute(.f))` evaluated
  in the caller's frame.

- max_chars:

  Integer. Maximum length of a returned anonymous-function label before
  truncation.

## Value

A single character string.

## Details

The returned string may contain literal braces when `.f` was anonymous.
It is written to the accumulator as data and is safe there, but any
`cli` message echoing this value must interpolate it (`{.val {x}}`)
rather than pasting it into the message template, or the braces will be
evaluated as inline markup.
