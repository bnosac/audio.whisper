#include <Rcpp.h>
#include "common.h"
#include "common-whisper.h"

#include "whisper.h"
#include "grammar-parser.h"
#include "ggml.h"
#include "ggml-backend.h"

#include <cmath>
#include <fstream>
#include <cstdio>
#include <string>
#include <thread>
#include <vector>
#include <cstring>
#include <cfloat>

#if defined(_MSC_VER)
#pragma warning(disable: 4244 4267) // possible loss of data
#endif

//  500 -> 00:05.000
// 6000 -> 01:00.000
std::string rcpp_to_timestamp(int64_t t, bool comma = false) {
    int64_t msec = t * 10;
    int64_t hr = msec / (1000 * 60 * 60);
    msec = msec - hr * (1000 * 60 * 60);
    int64_t min = msec / (1000 * 60);
    msec = msec - min * (1000 * 60);
    int64_t sec = msec / 1000;
    msec = msec - sec * 1000;

    char buf[32];
    snprintf(buf, sizeof(buf), "%02d:%02d:%02d%s%03d", (int) hr, (int) min, (int) sec, comma ? "," : ".", (int) msec);

    return std::string(buf);
}

int rcpp_timestamp_to_sample(int64_t t, int n_samples) {
    return std::max(0, std::min((int) n_samples - 1, (int) ((t*WHISPER_SAMPLE_RATE)/100)));
}

// command-line parameters
struct whisper_params {
    int32_t n_threads     = std::min(4, (int32_t) std::thread::hardware_concurrency());
    int32_t n_processors  = 1;
    int32_t offset_t_ms   = 0;
    int32_t offset_n      = 0;
    int32_t duration_ms   = 0;
    int32_t progress_step = 5;
    int32_t max_context   = -1;
    int32_t max_len       = 0;
    int32_t best_of       = whisper_full_default_params(WHISPER_SAMPLING_GREEDY).greedy.best_of;
    int32_t beam_size     = whisper_full_default_params(WHISPER_SAMPLING_BEAM_SEARCH).beam_search.beam_size;
    int32_t audio_ctx     = 0;

    float word_thold      =  0.01f;
    float entropy_thold   =  2.40f;
    float logprob_thold   = -1.00f;
    float no_speech_thold =  0.6f;
    float grammar_penalty = 100.0f;
    float temperature     = 0.0f;
    float temperature_inc = 0.2f;

    bool debug_mode      = false;
    bool translate       = false;
    bool detect_language = false;
    bool diarize         = false;
    bool tinydiarize     = false;
    bool split_on_word   = false;
    bool no_fallback     = false;
    bool output_txt      = false;
    bool output_vtt      = false;
    bool output_srt      = false;
    bool output_wts      = false;
    bool output_csv      = false;
    bool output_jsn      = false;
    bool output_jsn_full = false;
    bool output_lrc      = false;
    bool no_prints       = false;
    bool print_special   = false;
    bool print_colors    = false;
    bool print_confidence= false;
    bool print_progress  = false;
    bool no_timestamps   = false;
    bool log_score       = false;
    bool use_gpu         = true;
    bool flash_attn      = true;
    bool suppress_nst    = false;

    std::string language  = "en";
    std::string prompt;
    std::string font_path = "/System/Library/Fonts/Supplemental/Courier New Bold.ttf";
    std::string model     = "models/ggml-base.en.bin";
    std::string grammar;
    std::string grammar_rule;

    // [TDRZ] speaker turn string
    std::string tdrz_speaker_turn = " [SPEAKER_TURN]"; // TODO: set from command line

    // A regular expression that matches tokens to suppress
    std::string suppress_regex;

    std::string openvino_encode_device = "CPU";

    std::string dtw = "";

    std::vector<std::string> fname_inp = {};
    std::vector<std::string> fname_out = {};

    grammar_parser::parse_state grammar_parsed;

    // Voice Activity Detection (VAD) parameters
    bool        vad           = false;
    std::string vad_model     = "";
    float       vad_threshold = 0.5f;
    int         vad_min_speech_duration_ms = 250;
    int         vad_min_silence_duration_ms = 100;
    float       vad_max_speech_duration_s = FLT_MAX;
    int         vad_speech_pad_ms = 30;
    float       vad_samples_overlap = 0.1f;
};


struct whisper_print_user_data {
    const whisper_params * params;

    const std::vector<std::vector<float>> * pcmf32s;
    int progress_prev;
};

std::string estimate_diarization_speaker(std::vector<std::vector<float>> pcmf32s, int64_t t0, int64_t t1, bool id_only = false, float energy_higher_percent = 1.1) {
    std::string speaker = "";
    const int64_t n_samples = pcmf32s[0].size();

    const int64_t is0 = rcpp_timestamp_to_sample(t0, n_samples);
    const int64_t is1 = rcpp_timestamp_to_sample(t1, n_samples);

    double energy0 = 0.0f;
    double energy1 = 0.0f;

    for (int64_t j = is0; j < is1; j++) {
        energy0 += fabs(pcmf32s[0][j]);
        energy1 += fabs(pcmf32s[1][j]);
    }

    if (energy0 > energy_higher_percent*energy1) {
        speaker = "0";
    } else if (energy1 > energy_higher_percent*energy0) {
        speaker = "1";
    } else {
        speaker = "?";
    }

    //printf("is0 = %lld, is1 = %lld, energy0 = %f, energy1 = %f, speaker = %s\n", is0, is1, energy0, energy1, speaker.c_str());

    if (!id_only) {
        speaker.insert(0, "(speaker ");
        speaker.append(")");
    }

    return speaker;
}
void whisper_print_progress_callback(struct whisper_context * /*ctx*/, struct whisper_state * /*state*/, int progress, void * user_data) {
    int progress_step = ((whisper_print_user_data *) user_data)->params->progress_step;
    int * progress_prev  = &(((whisper_print_user_data *) user_data)->progress_prev);
    if (progress >= *progress_prev + progress_step) {
        *progress_prev += progress_step;
        Rprintf("%s: progress = %3d%%\n", __func__, progress);
    }
}

void whisper_print_segment_callback(struct whisper_context * ctx, struct whisper_state * /*state*/, int n_new, void * user_data) {
    const auto & params  = *((whisper_print_user_data *) user_data)->params;

    const int n_segments = whisper_full_n_segments(ctx);

    std::string speaker = "";

    int64_t t0 = 0;
    int64_t t1 = 0;

    // print the last n_new segments
    const int s0 = n_segments - n_new;

    if (s0 == 0) {
        if(params.print_progress){
            Rprintf("\n");
        }
    }

    for (int i = s0; i < n_segments; i++) {
        if (!params.no_timestamps || params.diarize) {
            t0 = whisper_full_get_segment_t0(ctx, i);
            t1 = whisper_full_get_segment_t1(ctx, i);
        }
        const char * text = whisper_full_get_segment_text(ctx, i);
        if(params.print_progress){
          Rprintf("[%s --> %s]  %s%s\n", rcpp_to_timestamp(t0).c_str(), rcpp_to_timestamp(t1).c_str(), speaker.c_str(), text);  
        }
        Rcpp::checkUserInterrupt();
    }
}



// Functionality to free the Rcpp::XPtr
class WhisperModel {
    public: 
        struct whisper_context * ctx;
        WhisperModel(std::string model, bool use_gpu = false, bool flash_attn = true){
          ggml_backend_load_all();
          struct whisper_context_params cparams = whisper_context_default_params();
          cparams.use_gpu = use_gpu;
          cparams.flash_attn = flash_attn;
          ctx = whisper_init_from_file_with_params(model.c_str(), cparams);
        }
        ~WhisperModel(){
            whisper_free(ctx);
        }
};

// [[Rcpp::export]]
SEXP whisper_load_model(std::string model, bool use_gpu = false, bool flash_attn = true) {
    // Load language model and return the pointer to be used by whisper_encode
    //struct whisper_context * ctx = whisper_init(model.c_str());
    //Rcpp::XPtr<whisper_context> ptr(ctx, false);
    Rprintf("system_info: n_threads = %d / %d | %s\n", 1, std::thread::hardware_concurrency(), whisper_print_system_info());  
    WhisperModel * wp = new WhisperModel(model, use_gpu, flash_attn);
    Rcpp::XPtr<WhisperModel> ptr(wp, false);
    return ptr;
}
    

// [[Rcpp::export]]
Rcpp::List whisper_encode(SEXP model, std::string path, std::string language, 
                          bool token_timestamps = false, bool translate = false, Rcpp::IntegerVector duration = 0, Rcpp::IntegerVector offset = 0, int trace = 1,
                          int n_threads = 1, int n_processors = 1,
                          float entropy_thold = 2.40,
                          float logprob_thold = -1.00,
                          int beam_size = -1,
                          int best_of = 5,
                          bool split_on_word = false,
                          int max_context = -1,
                          std::string prompt = "",
                          bool print_special = false,
                          bool diarize = false,
                          float diarize_percent = 1.1,
                          bool no_timestamps = false) {
    float audio_duration=0;
  
    whisper_params params;
    params.language = language;
    params.translate = translate;
    params.print_special = print_special;
    params.duration_ms = duration[0];
    params.offset_t_ms = offset[0];
    params.fname_inp.push_back(path);
    params.n_threads = n_threads;
    params.n_processors = n_processors;
    
    params.entropy_thold = entropy_thold;
    params.logprob_thold = logprob_thold;
    params.beam_size = beam_size;
    params.best_of = best_of;
    params.split_on_word = split_on_word;
    params.max_context = max_context;
    params.prompt = prompt;
    params.diarize = diarize;
    params.no_timestamps = no_timestamps;
    if (params.fname_inp.empty()) {
        Rcpp::stop("error: no input files specified");
    }

    if (params.language != "auto" && whisper_lang_id(params.language.c_str()) == -1) {
        Rcpp::stop("Unknown language");
    }
    
    // whisper init
    Rcpp::XPtr<WhisperModel> whispermodel(model);
    struct whisper_context * ctx = whispermodel->ctx;
    //Rcpp::XPtr<whisper_context> ctx(model);
    //struct whisper_context * ctx = whisper_init(params.model.c_str());

    const auto fname_inp = params.fname_inp[0];
    std::vector<float> pcmf32;               // mono-channel F32 PCM
    std::vector<std::vector<float>> pcmf32s; // stereo-channel F32 PCM
    
    if (!::read_audio_data(fname_inp, pcmf32, pcmf32s, params.diarize)) {
      Rprintf("error: failed to read WAV file '%s'\n", fname_inp.c_str());
      Rcpp::stop("The input audio needs to be a 16-bit .wav file.");
    }
    
    if(trace > 0){
      Rprintf("system_info: n_threads = %d / %d | %s\n", params.n_threads*params.n_processors, std::thread::hardware_concurrency(), whisper_print_system_info());  
    }
    
    
    {
      if (!whisper_is_multilingual(ctx)) {
        if (params.language != "en" || params.translate) {
          params.language = "en";
          params.translate = false;
          Rcpp::warning("WARNING: model is not multilingual, ignoring language and translation options");
        }
      }
      if(trace > 0){
        Rcpp::Rcout << "Processing " << fname_inp << " (" << int(pcmf32.size()) << " samples, " << float(pcmf32.size())/WHISPER_SAMPLE_RATE << " sec)" << ", n_threads = " << params.n_threads << ", n_processors = " << params.n_processors << ", lang = " << params.language << ", translate = " << params.translate << ", timestamps = " << token_timestamps << ", beam_size = " << params.beam_size << ", best_of = " << params.best_of << "\n";
      }
    }
    audio_duration = float(pcmf32.size())/WHISPER_SAMPLE_RATE;
    
    // Structures to get the data back in R
    std::vector<int> segment_nr;
    std::vector<int> segment_offset;
    Rcpp::StringVector transcriptions(0);
    Rcpp::StringVector transcriptions_from(0);
    Rcpp::StringVector transcriptions_to(0);
    Rcpp::StringVector transcriptions_speaker(0);
    std::vector<int> token_segment_nr;
    std::vector<int> token_segment_id;
    std::vector<std::string> token_segment_text;
    std::vector<float> token_segment_probability;
    std::vector<std::string> token_segment_from;
    std::vector<std::string> token_segment_to;
    //Rcpp::StringVector token_speaker(0);
    int n_segments;
    
    for (int f = 0; f < (int) offset.size(); ++f) {
        // run the inference
        {
            whisper_full_params wparams = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);

            const bool use_grammar = (!params.grammar_parsed.rules.empty() && !params.grammar_rule.empty());
            wparams.strategy = (params.beam_size > 1 || use_grammar) ? WHISPER_SAMPLING_BEAM_SEARCH : WHISPER_SAMPLING_GREEDY;

            wparams.print_realtime   = false;
            wparams.print_progress   = false;
            if(trace > 0){
              wparams.print_progress = true;
              wparams.print_realtime = true;
            }
            wparams.print_timestamps = !params.no_timestamps;
            wparams.print_special    = params.print_special;
            wparams.translate        = params.translate;
            wparams.language         = params.language.c_str();
            wparams.detect_language  = params.detect_language;
            wparams.n_threads        = params.n_threads;
            wparams.n_max_text_ctx   = params.max_context >= 0 ? params.max_context : wparams.n_max_text_ctx;
            wparams.offset_ms        = (int) offset[f];
            wparams.duration_ms      = (int) duration[f];     
            
            wparams.token_timestamps = token_timestamps;
            wparams.thold_pt         = params.word_thold;
            wparams.max_len          = params.output_wts && params.max_len == 0 ? 60 : params.max_len;
            wparams.split_on_word    = params.split_on_word;
            wparams.audio_ctx        = params.audio_ctx;

            wparams.debug_mode       = params.debug_mode;

            wparams.tdrz_enable      = params.tinydiarize; // [TDRZ]

            wparams.suppress_regex   = params.suppress_regex.empty() ? nullptr : params.suppress_regex.c_str();

            wparams.initial_prompt   = params.prompt.c_str();

            wparams.greedy.best_of        = params.best_of;
            wparams.beam_search.beam_size = params.beam_size;

            wparams.temperature_inc  = params.no_fallback ? 0.0f : params.temperature_inc;
            wparams.temperature      = params.temperature;

            wparams.entropy_thold    = params.entropy_thold;
            wparams.logprob_thold    = params.logprob_thold;
            wparams.no_speech_thold  = params.no_speech_thold;

            wparams.no_timestamps    = params.no_timestamps;

            wparams.suppress_nst     = params.suppress_nst;

            wparams.vad            = params.vad;
            wparams.vad_model_path = params.vad_model.c_str();

            wparams.vad_params.threshold               = params.vad_threshold;
            wparams.vad_params.min_speech_duration_ms  = params.vad_min_speech_duration_ms;
            wparams.vad_params.min_silence_duration_ms = params.vad_min_silence_duration_ms;
            wparams.vad_params.max_speech_duration_s   = params.vad_max_speech_duration_s;
            wparams.vad_params.speech_pad_ms           = params.vad_speech_pad_ms;
            wparams.vad_params.samples_overlap         = params.vad_samples_overlap;

            whisper_print_user_data user_data = { &params, &pcmf32s, 0 };
            
            // this callback is called on each new segment
            if (!wparams.print_realtime) {
                wparams.new_segment_callback           = whisper_print_segment_callback;
                wparams.new_segment_callback_user_data = &user_data;
            }
            if(trace > 0 && offset.size() > 1){
              Rcpp::Rcout << "Processing audio offset section " << f+1 << " (" << wparams.offset_ms << " ms - " << wparams.offset_ms+wparams.duration_ms << " ms)\n";
            }
            
            Rprintf("whisper_full_parallel"); 
            if (whisper_full_parallel(ctx, wparams, pcmf32.data(), pcmf32.size(), params.n_processors) != 0) {
                Rcpp::stop("failed to process audio");
            }
            Rprintf("whisper_full_parallel done"); 
        }
        n_segments = whisper_full_n_segments(ctx);
        for (int i = 0; i < n_segments; ++i) {
          segment_nr.push_back(segment_nr.size() + 1);
          segment_offset.push_back(offset[f]);
          const char * text = whisper_full_get_segment_text(ctx, i);
          transcriptions.push_back(Rcpp::String(text));
          int64_t t0 = whisper_full_get_segment_t0(ctx, i);
          int64_t t1 = whisper_full_get_segment_t1(ctx, i);
          transcriptions_from.push_back(Rcpp::String(rcpp_to_timestamp(t0).c_str()));
          transcriptions_to.push_back(Rcpp::String(rcpp_to_timestamp(t1).c_str()));
          Rcpp::String channel_speaker;
          if (params.diarize && pcmf32s.size() == 2) {
            channel_speaker = Rcpp::String(estimate_diarization_speaker(pcmf32s, t0, t1, true, diarize_percent));
          }else{
            channel_speaker = NA_STRING;
          }    
          transcriptions_speaker.push_back(channel_speaker);
          
          for (int j = 0; j < whisper_full_n_tokens(ctx, i); ++j) {
            if (params.print_special == false) {
              const whisper_token id = whisper_full_get_token_id(ctx, i, j);
              if (id >= whisper_token_eot(ctx)) {
                continue;
              }
            }
            const char * text = whisper_full_get_token_text(ctx, i, j);
            const float  p    = whisper_full_get_token_p   (ctx, i, j);
            const int tokenid = whisper_full_get_token_id  (ctx, i, j);
            token_segment_nr.push_back(i + 1);
            token_segment_id.push_back(tokenid);
            std::string str(text);
            token_segment_text.push_back(str);
            token_segment_probability.push_back(p);
            if(token_timestamps){
              whisper_token_data token = whisper_full_get_token_data(ctx, i, j);
              t0 = token.t0;
              t1 = token.t1;
              token_segment_from.push_back(Rcpp::String(rcpp_to_timestamp(t0).c_str()));
              token_segment_to.push_back(rcpp_to_timestamp(token.t1));
            } 
            //token_speaker.push_back(channel_speaker);
          }
        }
    }
    Rcpp::DataFrame tokens;
    if(token_timestamps){
        tokens = Rcpp::DataFrame::create(
            Rcpp::Named("segment") = token_segment_nr, 
            Rcpp::Named("token_id") = token_segment_id, 
            Rcpp::Named("token") = token_segment_text, 
            Rcpp::Named("token_prob") = token_segment_probability,
            Rcpp::Named("token_from") = token_segment_from,
            Rcpp::Named("token_to") = token_segment_to,
            //Rcpp::Named("token_speaker") = token_speaker,
            Rcpp::Named("stringsAsFactors") = false);
    }else{
        tokens = Rcpp::DataFrame::create(
            Rcpp::Named("segment") = token_segment_nr, 
            Rcpp::Named("token_id") = token_segment_id, 
            Rcpp::Named("token") = token_segment_text, 
            Rcpp::Named("token_prob") = token_segment_probability,
            //Rcpp::Named("token_speaker") = token_speaker,
            Rcpp::Named("stringsAsFactors") = false);
    }
    
    //whisper_free(ctx);
    Rcpp::List output = Rcpp::List::create(Rcpp::Named("n_segments") = segment_nr.size(),
                                           Rcpp::Named("data") = Rcpp::DataFrame::create(
                                               Rcpp::Named("segment") = segment_nr, 
                                               Rcpp::Named("segment_offset") = segment_offset, 
                                               Rcpp::Named("from") = transcriptions_from,
                                               Rcpp::Named("to") = transcriptions_to,
                                               Rcpp::Named("text") = transcriptions, 
                                               Rcpp::Named("speaker") = transcriptions_speaker,
                                               Rcpp::Named("stringsAsFactors") = false),
                                           Rcpp::Named("tokens") = tokens,
                                           Rcpp::Named("params") = Rcpp::List::create(
                                               Rcpp::Named("audio") = path,
                                               Rcpp::Named("audio_duration_seconds") = audio_duration,
                                               Rcpp::Named("language") = params.language, 
                                               Rcpp::Named("offset") = offset,
                                               Rcpp::Named("duration") = duration,
                                               Rcpp::Named("translate") = params.translate,
                                               Rcpp::Named("token_timestamps") = token_timestamps,
                                               Rcpp::Named("word_threshold") = params.word_thold,
                                               Rcpp::Named("entropy_thold") = params.entropy_thold,
                                               Rcpp::Named("logprob_thold") = params.logprob_thold,
                                               Rcpp::Named("beam_size") = params.beam_size,
                                               Rcpp::Named("best_of") = params.best_of,
                                               Rcpp::Named("split_on_word") = params.split_on_word,
                                               Rcpp::Named("diarize") = params.diarize,
                                               Rcpp::Named("system_info") = Rcpp::List::create(
                                                 Rcpp::Named("n_threads") = params.n_threads,
                                                 Rcpp::Named("n_processors") = params.n_processors,
                                                 Rcpp::Named("available_concurrency") = std::thread::hardware_concurrency(),
                                                 Rcpp::Named("optimisations") = whisper_print_system_info())));
    return output;
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
