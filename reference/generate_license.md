# Generate a LICENSE file

Writes a plain-text `LICENSE` file at the project root, using one of a
small set of common license templates with the copyright holder and year
filled in.

## Usage

``` r
generate_license(
  license = "MIT",
  holder = NULL,
  year = format(Sys.Date(), "%Y"),
  path = ".",
  overwrite = FALSE
)
```

## Arguments

- license:

  A character string. One of `"MIT"`, `"CC0"`, or `"GPL-3"`. Only this
  small, common set is supported; write a `LICENSE` file by hand for
  anything else. Defaults to `"MIT"`.

- holder:

  A character string. The copyright holder – a person or an institution.
  Must be supplied explicitly; there is no default, since guessing it
  wrong is worse than asking.

- year:

  A character string. The copyright year. Defaults to the current year.

- path:

  A character string. Directory in which to write the file. Defaults to
  `"."` (the current working directory).

- overwrite:

  Logical. If `TRUE`, overwrites an existing `LICENSE` file at the same
  location. Defaults to `FALSE`.

## Value

Invisibly returns the full path to the written file.

## Details

Note that this is different from how an R package normally carries a
license. A package's `DESCRIPTION` declares
`License: MIT + file LICENSE` and pairs a two-line CRAN stub (`LICENSE`)
with the full text in a separate `LICENSE.md`. The projects
[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md)
scaffolds are research compendia, not packages – there is no
`DESCRIPTION` to reference a license from – so `generate_license()`
instead writes one self-contained file carrying the license text
directly, the way a plain GitHub repository does.

## GPL-3

The GNU General Public License's full text runs to several hundred
lines. Rather than risk an inaccurate transcription of it,
`license = "GPL-3"` writes the license notice the Free Software
Foundation itself recommends attaching to a program, together with a
link to the canonical full text at
<https://www.gnu.org/licenses/gpl-3.0.txt>. `"MIT"` and `"CC0"` are both
short enough to reproduce here in full, and are written that way.

## See also

[`init_project()`](https://erwinlares.github.io/toolero/reference/init_project.md),
[`generate_data_doc()`](https://erwinlares.github.io/toolero/reference/generate_data_doc.md)

## Examples

``` r
if (FALSE) { # \dontrun{
generate_license(license = "MIT", holder = "Jane Researcher")

generate_license(license = "CC0", holder = "Example Lab",
                  path = "~/Documents/my-project")
} # }
```
