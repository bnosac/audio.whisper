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
