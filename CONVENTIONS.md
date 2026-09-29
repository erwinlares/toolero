# Conventions for the toolero family

`toolero`, `containr` and `submitr` are three packages that hand work to one
another: `toolero` scaffolds a project and splits its data, `containr` freezes
the software environment into an image, and `submitr` sends that image to a
cluster and brings the results back. Each is useful on its own, and each can be
adopted without the others.

That independence has a cost. A folder name, a file path, or a word can drift
between three codebases that are edited on three different days, and the drift
only becomes visible at the seam, where one package hands something to the next
and the next one looks in the wrong place. Every cross-package defect found in
the family's first audit was a drift of exactly this kind.

This file is the answer to that. It records the conventions the three packages
share, in one place, so that a question like "where does the derived script
live" has one answer that can be cited rather than three that have to be
reconciled. It lives in the `toolero` repository because `toolero` is where the
conventions are authored, and it is linked from all three READMEs.

It is a description of what the packages do, not an aspiration. If a package
disagrees with this file, one of the two is a bug, and the last section says how
to settle which.

---

## 1. The project layout

A project scaffolded by `toolero::init_project()` has this shape:

```text
my-project/
├── data-raw/          inputs as they arrived, never edited in place
├── data/              analysis-ready data, produced from data-raw/
│   └── jobs/          per-group splits from write_by_group(), plus the job manifest
├── R/                 R code, including scripts derived from .qmd documents
├── scripts/           standalone utility scripts not part of the analysis
├── output/            everything the analysis produces
│   ├── figures/
│   └── tables/
├── reports/           .qmd documents and their rendered output
├── assets/            styling and branding, when branding is requested
├── renv.lock          the R package environment
├── _toolero.yml       the project config: the project's own description of the above
└── my-project.Rproj
```

Two notes on that tree, because both have bitten us.

`R/` is the one standard folder `toolero` does not create, because
`usethis::create_project()` creates it unconditionally on its own. It cannot be
suppressed through `config` or `custom_folders`, and a call that asks for the
folder set without `R/` will get `R/` anyway.

`data/jobs/` and `assets/` are conditional. `data/jobs/` appears when
`write_by_group()` writes there; `assets/` appears when `init_project(branding = )`
is used. Both are declared in `_toolero.yml` when they exist, so a downstream
program should read the file rather than assume either is present.

## 2. Where the derived script lives: `R/`

An analysis in this family is usually written as a Quarto document and executed
as a plain R script, because a cluster runs `Rscript`, not `quarto render`. The
script derived from the document lives in `R/`.

```text
reports/analysis.qmd        the source of truth, edited by a person
R/reports/analysis.R        derived from it, executed by a machine
```

`create_qmd(use_purl = TRUE)` sets up a post-render hook that writes there. The
hook mirrors each document's location under `R/`, so `reports/analysis.qmd`
becomes `R/reports/analysis.R` and a document at the project root becomes
`R/analysis.R`; two documents that share a filename in different folders never
overwrite each other's script. `qmd_to_r()`'s own default is to write beside its
input, which is right for the one-off case; pass `output = ` to put the script
in `R/` yourself.

The examples below use `R/analysis.R`, the script derived from a document at
the project root. Downstream this means `submitr` is given
`r_script = "R/analysis.R"`, in both
`htc_gen_submit()` and `htc_gen_executable()`, and the same path in
`htc_gen_submit(input_files = )`. The script is not baked into the container
image: it travels to the execute node as an uploaded job input, so editing it
means re-uploading and resubmitting, not rebuilding and re-pushing the image.
`htc_gen_submit()` warns when `r_script` is missing from `input_files`.
`containr` may still be given `code_file = "R/analysis.R"` for an image that has
to run on its own, for a collaborator say, but a cluster job runs the uploaded
copy, not the one in the image.

The path itself is the one thing that has to stay consistent. Naming the script
differently in different places reproduces a broken path in a new location,
which is how the family arrived at four different answers to this question in
the first place.

Never edit the derived script. It is regenerated on every render, and an edit to
it is lost the next time somebody opens the document.

## 3. The output folder: `output/`

Everything an analysis produces goes under `output/`, on the laptop and on an
execute node alike. Not `results/`, which earlier versions of `submitr` used.

`toolero::save_output()` writes there and records each write in
`output/accumulator.csv`. `toolero::generate_manifest()` reads that accumulator
and writes the output record, `output/project-manifest.json`.
`submitr::htc_gen_executable()` defaults to `results_folder = "output"` and tars
that folder at the end of the job.

One consequence is worth stating plainly, because it is the failure people hit
first. Creating `output/` does not create `output/figures/`. A job that runs on
a machine where only `output/` exists, which is what a generated executable's
`mkdir -p` gives you, will fail on a bare `ggsave("output/figures/x.png")`.
`save_output()` creates parent directories recursively and is safe; a direct
call to a writer is not. Either use `save_output()`, or create the subfolder in
the script before writing to it.

## 4. Paths inside the container

`containr` preserves the project's directory structure inside the image. For
the `base`, `tidyverse`, `rstudio` and `verse` modes, files are copied under
`home_dir` (`/home` by default); for the two Shiny modes they land under
`/srv/shiny-server`. So a project laid out as in section 1, containerized with
`data_file = "data-raw/"` and `misc_file = "reports/"`, appears in the image
like this:

```text
/home/renv.lock
/home/data-raw/sample.csv
/home/reports/analysis.qmd
```

Relative paths therefore mean the same thing inside the container as they do on
the laptop, which is the whole point of preserving the structure. A script that
reads `data-raw/sample.csv` works in both places without modification.

The lockfile always goes to the working directory, `home_dir`, because the
`renv` restore runs there.

When `submitr` names a data file baked into the image, it names the path inside
the image, absolutely: `/home/data-raw/sample.csv`. On the laptop the same file
is `data-raw/sample.csv`, relative to the project root. These are the same file
and not the same path, and documents that say otherwise confuse people who read
carefully. The script is the opposite case: it arrives in the job's scratch
directory as an uploaded input, so the generated executable runs it by bare
name (`Rscript analysis.R`), not by a path inside the image.

## 5. Finding the input file: `resolve_input_path()`

The same analysis runs in three contexts and the input lives in a different
place in each: interactively you are sitting in the project, under
`quarto render` the working directory is the document's, and under
`Rscript analysis.R subset-c.csv` the file to read is named on the command line.

`toolero::resolve_input_path()` is the one answer to this. In the common case it
takes no arguments at all:

```r
input <- toolero::resolve_input_path()
```

Each of its three branches is a promise, so only the branch that applies is ever
evaluated, and because it is evaluated inside the function a missing `params:`
block becomes a message about the YAML header rather than
`object 'params' not found` from somewhere in the middle of a render.

The `rscript` branch defaults to the first trailing command line argument, which
is exactly what `submitr`'s generated executable passes. That is not a
coincidence and it should not be broken: a change to how the executable passes
the subset filename is a change to this contract.

Do not paste a hand-written `switch()` on `detect_execution_context()` into
documents or teaching material. `detect_execution_context()` remains available
and is the right tool when the thing that varies is not the input path, but for
the input path the function above is the supported answer.

## 6. `_toolero.yml`

`init_project()` writes `_toolero.yml` at the project root. It is the project's
machine-readable description of itself, and it exists so that `containr` and
`submitr` do not have to ask the user to retype what the project already knows.

```yaml
schema_version: 1
folders:
  - data-raw
  - data
  - data/jobs
  - R
  - scripts
  - output
  - output/figures
  - output/tables
  - reports
conventions:
  output_dir: output
  script_dir: R
  split_dir: data/jobs
  raw_dir: data-raw
  clean_dir: data
```

Four rules govern it.

**It is external-only.** `toolero` writes the file and never reads it at
runtime. No `toolero` function changes its behaviour because the file is present
or absent. The readers are `check_project()`, `containr` and `submitr`.

**Reading it is not a dependency on `toolero`.** It is a small flat YAML file.
A reader needs a YAML parser and nothing else. A project that writes the file by
hand is as valid an input as one that ran `init_project()`, and neither
`containr` nor `submitr` should ever declare a dependency on `toolero` in order
to read it.

**The schema is flat and versioned.** `schema_version` is an integer. A reader
that meets a version it does not recognize should warn and fall back to its own
defaults, not abort: a project scaffolded by a newer `toolero` should still be
containerizable by an older `containr`.

**Reading it is opt-in, and visible.** A downstream function should take the
config path as an explicit argument rather than picking the file up because it
happens to be there, and should report which values it took from the file. A
generated `Dockerfile` whose `COPY` lines came from somewhere the user cannot
see is the kind of invisible input this family exists to eliminate.

The surface is marked experimental in `toolero`'s documentation. The schema may
gain keys; existing keys will not change meaning without a version bump.

## 7. Vocabulary

Several words drifted between the three packages, and each now has one
meaning. Four of them name files. They are worth keeping straight, because
three of the four files have "manifest" somewhere in their name.

The **project config** is `_toolero.yml`: the project's description of its own
folders and conventions (section 6). `init_project()` writes it;
`check_project()`, `containr`, and `submitr` read it.

The **job manifest** is a list of inputs to a computation about to happen.
`write_by_group()` writes one at `data/jobs/manifest.csv`, with one row per
split file, and `submitr` derives `subdatasets.csv` from it.

The **output record** is a record of outputs from a computation that has
already happened. `generate_manifest()` writes it at
`output/project-manifest.json`, from the rows `save_output()` appended to
`output/accumulator.csv` along the way. The accumulator is the raw,
append-only log; the output record is its deduplicated, end-of-run summary.

The **submission state** is `submitr`'s working memory for the job in
progress, kept in `htc-manifest.yaml`: which files were generated, where they
were uploaded, and which cluster ID came back. It is updated as the work
proceeds and read only by `submitr` itself.

The file and function names predate these terms and are kept for
compatibility, so `generate_manifest()` writes the output record and
`htc-manifest.yaml` holds the submission state. Use the term in prose and the
file name in code. Unqualified, the word "manifest" means none of these; use
one of the four terms instead.

**Development packages** are what you install with `apt-get` to build an R
package from source: `libfreetype-dev`, `libpng-dev`. **Headers** are one of the
things inside such a package. Say "the `libfreetype` and `libpng` development
packages", not "the headers", when what you mean is the thing being installed.

CHTC calls the machine you log into an **access point**; HTCondor's own
documentation also calls it a **submit node**. Both are correct. Introduce both
once, then use **submit node** throughout, because it pairs with **execute
node**, which has no competing name.

## 8. What each package may assume

`toolero` assumes nothing about the other two. It never reads `_toolero.yml`, it
never checks for a `Dockerfile`, and it has no knowledge of HTCondor.

`containr` may assume a project has `renv.lock` at its root. It may read
`_toolero.yml` when it is pointed at one. It may not assume `toolero` is
installed, and it may not assume any particular folder exists.

`submitr` may assume the image contains any data files at the absolute paths
it was given, and it may read `_toolero.yml` when it is pointed at one. It
cannot verify the first of those, and should say so rather than implying that
it has. It may not assume the image contains the analysis script: the script
travels with the job (section 2).

The analysis script inside an image may assume `toolero` is available **only if
`toolero` is in `renv.lock`**. This is easy to forget, because on the laptop
`toolero` is installed for reasons that have nothing to do with the analysis. If
the containerized script calls `save_output()` or `resolve_input_path()`, then
`toolero` is a runtime dependency of that analysis and has to be snapshotted
like any other.

## 9. Changing a convention

A convention here is load-bearing across three CRAN packages, so changing one is
not a refactor.

Propose the change in the relevant package's audit document, with the item
number it will carry. Say which of the other two packages inherit it, and
whether they have to move in the same release or can follow. Update this file in
the same commit that ships the first half of the change, not afterwards, and
note the change in the version history below.

Where a change has to happen in two packages at once, say so explicitly and in
both audit documents. There is exactly one such constraint at the time of
writing, in section 5: `submitr`'s generated executable passes the subset
filename as the first trailing command line argument, and
`toolero::resolve_input_path()`'s `rscript` branch reads exactly that. The two
cannot move separately. (The constraint section 2 used to name, between
`containr`'s `code_file` and `submitr`'s `r_script`, retired when the script
stopped being baked into the image.)

---

## Version history

**2026-09 (vocabulary and the uploaded script).** Section 7 now defines four
file terms instead of two: the *project manifest* is renamed the *output
record*, and *project config* (`_toolero.yml`) and *submission state*
(`htc-manifest.yaml`) are added. No files, functions, or arguments were
renamed; the three READMEs were brought into line in the same change.
Sections 2, 4, 8 and 9 were corrected to match `submitr`'s decision (S-I4,
2026-09-24) that the analysis script travels to the execute node as an
uploaded job input rather than being baked into the container image. That
decision shipped before this file was updated, which is the order section 9
asks to avoid. Section 2 also now describes the purl hook's path mirroring
(`reports/analysis.qmd` purls to `R/reports/analysis.R`), which the earlier
text had flattened to `R/analysis.R`.

**2026-09 (toolero 0.6.0).** No changes to the conventions themselves.
`toolero` added `generate_profile()` and `generate_citation()`, a `config`
argument to `write_by_group()`, `save_output()`, and `generate_manifest()`
for reading `output_dir`/`split_dir` out of `_toolero.yml`, and a `commit`
field on the project manifest -- all additive, and all already consistent
with what this file describes.

**2026-09.** First version, written after the `toolero` 0.5.0 remediation
settled the conventions in sections 1 through 6. The decisions recorded here
supersede: `results/` as an output folder name, `scripts/` as the home of
derived scripts, the hand-written `switch()` on `detect_execution_context()` as
the way to resolve an input path, and the stamped `params:` block that an
earlier draft of `create_qmd()` briefly wrote.
