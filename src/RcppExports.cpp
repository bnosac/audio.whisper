// Generated by using Rcpp::compileAttributes() -> do not edit by hand
// Generator token: 10BE3573-1514-4C36-9D1C-5A225CD40393

#include <Rcpp.h>

using namespace Rcpp;

// whisper_load_model
SEXP whisper_load_model(std::string model, bool use_gpu);
RcppExport SEXP _audio_whisper_whisper_load_model(SEXP modelSEXP, SEXP use_gpuSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< std::string >::type model(modelSEXP);
    Rcpp::traits::input_parameter< bool >::type use_gpu(use_gpuSEXP);
    rcpp_result_gen = Rcpp::wrap(whisper_load_model(model, use_gpu));
    return rcpp_result_gen;
END_RCPP
}
// whisper_encode
Rcpp::List whisper_encode(SEXP model, std::string path, std::string language, bool token_timestamps, bool translate, int duration, int offset, int trace, int n_threads, int n_processors, float entropy_thold, float logprob_thold, int beam_size, int best_of, bool split_on_word, int max_context, std::string prompt, bool print_special, bool diarize);
RcppExport SEXP _audio_whisper_whisper_encode(SEXP modelSEXP, SEXP pathSEXP, SEXP languageSEXP, SEXP token_timestampsSEXP, SEXP translateSEXP, SEXP durationSEXP, SEXP offsetSEXP, SEXP traceSEXP, SEXP n_threadsSEXP, SEXP n_processorsSEXP, SEXP entropy_tholdSEXP, SEXP logprob_tholdSEXP, SEXP beam_sizeSEXP, SEXP best_ofSEXP, SEXP split_on_wordSEXP, SEXP max_contextSEXP, SEXP promptSEXP, SEXP print_specialSEXP, SEXP diarizeSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< SEXP >::type model(modelSEXP);
    Rcpp::traits::input_parameter< std::string >::type path(pathSEXP);
    Rcpp::traits::input_parameter< std::string >::type language(languageSEXP);
    Rcpp::traits::input_parameter< bool >::type token_timestamps(token_timestampsSEXP);
    Rcpp::traits::input_parameter< bool >::type translate(translateSEXP);
    Rcpp::traits::input_parameter< int >::type duration(durationSEXP);
    Rcpp::traits::input_parameter< int >::type offset(offsetSEXP);
    Rcpp::traits::input_parameter< int >::type trace(traceSEXP);
    Rcpp::traits::input_parameter< int >::type n_threads(n_threadsSEXP);
    Rcpp::traits::input_parameter< int >::type n_processors(n_processorsSEXP);
    Rcpp::traits::input_parameter< float >::type entropy_thold(entropy_tholdSEXP);
    Rcpp::traits::input_parameter< float >::type logprob_thold(logprob_tholdSEXP);
    Rcpp::traits::input_parameter< int >::type beam_size(beam_sizeSEXP);
    Rcpp::traits::input_parameter< int >::type best_of(best_ofSEXP);
    Rcpp::traits::input_parameter< bool >::type split_on_word(split_on_wordSEXP);
    Rcpp::traits::input_parameter< int >::type max_context(max_contextSEXP);
    Rcpp::traits::input_parameter< std::string >::type prompt(promptSEXP);
    Rcpp::traits::input_parameter< bool >::type print_special(print_specialSEXP);
    Rcpp::traits::input_parameter< bool >::type diarize(diarizeSEXP);
    rcpp_result_gen = Rcpp::wrap(whisper_encode(model, path, language, token_timestamps, translate, duration, offset, trace, n_threads, n_processors, entropy_thold, logprob_thold, beam_size, best_of, split_on_word, max_context, prompt, print_special, diarize));
    return rcpp_result_gen;
END_RCPP
}
// whisper_print_benchmark
void whisper_print_benchmark(SEXP model, int n_threads);
RcppExport SEXP _audio_whisper_whisper_print_benchmark(SEXP modelSEXP, SEXP n_threadsSEXP) {
BEGIN_RCPP
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< SEXP >::type model(modelSEXP);
    Rcpp::traits::input_parameter< int >::type n_threads(n_threadsSEXP);
    whisper_print_benchmark(model, n_threads);
    return R_NilValue;
END_RCPP
}
// whisper_language_info
Rcpp::DataFrame whisper_language_info();
RcppExport SEXP _audio_whisper_whisper_language_info() {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    rcpp_result_gen = Rcpp::wrap(whisper_language_info());
    return rcpp_result_gen;
END_RCPP
}

static const R_CallMethodDef CallEntries[] = {
    {"_audio_whisper_whisper_load_model", (DL_FUNC) &_audio_whisper_whisper_load_model, 2},
    {"_audio_whisper_whisper_encode", (DL_FUNC) &_audio_whisper_whisper_encode, 19},
    {"_audio_whisper_whisper_print_benchmark", (DL_FUNC) &_audio_whisper_whisper_print_benchmark, 2},
    {"_audio_whisper_whisper_language_info", (DL_FUNC) &_audio_whisper_whisper_language_info, 0},
    {NULL, NULL, 0}
};

RcppExport void R_init_audio_whisper(DllInfo *dll) {
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
}
