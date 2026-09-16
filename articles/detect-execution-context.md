# Writing context-aware R code with \`detect_execution_context()\`

![toolero hex sticker](figures/logo.png)

## The problem

Here is a situation most intermediate R users have encountered, even if
they have not quite named it. You write an analysis script interactively
in RStudio. You load your data with a path relative to your working
directory, run everything, and it works. A week later, you fold that
script into a Quarto document. Suddenly the path is wrong —
`data/input.csv` no longer resolves because the working directory inside
a `quarto render` call is the document’s directory, not the project root
you were working from. You patch the path. Then you want to run the same
logic with `Rscript` from the command line, maybe to test it before
sending it to a computing cluster. The path is wrong again, and this
time the fix is different.

You now have three versions of the same input-loading logic, maintained
in three places, and they can drift. This is a small thing that
compounds over time into a larger problem: the report and the runnable
analysis are no longer the same code.

The root cause is that R code does not know, by default, how it is being
executed. It cannot tell whether it is running in an interactive
session, being rendered as part of a Quarto document, or being called
directly by `Rscript`. Each of these contexts has different conventions
for how the working directory is set, how parameters are passed, and how
input files are found. Writing code that works correctly across all
three without any context awareness means either hardcoding paths
(fragile) or maintaining multiple entry points (tedious).

## The three contexts

It helps to be explicit about what we mean. In a typical research
workflow, R code runs in one of three contexts.

**Interactive.** You are working in RStudio or another IDE. The working
directory is typically the project root, set by the `.Rproj` file. Input
paths are usually relative to that root. Parameters are set by hand or
read from a config file.

**Quarto.** Your code lives inside a `.qmd` document. When
`quarto render` is called, knitr sets the working directory to the
directory containing the `.qmd` file, not the project root. Parameters
are often passed through the `params` key in the YAML header. This is a
natural fit for a reproducible report, but it can be a source of subtle
path errors if the document does not live at the project root.

**Rscript.** The code is run from the command line as a standalone
script, or dispatched by a job scheduler like HTCondor. The working
directory is wherever the script is launched from, which may or may not
be the project root. Parameters are passed via
`commandArgs(trailingOnly = TRUE)`. This is the context that matters
most when you are preparing an analysis for a computing cluster.

These three contexts do not share a common convention for how input
files are located or how parameters arrive. Code written with only one
context in mind will need adaptation — or will silently fail — in the
other two.

## The solution

[`detect_execution_context()`](https://erwinlares.github.io/toolero/reference/detect_execution_context.md)
returns a single string identifying which of these three contexts the
code is currently running in: `"interactive"`, `"quarto"`, or
`"rscript"`. That is the entire interface. The function takes no
arguments and produces one output.

``` r

library(toolero)

context <- detect_execution_context()
context
#> [1] "interactive"
```

The value of this simple function lies in what it enables downstream. It
is the kind of thing you reach for directly when the behavior that
varies is not about data at all – suppressing an interactive progress
message on a batch run, for instance:

``` r

if (detect_execution_context() == "rscript") {
  options(cli.progress_show_after = Inf)
}
```

For the specific, recurring case of resolving an *input file path*
across the three contexts, `toolero` packages the pattern for you in a
second function,
[`resolve_input_path()`](https://erwinlares.github.io/toolero/reference/resolve_input_path.md),
built directly on top of
[`detect_execution_context()`](https://erwinlares.github.io/toolero/reference/detect_execution_context.md):

``` r

input_file <- resolve_input_path(
  interactive = "data/input.csv",
  quarto      = params$input_file,
  rscript     = commandArgs(trailingOnly = TRUE)[1]
)
```

This block replaces three separate entry points with one. Whether the
analysis runs interactively, renders as a report, or executes as a
scheduled job, the same logic handles it. Recall that this is exactly
the kind of drift we identified as the root cause of the problem: one
function call gives you one place to manage it, rather than three copies
of a hand-written [`switch()`](https://rdrr.io/r/base/switch.html) that
can drift apart from each other, which is what an earlier version of
this vignette recommended.

[`resolve_input_path()`](https://erwinlares.github.io/toolero/reference/resolve_input_path.md)
does more than pick the right branch, too. Each branch is an ordinary R
argument, so only the one matching the current context is ever evaluated
– the `params` reference above never runs under `Rscript`, where
`params` does not exist at all. And because the function checks the
result before handing it back, three failures that used to surface one
call later as something unhelpful are now caught and explained: a
missing command line argument, a `params` block that exists without an
`input_file` key, and a resolved path that simply is not there.
Arguments can also be omitted entirely – `rscript` then defaults to the
first command line argument, and `interactive` and `quarto` both fall
back to the document’s own `params$input_file` – so a document whose
header already declares `input_file` can call
[`resolve_input_path()`](https://erwinlares.github.io/toolero/reference/resolve_input_path.md)
with no arguments at all. See
[`?resolve_input_path`](https://erwinlares.github.io/toolero/reference/resolve_input_path.md)
for the full set of failure messages and what each one means.

It may not be unreasonable to assume that many researchers already
handle this implicitly, either by keeping separate scripts for each
context or by commenting and uncommenting lines depending on how they
plan to run the code. Both are workable but both obscure intent. Naming
the branches explicitly, as
[`resolve_input_path()`](https://erwinlares.github.io/toolero/reference/resolve_input_path.md)
does, makes the branching readable: anyone who opens the file can see
immediately that the code was written to run in three contexts and
understand what each one does.

## A worked example

Consider a Quarto document that reads a data file, summarizes it, and
produces a figure. In an early draft of this workflow, the input path
might be hardcoded:

``` r

data <- readr::read_csv("data/penguins.csv")
```

This works when rendering from the project root. It fails as soon as the
document moves to a subdirectory, when the script is extracted and run
standalone, or when it is dispatched on a cluster. In other words, it is
fragile precisely at the moments that matter most.

A more portable version uses
[`resolve_input_path()`](https://erwinlares.github.io/toolero/reference/resolve_input_path.md)
to resolve the path appropriate for each launch method:

``` r

library(toolero)

input_file <- resolve_input_path(
  interactive = "data/penguins.csv",
  quarto      = params$input_file,
  rscript     = commandArgs(trailingOnly = TRUE)[1]
)

data <- read_clean_csv(input_file)
```

This version runs correctly in all three contexts without modification.
It also documents intent: a reader can see that the code was designed to
be portable, not just locally convenient.

## Connecting to `create_qmd()` and `qmd_to_r()`

[`detect_execution_context()`](https://erwinlares.github.io/toolero/reference/detect_execution_context.md)
and
[`resolve_input_path()`](https://erwinlares.github.io/toolero/reference/resolve_input_path.md)
fit naturally into the broader `toolero` workflow for literate, portable
analysis documents.
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
scaffolds a new Quarto document from a template that includes
context-aware input resolution by default – the sample document it
generates already resolves its input with
[`resolve_input_path()`](https://erwinlares.github.io/toolero/reference/resolve_input_path.md)
and declares the `input_file` its `params:` block needs. You do not have
to add either manually.

``` r

# Scaffold a new document with context-aware input resolution built in
create_qmd("analysis.qmd", path = ".")
```

Once the analysis is written and verified,
[`qmd_to_r()`](https://erwinlares.github.io/toolero/reference/qmd_to_r.md)
extracts the R code from the document into a standalone script.

``` r

qmd_to_r(
  input  = "analysis.qmd",
  output = "scripts/analysis.R"
)
```

The extracted script inherits the
[`resolve_input_path()`](https://erwinlares.github.io/toolero/reference/resolve_input_path.md)
call from the document, so it resolves inputs correctly when run with
`Rscript` or dispatched by a job scheduler. That is the important point:
because context detection was baked into the document from the
beginning, the standalone script is already portable. You do not have to
adapt it for the command-line context after the fact.

In other words,
[`detect_execution_context()`](https://erwinlares.github.io/toolero/reference/detect_execution_context.md)
and
[`resolve_input_path()`](https://erwinlares.github.io/toolero/reference/resolve_input_path.md)
are the pieces that make the
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
–
[`qmd_to_r()`](https://erwinlares.github.io/toolero/reference/qmd_to_r.md)
pipeline genuinely portable rather than portable in theory. Write the
analysis once, render it as a report, extract it as a script, and submit
it to a cluster – the same input-resolution logic works throughout.

## Summary

[`detect_execution_context()`](https://erwinlares.github.io/toolero/reference/detect_execution_context.md)
solves a small but persistent problem: R code does not know by default
how it is being run, and that ignorance is a common source of path
errors, parameter mismatches, and diverging entry points.

The function does one thing – identify the current execution context –
and returns a value you can act on immediately. For the specific case of
finding an input file,
[`resolve_input_path()`](https://erwinlares.github.io/toolero/reference/resolve_input_path.md)
builds directly on it, checking the result and explaining what went
wrong when it cannot resolve a usable path. Together they produce code
that is explicit about its portability, easy to read, and correct across
interactive, Quarto, and command-line execution without maintaining
separate versions.

Used alongside
[`create_qmd()`](https://erwinlares.github.io/toolero/reference/create_qmd.md)
and
[`qmd_to_r()`](https://erwinlares.github.io/toolero/reference/qmd_to_r.md),
they close the loop between a literate analysis document and a runnable
standalone script, making the path from local notebook to computing
cluster a little more direct.
