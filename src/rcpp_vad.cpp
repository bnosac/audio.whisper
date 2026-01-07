#include <Rcpp.h>
#include "read_wav.h"
#include "whisper.h"
#include "ggml.h"

struct cli_params {
  int32_t     n_threads = std::min(4, (int32_t) std::thread::hardware_concurrency());
  std::string vad_model = "";
  float       vad_threshold = 0.5f;
  int         vad_min_speech_duration_ms = 250;
  int         vad_min_silence_duration_ms = 100;
  float       vad_max_speech_duration_s = FLT_MAX;
  int         vad_speech_pad_ms = 30;
  float       vad_samples_overlap = 0.1f;
  bool        use_gpu = false;
  std::string fname_inp = {};
  bool        no_prints       = false;
};

static void cb_log_disable(enum ggml_log_level , const char * , void * ) { }


// [[Rcpp::export]]
Rcpp::List silero_vad(
    std::string path, std::string vad_model,
    float       vad_threshold = 0.5,
    int         vad_min_speech_duration_ms = 250,
    int         vad_min_silence_duration_ms = 100,
    float       vad_max_speech_duration_s = -1,
    int         vad_speech_pad_ms = 30,
    float       vad_samples_overlap = 0.1,
    bool        use_gpu = false,
    int         n_threads = 1,
    bool        probabilities = false) {
  //ggml_backend_load_all();
  float audio_duration=0;
  cli_params cli_params;
  cli_params.vad_model  = vad_model;
  cli_params.vad_threshold = vad_threshold;
  cli_params.vad_min_speech_duration_ms = vad_min_speech_duration_ms;
  cli_params.vad_min_silence_duration_ms = vad_min_silence_duration_ms;
  cli_params.vad_max_speech_duration_s = vad_max_speech_duration_s;
  cli_params.vad_speech_pad_ms = vad_speech_pad_ms;
  cli_params.vad_samples_overlap = vad_samples_overlap;
  
  whisper_log_set(cb_log_disable, NULL);
  
  std::vector<float> pcmf32;               // mono-channel F32 PCM
  std::vector<std::vector<float>> pcmf32s; // stereo-channel F32 PCM
  
  if (!::read_wav(path, pcmf32, pcmf32s, false)) {
    Rprintf("error: failed to read WAV file '%s'\n", path.c_str());
    Rcpp::stop("The input audio needs to be a 16-bit .wav file.");
  }
  audio_duration = float(pcmf32.size())/WHISPER_SAMPLE_RATE;
  
  // Initialize the context which loads the VAD model.
  struct whisper_vad_context_params ctx_params = whisper_vad_default_context_params();
  ctx_params.n_threads  = n_threads;
  ctx_params.use_gpu    = use_gpu;
  struct whisper_vad_context * vctx = whisper_vad_init_from_file_with_params(
    cli_params.vad_model.c_str(),
    ctx_params);

  // Detect speech in the input audio file.
  if (!whisper_vad_detect_speech(vctx, pcmf32.data(), pcmf32.size())) {
    Rprintf("error: failed to detect speech\n");
  }

  // Get the the vad segements using the probabilities that have been computed
  // previously and stored in the whisper_vad_context.
  struct whisper_vad_params params = whisper_vad_default_params();
  params.threshold = cli_params.vad_threshold;
  params.min_speech_duration_ms = cli_params.vad_min_speech_duration_ms;
  params.min_silence_duration_ms = cli_params.vad_min_silence_duration_ms;
  if (!whisper_vad_detect_speech(vctx, pcmf32.data(), pcmf32.size())) {
    Rprintf("error: failed to detect speech\n");
  }
  params.max_speech_duration_s = cli_params.vad_max_speech_duration_s;
  params.speech_pad_ms = cli_params.vad_speech_pad_ms;
  params.samples_overlap = cli_params.vad_samples_overlap;
  struct whisper_vad_segments * segments = whisper_vad_segments_from_probs(vctx, params);
  
  int segment_n = whisper_vad_segments_n_segments(segments);
  std::vector<float> probs;
  if(probabilities){
    int probs_n = whisper_vad_n_probs(vctx);
    auto prbo =  whisper_vad_probs(vctx);
    for (int i = 0; i < probs_n; ++i) {
      probs.push_back(prbo[i]);
    }  
  }
  std::vector<float> segment_nr;
  std::vector<float> segment_start;
  std::vector<float> segment_end;
  Rcpp::LogicalVector has_voice;
  for (int i = 0; i < segment_n; ++i) {
    float start = whisper_vad_segments_get_segment_t0(segments, i) / 1000;
    float end = whisper_vad_segments_get_segment_t1(segments, i) / 1000;
    segment_nr.push_back(i + 1);
    segment_start.push_back(start);
    segment_end.push_back(end);
    has_voice.push_back(true);
  }

  whisper_vad_free_segments(segments);
  whisper_vad_free(vctx);
  
  Rcpp::DataFrame items = Rcpp::DataFrame::create(
    Rcpp::Named("segment") = segment_nr, 
    Rcpp::Named("from") = segment_start, 
    Rcpp::Named("to") = segment_end, 
    Rcpp::Named("has_voice") = has_voice, 
    Rcpp::Named("stringsAsFactors") = false);
  Rcpp::List output = Rcpp::List::create(
    Rcpp::Named("n_segments") = segment_n,
    Rcpp::Named("probabilities") = probs,
    Rcpp::Named("data") = items,
    Rcpp::Named("params") = Rcpp::List::create(
      Rcpp::Named("audio") = path,
      Rcpp::Named("audio_duration_seconds") = audio_duration,
      Rcpp::Named("vad_model") = vad_model,
      Rcpp::Named("threshold") = vad_threshold,
      Rcpp::Named("min_speech_duration") = vad_min_speech_duration_ms,   // VAD min speech duration (0.0-1.0)
      Rcpp::Named("max_speech_duration") = vad_max_speech_duration_s,    // VAD max speech duration (auto-split longer)
      Rcpp::Named("min_silence_duration") = vad_min_silence_duration_ms, // VAD min silence duration (to split segments)
      Rcpp::Named("pad") = vad_speech_pad_ms,                     // VAD speech padding (extend segments)
      Rcpp::Named("overlap") = vad_samples_overlap,              // VAD samples overlap (seconds between segments)
      Rcpp::Named("use_gpu") = use_gpu,
      Rcpp::Named("n_threads") = n_threads
    )
  );
  return output;
}



