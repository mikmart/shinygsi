default_options <- list(
  shinygsi.cache = cachem::cache_mem()
)

.onLoad <- function(libname, pkgname) {
  op <- options()

  toset <- !(names(default_options) %in% names(op))
  if (any(toset)) options(default_options[toset])

  invisible()
}
