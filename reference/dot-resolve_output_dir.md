# Resolve the directory that holds the accumulator and the output record

Internal helper shared by
[`save_output()`](https://erwinlares.github.io/toolero/reference/save_output.md)
and
[`generate_manifest()`](https://erwinlares.github.io/toolero/reference/generate_manifest.md).
An explicit `output_dir` is used exactly as given. Otherwise the
directory comes from `config`'s `output_dir` convention, or is
`"output"`, and a relative value is taken from the project root: the
directory holding `config` when one is supplied,
[`.project_root()`](https://erwinlares.github.io/toolero/reference/dot-project_root.md)
otherwise. So `output/` means the project's own output folder whether
the code runs at the project root, in a document under `reports/`, or on
an execute node.

## Usage

``` r
.resolve_output_dir(output_dir, config)
```

## Arguments

- output_dir:

  Character or `NULL`. The caller's explicit value.

- config:

  Character or `NULL`. Path to a project config.

## Value

A single character string.
