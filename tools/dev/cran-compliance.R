#exit/abort/fprintf/printf/fflush/rand

## Clean up for CRAN compliance
f <- list.files("src/whisper_cpp", pattern = ".c$|.h$", full.names = TRUE)
for(p in f){
  x <- readLines(p)
  if(any(grepl(x, pattern = "exit(1)", fixed = TRUE)) || 
     any(grepl(x, pattern = "exit(0)", fixed = TRUE)) || 
     any(grepl(x, pattern = "abort()", fixed = TRUE)) || 
     any(grepl(x, pattern = "fprintf(stderr, ", fixed = TRUE)) ||
     any(grepl(x, pattern = "printf(__VA_ARGS__)", fixed = TRUE)) ||
     any(grepl(x, pattern = " printf(", fixed = TRUE)) ||
     any(grepl(x, pattern = "fflush(stdout)", fixed = TRUE))){
    x <- c('#include "R.h"', x)
    #x <- x[!grepl(x, pattern = "exit(1)", fixed = TRUE)]
    x <- gsub(x, pattern = "exit(1)", replacement = 'Rf_error("whispercpp error")', fixed = TRUE)
    x <- gsub(x, pattern = "exit(0)", replacement = 'Rf_error("whispercpp error")', fixed = TRUE)
    x <- gsub(x, pattern = "abort()", replacement = 'Rf_error("whispercpp error")', fixed = TRUE)
    x <- gsub(x, pattern = "fprintf(stderr, ", replacement = "Rprintf(", fixed = TRUE)
    #x <- gsub(x, pattern = "fprintf(stderr, ", replacement = "Rf_error(", fixed = TRUE)
    x <- gsub(x, pattern = "printf(__VA_ARGS__)", replacement = "Rprintf(__VA_ARGS__)", fixed = TRUE)
    x <- gsub(x, pattern = " printf(", replacement = " Rprintf(", fixed = TRUE)
    x <- gsub(x, pattern = "fflush(stdout)", replacement = "R_CheckUserInterrupt()", fixed = TRUE)
    writeLines(x, p)
  }
}

x <- readLines("src/whisper_cpp/ggml.c")
#x <- x[!grepl(x, pattern = "FILE * fout = stdout;", fixed = TRUE)]
x <- gsub(x, pattern = "FILE * fout = stdout;", replacement = "FILE * fout;", fixed = TRUE)
x <- gsub(x, pattern = "fprintf(fout, ", replacement = "Rprintf(", fixed = TRUE)
writeLines(x, "src/whisper_cpp/ggml.c")        

## Clean up whisper.cpp for CRAN compliance
x <- readLines("src/whisper_cpp/whisper.cpp")
x <- c('#include <Rcpp.h>', x)
x <- gsub(x, pattern = "exit(1)", replacement = 'Rcpp::stop("whispercpp error")', fixed = TRUE)
x <- gsub(x, pattern = "exit(0)", replacement = 'Rcpp::stop("whispercpp error")', fixed = TRUE)
x <- gsub(x, pattern = "abort()", replacement = 'Rcpp::stop("whispercpp error")', fixed = TRUE)
x <- gsub(x, pattern = "fprintf(stderr, ", replacement = "Rprintf(", fixed = TRUE)
x <- gsub(x, pattern = " printf(", replacement = " Rprintf(", fixed = TRUE)
x <- gsub(x, pattern = "fflush(stdout)", replacement = "Rcpp::checkUserInterrupt()", fixed = TRUE)
x <- gsub(x, pattern = "fflush(stderr)", replacement = "Rcpp::checkUserInterrupt()", fixed = TRUE)
x <- gsub(x, pattern = "fputs(whisper_bench_ggml_mul_mat_str(n_threads), stderr)", replacement = "Rcpp::Rcout << whisper_bench_ggml_mul_mat_str(n_threads)", fixed = TRUE)
x <- gsub(x, pattern = "fputs(whisper_bench_memcpy_str(n_threads), stderr)", replacement = "Rcpp::Rcout << whisper_bench_memcpy_str(n_threads)", fixed = TRUE)
x <- gsub(x, pattern = "fputs(text, stderr);", replacement = "Rcpp::Rcout << text;", fixed = TRUE)
x <- gsub(x, pattern = "rand()", replacement = "((int) floor(R::runif(0, 32767)))", fixed = TRUE)
writeLines(x, "src/whisper_cpp/whisper.cpp")

## Clean up common-ggml.cpp for CRAN compliance
x <- readLines("src/whisper_cpp/common-ggml.cpp")
x <- c('#include <Rcpp.h>', x)
x <- gsub(x, pattern = "exit(1)", replacement = 'Rcpp::stop("whispercpp error")', fixed = TRUE)
x <- gsub(x, pattern = "exit(0)", replacement = 'Rcpp::stop("whispercpp error")', fixed = TRUE)
x <- gsub(x, pattern = "abort()", replacement = 'Rcpp::stop("whispercpp error")', fixed = TRUE)
x <- gsub(x, pattern = "fprintf(stderr, ", replacement = "Rprintf(", fixed = TRUE)
x <- gsub(x, pattern = " printf(", replacement = " Rprintf(", fixed = TRUE)
x <- gsub(x, pattern = "fflush(stdout)", replacement = "Rcpp::checkUserInterrupt()", fixed = TRUE)
x <- gsub(x, pattern = "fflush(stderr)", replacement = "Rcpp::checkUserInterrupt()", fixed = TRUE)
x <- gsub(x, pattern = "fputs(whisper_bench_ggml_mul_mat_str(n_threads), stderr)", replacement = "Rcpp::Rcout << whisper_bench_ggml_mul_mat_str(n_threads)", fixed = TRUE)
x <- gsub(x, pattern = "fputs(whisper_bench_memcpy_str(n_threads), stderr)", replacement = "Rcpp::Rcout << whisper_bench_memcpy_str(n_threads)", fixed = TRUE)
x <- gsub(x, pattern = "fputs(text, stderr);", replacement = "Rcpp::Rcout << text;", fixed = TRUE)
x <- gsub(x, pattern = "rand()", replacement = "((int) floor(R::runif(0, 32767)))", fixed = TRUE)
writeLines(x, "src/whisper_cpp/common-ggml.cpp")

## Clean up common.cpp for CRAN compliance
x <- readLines("src/whisper_cpp/common.cpp")
x <- c('#include <Rcpp.h>', x)
x <- gsub(x, pattern = "exit(1)", replacement = 'Rcpp::stop("whispercpp error")', fixed = TRUE)
x <- gsub(x, pattern = "exit(0)", replacement = 'Rcpp::stop("whispercpp error")', fixed = TRUE)
x <- gsub(x, pattern = "abort()", replacement = 'Rcpp::stop("whispercpp error")', fixed = TRUE)
x <- gsub(x, pattern = "fprintf(stderr, ", replacement = "Rprintf(", fixed = TRUE)
x <- gsub(x, pattern = " printf(", replacement = " Rprintf(", fixed = TRUE)
x <- gsub(x, pattern = "fflush(stdout)", replacement = "Rcpp::checkUserInterrupt()", fixed = TRUE)
x <- gsub(x, pattern = "fflush(stderr)", replacement = "Rcpp::checkUserInterrupt()", fixed = TRUE)
x <- gsub(x, pattern = "fputs(whisper_bench_ggml_mul_mat_str(n_threads), stderr)", replacement = "Rcpp::Rcout << whisper_bench_ggml_mul_mat_str(n_threads)", fixed = TRUE)
x <- gsub(x, pattern = "fputs(whisper_bench_memcpy_str(n_threads), stderr)", replacement = "Rcpp::Rcout << whisper_bench_memcpy_str(n_threads)", fixed = TRUE)
x <- gsub(x, pattern = "fputs(text, stderr);", replacement = "Rcpp::Rcout << text;", fixed = TRUE)
x <- gsub(x, pattern = "rand()", replacement = "((int) floor(R::runif(0, 32767)))", fixed = TRUE)
writeLines(x, "src/whisper_cpp/common.cpp")

## Make sure Metal works - otherwise 
x <- readLines("src/whisper_cpp/ggml-metal.m")
x <- c('#ifndef R_NO_REMAP', '#define R_NO_REMAP 1', '#endif', '#import "R.h"', x)
x <- gsub(x, pattern = "fprintf(stderr, ", replacement = "Rprintf(", fixed = TRUE)
writeLines(x, "src/whisper_cpp/ggml-metal.m")
