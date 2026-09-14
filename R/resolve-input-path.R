# R/resolve-input-path.R

#' Resolve the input data path for the current execution context
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Picks an input file path according to where the code is running, then
#' checks that the result is usable and explains what went wrong when it is
#' not. It is the pattern this family of packages recommends everywhere,
#' packaged so that it lives in one place rather than being retyped into
#' every document.
#'
#' @param interactive The path to use in an interactive session. Typically
#'   the local development copy of the data. If not supplied, falls back to
#'   the document's own `params$input_file`, when the document declares one.
#' @param quarto The path to use while Quarto renders the document. Normally
#'   `params$input_file`, which is also what is used when this argument is
#'   not supplied.
#' @param rscript The path to use under `Rscript`, normally the first
#'   command line argument. Defaults to exactly that.
#' @param must_exist Logical. Whether to check that the resolved path exists
#'   on disk. Defaults to `TRUE`. Set it to `FALSE` when the path is a URL,
#'   a database handle, or anything else [fs::file_exists()] cannot see.
#' @param context Character. The execution context to resolve for, one of
#'   `"interactive"`, `"quarto"`, or `"rscript"`. Defaults to
#'   [detect_execution_context()]. Supply it directly in tests, or when the
#'   caller has already computed it and does not want a second call.
#'
#' @return A single character string: the resolved path.
#'
#' @details
#' Each of the three arguments is an ordinary R argument and therefore a
#' promise, so only the branch matching `context` is ever evaluated. Under
#' `Rscript`, where `params` does not exist, passing
#' `quarto = params$input_file` is safe because that expression is never
#' forced.
#'
#' The reason this is a function rather than a documented `switch()` follows
#' from the same mechanism. When a branch *is* selected and its expression
#' fails, the failure happens inside this function, where it can be caught
#' and explained. A document that declares no `params:` block raises
#' `object 'params' not found`, which says nothing about YAML headers; a
#' hand-written `switch()` in the document evaluates that expression in the
#' document's own frame, where nothing is in a position to intercept it.
#'
#' The three ways a branch produces something unusable, and what this
#' function says about each:
#'
#' - Under `Rscript` with no argument passed, `commandArgs(trailingOnly =
#'   TRUE)[1]` is `NA_character_`. Reading that produces an error about
#'   `NA` rather than about a missing argument.
#' - Under Quarto, `params` exists only if the YAML header declares it, and
#'   `params$input_file` is `NULL` if the block exists without that key.
#' - In any context, the resolved path may simply not be there, which is
#'   most often a working directory that is not what the author assumed.
#'
#' @export
#'
#' @seealso [detect_execution_context()], which decides the branch.
#'
#' @examples
#' # Resolving for a named context. must_exist = FALSE because there is no
#' # such file here; in a real document you want the default.
#' resolve_input_path(
#'   rscript    = "data-raw/sample.csv",
#'   context    = "rscript",
#'   must_exist = FALSE
#' )
#'
#' \dontrun{
#' # A path per context, which is what a scaffolded document shows. Only
#' # the branch matching the current context is evaluated, so the params
#' # reference is safe under Rscript, where params does not exist.
#' input_file <- resolve_input_path(
#'   interactive = "data-raw/sample.csv",
#'   quarto      = params$input_file,
#'   rscript     = commandArgs(trailingOnly = TRUE)[1]
#' )
#'
#' # The defaults cover the mechanical branch and fall back to the
#' # document's own params for the other two, so a document whose YAML
#' # header declares input_file needs no arguments at all.
#' input_file <- resolve_input_path()
#' }
resolve_input_path <- function(interactive = NULL,
                               quarto      = NULL,
                               rscript     = NULL,
                               must_exist  = TRUE,
                               context     = detect_execution_context()) {

    context <- .validate_context(context)
    caller  <- parent.frame()

    supplied <- c(
        interactive = !missing(interactive),
        quarto      = !missing(quarto),
        rscript     = !missing(rscript)
    )

    if (supplied[[context]]) {
        # The selected branch is forced here rather than in the caller's
        # frame, which is the whole point: an expression like
        # params$input_file can fail, and this is the only place that
        # failure can be turned into a message about YAML headers.
        path <- tryCatch(
            switch(
                context,
                interactive = interactive,
                quarto      = quarto,
                rscript     = rscript
            ),
            error = function(cnd) .abort_branch_error(cnd, context)
        )
    } else {
        path <- .default_input_branch(context, caller)
    }

    if (is.null(path) || length(path) != 1L) {
        .abort_unresolved(context)
    }

    path <- tryCatch(as.character(path), error = function(cnd) NA_character_)

    if (is.na(path) || !nzchar(trimws(path))) {
        .abort_unresolved(context)
    }

    if (isTRUE(must_exist) && !fs::file_exists(path)) {
        working_dir <- getwd()
        cli::cli_abort(c(
            "The resolved input path does not exist.",
            "x" = "{.path {path}}",
            "i" = "Resolved for the {.val {context}} execution context.",
            "i" = "Relative paths are read from {.path {working_dir}}.",
            "i" = "Pass {.code must_exist = FALSE} if the path is not a
                   local file."
        ))
    }

    path
}


# -- Helper: validate the context argument ------------------------------------

.validate_context <- function(context) {
    valid <- c("interactive", "quarto", "rscript")

    if (!is.character(context) || length(context) != 1L || is.na(context) ||
        !context %in% valid) {
        cli::cli_abort(c(
            "{.arg context} must be one of {.val {valid}}.",
            "x" = "Received {.obj_type_friendly {context}}."
        ))
    }

    context
}


# -- Helper: the default value for a branch the caller did not supply ---------
#
# rscript has one unambiguous source. interactive and quarto both fall back
# to the document's own params, which makes the YAML header the single
# source of truth for a document that declares one: the path is written
# once, in the header, rather than once there and once in a chunk that has
# to be kept in step with it.

.default_input_branch <- function(context, env) {
    if (identical(context, "rscript")) {
        return(commandArgs(trailingOnly = TRUE)[1L])
    }

    .params_input_file(env)
}


# -- Helper: read params$input_file out of the calling environment ------------
#
# Looked up in the caller rather than here, and with inherits = TRUE, because
# knitr assigns `params` into the environment the document is knit in, which
# is the caller's enclosure rather than this package's namespace. Returns
# NULL rather than erroring when there is no params object at all, so the
# caller can produce a message about the header instead.

.params_input_file <- function(env) {
    if (!exists("params", envir = env, inherits = TRUE)) {
        return(NULL)
    }

    params <- get("params", envir = env, inherits = TRUE)

    if (!is.list(params)) {
        return(NULL)
    }

    params[["input_file"]]
}


# -- Helper: explain a branch expression that failed when it was forced -------

.abort_branch_error <- function(cnd, context) {
    detail <- conditionMessage(cnd)

    if (identical(context, "quarto") && grepl("'params'", detail, fixed = TRUE)) {
        cli::cli_abort(c(
            "This document does not declare a {.field params} block.",
            "i" = "Quarto creates {.code params} only when the YAML header
                   declares it. Add an {.field input_file} entry under a
                   {.code params:} key in the header.",
            "i" = "Or pass a path directly as {.arg quarto}."
        ), parent = cnd)
    }

    cli::cli_abort(c(
        "Could not evaluate the {.arg {context}} branch.",
        "x" = detail
    ), parent = cnd)
}


# -- Helper: explain a branch that produced nothing usable --------------------

.abort_unresolved <- function(context) {
    if (identical(context, "rscript")) {
        cli::cli_abort(c(
            "No input path was given to this script.",
            "i" = "Under {.code Rscript} the path comes from the first
                   command line argument, and none was passed.",
            "i" = "From {.pkg submitr}, set {.arg data_files} in
                   {.fn htc_gen_submit} so a file is transferred and named.",
            "i" = "Or pass a path directly as {.arg rscript}."
        ))
    }

    if (identical(context, "quarto")) {
        cli::cli_abort(c(
            "No {.field input_file} parameter is available for this render.",
            "i" = "The document's {.field params} block does not declare
                   {.field input_file}, or declares it empty.",
            "i" = "Or pass a path directly as {.arg quarto}."
        ))
    }

    cli::cli_abort(c(
        "No input path is available for the interactive context.",
        "i" = "Pass one as {.arg interactive}, for example
               {.code interactive = \"data-raw/sample.csv\"}.",
        "i" = "Or declare {.field input_file} in the document's
               {.field params} block and it will be used here too."
    ))
}
