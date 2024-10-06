// Generated by using Rcpp::compileAttributes() -> do not edit by hand
// Generator token: 10BE3573-1514-4C36-9D1C-5A225CD40393

#include <Rcpp.h>

using namespace Rcpp;

#ifdef RCPP_USE_GLOBAL_ROSTREAM
Rcpp::Rostream<true>&  Rcpp::Rcout = Rcpp::Rcpp_cout_get();
Rcpp::Rostream<false>& Rcpp::Rcerr = Rcpp::Rcpp_cerr_get();
#endif

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

static const R_CallMethodDef CallEntries[] = {
    {"_audio_whisper_whisper_print_benchmark", (DL_FUNC) &_audio_whisper_whisper_print_benchmark, 2},
    {"_audio_whisper_whisper_language_info", (DL_FUNC) &_audio_whisper_whisper_language_info, 0},
    {"_audio_whisper_whisper_load_model", (DL_FUNC) &_audio_whisper_whisper_load_model, 2},
    {NULL, NULL, 0}
};

RcppExport void R_init_audio_whisper(DllInfo *dll) {
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
}
