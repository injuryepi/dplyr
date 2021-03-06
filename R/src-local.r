#' A local source.
#'
#' This is mainly useful for testing, since makes it possible to refer to
#' local and remote tables using exactly the same syntax.
#'
#' Generally, `src_local()` should not be called directly, but instead
#' one of the constructors should be used.
#'
#' @param tbl name of the function used to generate `tbl` objects
#' @param pkg,env Either the name of a package or an environment object in
#'   which to look for objects.
#' @keywords internal
#' @export
#' @examples
#' if (require("Lahman")) {
#' batting_df <- tbl(src_df("Lahman"), "Batting")
#' }
src_local <- function(tbl, pkg = NULL, env = NULL) {
  if (!xor(is.null(pkg), is.null(env))) {
    bad_args(c("pkg", "env"), "exactly one must be non-NULL, ",
      "not {(!is.null(pkg)) + (!is.null(env))}"
    )
  }
  if (!is.null(pkg)) {
    env <- getNamespaceInfo(pkg, "lazydata")
    name <- paste0("<package: ", pkg, ">")
  } else {
    stopifnot(is.environment(env))
    name <- utils::capture.output(print(env))
  }

  structure(
    list(tbl_f = match.fun(tbl), name = name, env = env),
    class = c("src_local", "src")
  )
}

#' @rdname src_local
#' @export
src_df <- function(pkg = NULL, env = NULL) {
  src_local("tbl_df", pkg, env)
}

#' @export
src_tbls.src_local <- function(x, ...) {
  objs <- ls(envir = x$env)
  Filter(function(obj) is.data.frame(get(obj, envir = x$env)), objs)
}

#' @export
tbl.src_local <- function(src, from, ...) {
  src$tbl_f(get(from, src$env))
}

#' @export
copy_to.src_local <- function(dest, df, name = deparse(substitute(df)),
                              overwrite = FALSE, ...) {

  if (!overwrite && exists(name, envir = dest$env, inherits = FALSE)) {
    bad_args(c("name", "overwrite"), "object with name {fmt_obj(name)} already exists, ",
      "set `overwrite` = TRUE"
    )
  }

  assign(name, envir = dest$env, df)
  tbl(dest, name)
}

#' @export
format.src_local <- function(x, ...) {
  paste0(
    "src:  ", x$name, "\n",
    wrap("tbls: ", paste0(sort(src_tbls(x)), collapse = ", "))
  )
}
