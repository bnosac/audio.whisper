# Generated by using Rcpp::compileAttributes() -> do not edit by hand
# Generator token: 10BE3573-1514-4C36-9D1C-5A225CD40393

whisper_load_model <- function(model) {
    .Call('_audio_whisper_whisper_load_model', PACKAGE = 'audio.whisper', model)
}

whisper_encode <- function(model, path, language, token_timestamps = FALSE, translate = FALSE, print_special = FALSE, duration = 0L, offset = 0L, trace = FALSE, n_threads = 1L, n_processors = 1L) {
    .Call('_audio_whisper_whisper_encode', PACKAGE = 'audio.whisper', model, path, language, token_timestamps, translate, print_special, duration, offset, trace, n_threads, n_processors)
}

whisper_print_benchmark <- function(model, n_threads = 1L) {
    invisible(.Call('_audio_whisper_whisper_print_benchmark', PACKAGE = 'audio.whisper', model, n_threads))
}

