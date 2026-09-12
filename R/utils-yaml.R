# Internal helpers for editing the YAML header of a .qmd document.
#
# These operate on the header as text, not as a parsed object. The reason
# is scope: create_qmd() only ever edits headers that toolero itself
# shipped in inst/templates/, so there is nothing to gain from
# round-tripping a header through yaml::yaml.load() and yaml::as.yaml().
# There is plenty to lose. A round trip discards comments outright, strips
# the quoting the template author chose, and re-indents sequences nested
# under mappings, since yaml::as.yaml() defaults to
# indent.mapping.sequence = FALSE. The document a researcher opens then
# does not look like the template we wrote, and the header can never carry
# an explanatory comment. Editing by line leaves the template intact and
# serializes only the value actually being set.
#
# The bound that makes this safe is the one above: these helpers are never
# pointed at a header a user wrote by hand. If that ever changes, they are
# the wrong tool and a comment-preserving YAML parser is the right one.


# -- Indentation of one line, or NA for a blank one --------------------------

.yaml_indent <- function(line) {
    if (!nzchar(trimws(line))) {
        return(NA_integer_)
    }
    attr(regexpr("^ *", line), "match.length")
}


# -- The key a header line declares, or NA when it declares none -------------
#
# `text` is a single line with its leading indentation already removed.
# Comments are not keys. Neither are sequence items: at the indentation we
# search, a leading dash means we are looking at an element of a sequence
# rather than at a mapping key.

.yaml_line_key <- function(text) {
    if (!nzchar(text)) {
        return(NA_character_)
    }

    first <- substr(text, 1L, 1L)

    if (identical(first, "#")) {
        return(NA_character_)
    }
    if (identical(first, "-") &&
        (nchar(text) == 1L || identical(substr(text, 2L, 2L), " "))) {
        return(NA_character_)
    }

    if (identical(first, "\"") || identical(first, "'")) {
        pattern <- if (identical(first, "\"")) "^\"[^\"]*\"" else "^'[^']*'"
        quoted <- regexpr(pattern, text)
        if (quoted < 1L) {
            return(NA_character_)
        }
        len <- attr(quoted, "match.length")
        if (!grepl("^ *:( |$)", substring(text, len + 1L))) {
            return(NA_character_)
        }
        return(substr(text, 2L, len - 1L))
    }

    colon <- regexpr(":", text, fixed = TRUE)
    if (colon < 1L) {
        return(NA_character_)
    }

    after <- substring(text, colon + 1L)
    if (nzchar(after) && !identical(substr(after, 1L, 1L), " ")) {
        return(NA_character_)
    }

    key <- trimws(substr(text, 1L, colon - 1L))
    if (!nzchar(key) || grepl("#", key, fixed = TRUE)) {
        return(NA_character_)
    }

    key
}


# -- Locate a key at a given indentation inside a range of lines -------------

.find_yaml_key <- function(lines, from, to, indent, key) {
    if (from < 1L || to < from) {
        return(NA_integer_)
    }

    for (i in from:to) {
        line_indent <- .yaml_indent(lines[[i]])
        if (is.na(line_indent) || line_indent != indent) {
            next
        }
        found <- .yaml_line_key(substring(lines[[i]], indent + 1L))
        if (!is.na(found) && identical(found, key)) {
            return(i)
        }
    }

    NA_integer_
}


# -- Last line belonging to the entry that starts at `i` ---------------------
#
# An entry runs from its key line to the last following line indented more
# deeply than the key. Blank lines in between are skipped rather than
# terminating the entry, and because only more deeply indented lines move
# the boundary, trailing blank lines are never swallowed.

.yaml_entry_extent <- function(lines, i, limit = length(lines)) {
    indent <- .yaml_indent(lines[[i]])
    last <- i
    k <- i + 1L

    while (k <= limit) {
        k_indent <- .yaml_indent(lines[[k]])
        if (is.na(k_indent)) {
            k <- k + 1L
            next
        }
        if (k_indent <= indent) {
            break
        }
        last <- k
        k <- k + 1L
    }

    last
}


# -- Indentation of the first non-blank line in a range ----------------------

.first_child_indent <- function(lines, from, to) {
    if (from < 1L || to < from) {
        return(NA_integer_)
    }

    for (i in from:to) {
        indent <- .yaml_indent(lines[[i]])
        if (!is.na(indent)) {
            return(indent)
        }
    }

    NA_integer_
}


# -- Replace lines [at_from, at_to] with `replacement` -----------------------
#
# To insert after position p without removing anything, call with
# at_from = p + 1 and at_to = p.

.splice <- function(lines, at_from, at_to, replacement) {
    head <- if (at_from > 1L) lines[seq_len(at_from - 1L)] else character(0)
    tail <- if (at_to < length(lines)) {
        lines[seq.int(at_to + 1L, length(lines))]
    } else {
        character(0)
    }
    c(head, replacement, tail)
}


# -- Render one entry, nesting `value` under the whole of `path` -------------
#
# Only the value being written passes through yaml::as.yaml(), so the rest
# of the header is never reserialized. The logical handler is the one
# carried over from the previous implementation: Quarto wants true/false,
# and the emitter's default for R logicals is yes/no.

.render_yaml_entry <- function(path, value, indent = 0L, indent_unit = 2L) {
    nested <- value
    for (key in rev(path[-1L])) {
        nested <- list(nested)
        names(nested) <- key
    }

    entry <- list(nested)
    names(entry) <- path[[1L]]

    text <- yaml::as.yaml(
        entry,
        indent = indent_unit,
        indent.mapping.sequence = TRUE,
        handlers = list(
            logical = function(x) {
                structure(ifelse(x, "true", "false"), class = "verbatim")
            }
        )
    )

    rendered <- strsplit(sub("\n$", "", text), "\n", fixed = TRUE)[[1L]]

    if (indent > 0L) {
        rendered <- paste0(strrep(" ", indent), rendered)
    }

    rendered
}


# -- Set one key, addressed by path, in a vector of header lines -------------
#
# `path` is the chain of keys down to the one being written, for example
# "purl", c("params", "input_file"), or c("format", "html", "css"). The key
# is replaced where it exists, inserted at the end of its parent block where
# the parent exists but the key does not, and created as a whole chain where
# the parent is missing too. With `overwrite = FALSE` an existing key is left
# exactly as the template wrote it.

.set_yaml_key <- function(lines,
                          path,
                          value,
                          overwrite = TRUE,
                          indent_unit = 2L) {

    from   <- 1L
    to     <- length(lines)
    indent <- 0L

    for (level in seq_along(path)) {
        key       <- path[[level]]
        remaining <- path[level:length(path)]
        hit       <- .find_yaml_key(lines, from, to, indent, key)

        # Not in this block: write the whole remaining chain at the end
        # of it.
        if (is.na(hit)) {
            entry <- .render_yaml_entry(remaining, value, indent, indent_unit)
            insert_after <- if (to >= from) to else from - 1L
            return(.splice(lines, insert_after + 1L, insert_after, entry))
        }

        last <- .yaml_entry_extent(lines, hit, to)

        # The last key in the path: replace the entry it heads.
        if (level == length(path)) {
            if (!overwrite) {
                return(lines)
            }
            entry <- .render_yaml_entry(key, value, indent, indent_unit)
            return(.splice(lines, hit, last, entry))
        }

        # A key on the way to a deeper one has to open a block. A key with
        # nothing indented under it does not, and replacing it wholesale
        # would silently discard whatever scalar it holds.
        if (last == hit) {
            key_path <- paste(path, collapse = " > ")
            cli::cli_abort(c(
                "Cannot set {.field {key_path}} in this YAML header.",
                "x" = "{.field {key}} is already present with a scalar
                       value, so there is no block to write into."
            ))
        }

        from   <- hit + 1L
        to     <- last
        indent <- .first_child_indent(lines, from, to)
    }

    lines
}


# -- Split a .qmd into its YAML header and everything after it ---------------
#
# Returns NULL when there is no header. Fences are excluded from `header`,
# which is the whole point: the previous implementation handed
# yaml::yaml.load() a string with both fences still in it, so the closing
# fence read as the start of a second, empty YAML document.

.split_yaml_header <- function(qmd_content) {
    normalized <- gsub("\r\n", "\n", qmd_content, fixed = TRUE)
    lines <- strsplit(normalized, "\n", fixed = TRUE)[[1L]]

    fences <- grepl("^---[ \t]*$", lines)

    if (length(lines) < 2L || !fences[[1L]]) {
        return(NULL)
    }

    closing <- which(fences)
    closing <- closing[closing > 1L]
    if (length(closing) == 0L) {
        return(NULL)
    }
    closing <- closing[[1L]]

    list(
        header = if (closing > 2L) lines[2:(closing - 1L)] else character(0),
        body   = if (closing < length(lines)) {
            lines[seq.int(closing + 1L, length(lines))]
        } else {
            character(0)
        },
        opening_fence   = lines[[1L]],
        closing_fence   = lines[[closing]],
        trailing_newline = grepl("\n$", normalized)
    )
}


# -- Reassemble a document from edited header lines --------------------------

.join_yaml_header <- function(header, parts) {
    out <- paste(
        c(parts$opening_fence, header, parts$closing_fence, parts$body),
        collapse = "\n"
    )

    if (isTRUE(parts$trailing_newline)) {
        out <- paste0(out, "\n")
    }

    out
}


# -- Set several keys in a document's YAML header ----------------------------
#
# `keys` is a list of entries, each a list with `path`, `value`, and
# optionally `overwrite`. `what` names the operation in the warning issued
# when the document turns out to have no header at all.

.set_yaml_keys <- function(qmd_content, keys, what = "the edit") {
    if (length(keys) == 0L) {
        return(qmd_content)
    }

    parts <- .split_yaml_header(qmd_content)

    if (is.null(parts)) {
        cli::cli_warn("No YAML header found in template. Skipping {what}.")
        return(qmd_content)
    }

    header <- parts$header

    for (entry in keys) {
        header <- .set_yaml_key(
            header,
            path      = entry$path,
            value     = entry$value,
            overwrite = if (is.null(entry$overwrite)) TRUE else entry$overwrite
        )
    }

    .join_yaml_header(header, parts)
}
