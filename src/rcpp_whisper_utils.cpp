#include <Rcpp.h>
#include "whisper.h"

// [[Rcpp::export]]
Rcpp::DataFrame whisper_language_info() {
  auto max_id = whisper_lang_max_id();
  std::vector<int> id;
  std::vector<std::string> language;
  std::vector<std::string> label;
  for (int i = 0; i <= max_id; ++i) {
    id.push_back(i);
    language.push_back(whisper_lang_str(i));
    label.push_back(whisper_lang_str_full(i));
  }
  return Rcpp::DataFrame::create(
    Rcpp::Named("id") = id, 
    Rcpp::Named("language") = language, 
    Rcpp::Named("language_label") = label, 
    Rcpp::Named("stringsAsFactors") = false);
}


// Functionality to free the Rcpp::XPtr
class WhisperModel {
public: 
  struct whisper_context * ctx;
  WhisperModel(std::string model, bool use_gpu = false){
    struct whisper_context_params cparams;
    cparams.use_gpu = use_gpu;
    ctx = whisper_init_from_file_with_params(model.c_str(), cparams);
  }
  ~WhisperModel(){
    whisper_free(ctx);
  }
};

// [[Rcpp::export]]
SEXP whisper_load_model(std::string model, bool use_gpu = false) {
  // Load language model and return the pointer to be used by whisper_encode
  //struct whisper_context * ctx = whisper_init(model.c_str());
  //Rcpp::XPtr<whisper_context> ptr(ctx, false);
  WhisperModel * wp = new WhisperModel(model, use_gpu);
  Rcpp::XPtr<WhisperModel> ptr(wp, false);
  return ptr;
}