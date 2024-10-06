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



// [[Rcpp::export]]
void whisper_print_benchmark(SEXP model, int n_threads = 1) {
  whisper_params params;
  params.n_threads = n_threads;
  // whisper init
  Rcpp::XPtr<WhisperModel> whispermodel(model);
  struct whisper_context * ctx = whispermodel->ctx;
  Rprintf("\n");
  Rprintf("system_info: n_threads = %d / %d | %s\n", params.n_threads, std::thread::hardware_concurrency(), whisper_print_system_info());
  const int n_mels = whisper_model_n_mels(ctx);
  if (int ret = whisper_set_mel(ctx, nullptr, 0, n_mels)) {
    Rprintf("error: failed to set mel: %d\n", ret);
  }
  if (int ret = whisper_encode(ctx, 0, params.n_threads) != 0) {
    Rprintf("error: failed to encode model: %d\n", ret);
  }
  whisper_print_timings(ctx);
}
