# Resolve the input data path for the current execution context

**\[experimental\]**

Picks an input file path according to where the code is running, then
checks that the result is usable and explains what went wrong when it is
not. It is the pattern this family of packages recommends everywhere,
packaged so that it lives in one place rather than being retyped into
every document.

## Usage

``` r
resolve_input_path(
  interactive = NULL,
  quarto = NULL,
  rscript = NULL,
  must_exist = TRUE,
  context = detect_execution_context()
)
```

## Arguments

- interactive:

  The path to use in an interactive session. Typically the local
  development copy of the data. If not supplied, falls back to the
  document's own `params$input_file`, when the document declares one.

- quarto:

  The path to use while Quarto renders the document. Normally
  `params$input_file`, which is also what is used when this argument is
  not supplied.

- rscript:

  The path to use under `Rscript`, normally the first command line
  argument. Defaults to exactly that.

- must_exist:

  Logical. Whether to check that the resolved path exists on disk.
  Defaults to `TRUE`. Set it to `FALSE` when the path is a URL, a
  database handle, or anything else
  [`fs::file_exists()`](https://fs.r-lib.org/reference/file_access.html)
  cannot see.

- context:

  Character. The execution context to resolve for, one of
  `"interactive"`, `"quarto"`, or `"rscript"`. Defaults to
  [`detect_execution_context()`](https://erwinlares.github.io/toolero/reference/detect_execution_context.md).
  Supply it directly in tests, or when the caller has already computed
  it and does not want a second call.

## Value

A single character string: the resolved path.

## Details

Each of the three arguments is an ordinary R argument and therefore a
promise, so only the branch matching `context` is ever evaluated. Under
`Rscript`, where `params` does not exist, passing
`quarto = params$input_file` is safe because that expression is never
forced.

The reason this is a function rather than a documented
[`switch()`](https://rdrr.io/r/base/switch.html) follows from the same
mechanism. When a branch *is* selected and its expression fails, the
failure happens inside this function, where it can be caught and
explained. A document that declares no `params:` block raises
`object 'params' not found`, which says nothing about YAML headers; a
hand-written [`switch()`](https://rdrr.io/r/base/switch.html) in the
document evaluates that expression in the document's own frame, where
nothing is in a position to intercept it.

The three ways a branch produces something unusable, and what this
function says about each:

- Under `Rscript` with no argument passed,
  `commandArgs(trailingOnly = TRUE)[1]` is `NA_character_`. Reading that
  produces an error about `NA` rather than about a missing argument.

- Under Quarto, `params` exists only if the YAML header declares it, and
  `params$input_file` is `NULL` if the block exists without that key.

- In any context, the resolved path may simply not be there, which is
  most often a working directory that is not what the author assumed.

## See also

[`detect_execution_context()`](https://erwinlares.github.io/toolero/reference/detect_execution_context.md),
which decides the branch.

## Examples

``` r
# Resolving for a named context. must_exist = FALSE because there is no
# such file here; in a real document you want the default.
resolve_input_path(
  rscript    = "data-raw/sample.csv",
  context    = "rscript",
  must_exist = FALSE
)
#> [1] "data-raw/sample.csv"

if (FALSE) { # \dontrun{
# A path per context, which is what a scaffolded document shows. Only
# the branch matching the current context is evaluated, so the params
# reference is safe under Rscript, where params does not exist.
input_file <- resolve_input_path(
  interactive = "data-raw/sample.csv",
  quarto      = params$input_file,
  rscript     = commandArgs(trailingOnly = TRUE)[1]
)

# The defaults cover the mechanical branch and fall back to the
# document's own params for the other two, so a document whose YAML
# header declares input_file needs no arguments at all.
input_file <- resolve_input_path()
} # }
```
