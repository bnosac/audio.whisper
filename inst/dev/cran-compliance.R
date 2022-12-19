## Clean up ggml.c for CRAN compliance
x <- readLines("src/whisper_cpp/ggml.c")
x <- x[-grep(pattern = "abort()", x)]
x <- c('#include "R.h"', x)
x <- gsub(x, pattern = "fprintf(stderr, ", replacement = "Rf_error(", fixed = TRUE)
x <- gsub(x, pattern = "printf(__VA_ARGS__)", replacement = "Rprintf(__VA_ARGS__)", fixed = TRUE)
writeLines(x, "src/whisper_cpp/ggml.c")

## Clean up whisper.cpp for CRAN compliance
x <- readLines("src/whisper_cpp/whisper.cpp")
x <- c('#include <Rcpp.h>', x)
x <- gsub(x, pattern = "fprintf(stderr, ", replacement = "Rprintf(", fixed = TRUE)
x <- gsub(x, pattern = " printf(", replacement = " Rprintf(", fixed = TRUE)
x <- gsub(x, pattern = "fflush(stdout)", replacement = "Rcpp::checkUserInterrupt()", fixed = TRUE)
writeLines(x, "src/whisper_cpp/whisper.cpp")
