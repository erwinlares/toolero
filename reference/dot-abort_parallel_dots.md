# Report a `...` argument that cannot be sent to a parallel worker

Internal helper used by
[`run_by_group()`](https://erwinlares.github.io/toolero/reference/run_by_group.md)
when materializing `...` for parallel execution fails. The usual cause
is a bare column name intended for `.f` to capture with `{{ }}`: it has
no value outside the data mask `.f` builds, so there is nothing to send
to a worker session.

## Usage

``` r
.abort_parallel_dots(cnd)
```

## Arguments

- cnd:

  The condition raised while evaluating `...`.

## Value

Never returns; aborts.
