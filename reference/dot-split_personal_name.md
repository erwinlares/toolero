# Split a full name into given and family names

Internal helper used by
[`generate_citation()`](https://erwinlares.github.io/toolero/reference/generate_citation.md)
to fill the `given-names`/`family-names` fields the Citation File Format
requires, from the single `name` field a profile's `author:` block
carries (the same field Quarto's own author schema uses).

## Usage

``` r
.split_personal_name(name)
```

## Arguments

- name:

  Character. A single full name, e.g. `"Erwin Lares"`.

## Value

A named list with elements `given` and `family`, both character.

## Details

The split is the last space in the string: everything after it is the
family name, everything before it is the given name(s). This is right
for the common case and wrong for some real names – multi-word family
names ("van der Berg"), single-word names, and family-name-first
orderings all defeat it.
[`generate_citation()`](https://erwinlares.github.io/toolero/reference/generate_citation.md)
flags this in its own message rather than pretending the split is
reliable.
