#' @importFrom Rcpp evalCpp
#' @useDynLib audio.whisper
#' @importFrom utils tail
NULL



.onLoad <- function(libname, pkgname) {
  whisper_load_backend()
  
  invisible()
}
