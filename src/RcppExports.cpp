// Generated by using Rcpp::compileAttributes() -> do not edit by hand
// Generator token: 10BE3573-1514-4C36-9D1C-5A225CD40393

#include <Rcpp.h>

using namespace Rcpp;

// whisper_encode
Rcpp::List whisper_encode(std::string model, std::string path, std::string language);
RcppExport SEXP _audio_whisper_whisper_encode(SEXP modelSEXP, SEXP pathSEXP, SEXP languageSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< std::string >::type model(modelSEXP);
    Rcpp::traits::input_parameter< std::string >::type path(pathSEXP);
    Rcpp::traits::input_parameter< std::string >::type language(languageSEXP);
    rcpp_result_gen = Rcpp::wrap(whisper_encode(model, path, language));
    return rcpp_result_gen;
END_RCPP
}

static const R_CallMethodDef CallEntries[] = {
    {"_audio_whisper_whisper_encode", (DL_FUNC) &_audio_whisper_whisper_encode, 3},
    {NULL, NULL, 0}
};

RcppExport void R_init_audio_whisper(DllInfo *dll) {
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
}
