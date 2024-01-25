#include <Rcpp.h>
#include "common.h"

#include "whisper.h"

#include <cmath>
#include <fstream>
#include <cstdio>
#include <string>
#include <thread>
#include <vector>
#include <cstring>

#if defined(_MSC_VER)
#pragma warning(disable: 4244 4267) // possible loss of data
#endif

// Terminal color map. 10 colors grouped in ranges [0.0, 0.1, ..., 0.9]
// Lowest is red, middle is yellow, highest is green.
const std::vector<std::string> k_colors = {
    "\033[38;5;196m", "\033[38;5;202m", "\033[38;5;208m", "\033[38;5;214m", "\033[38;5;220m",
    "\033[38;5;226m", "\033[38;5;190m", "\033[38;5;154m", "\033[38;5;118m", "\033[38;5;82m",
};

//  500 -> 00:05.000
// 6000 -> 01:00.000
std::string to_timestamp(int64_t t, bool comma = false) {
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

int timestamp_to_sample(int64_t t, int n_samples) {
    return std::max(0, std::min((int) n_samples - 1, (int) ((t*WHISPER_SAMPLE_RATE)/100)));
}

// helper function to replace substrings
void replace_all(std::string & s, const std::string & search, const std::string & replace) {
    for (size_t pos = 0; ; pos += replace.length()) {
        pos = s.find(search, pos);
        if (pos == std::string::npos) break;
        s.erase(pos, search.length());
        s.insert(pos, replace);
    }
}

// command-line parameters
struct whisper_params {
    int32_t n_threads    = std::min(4, (int32_t) std::thread::hardware_concurrency());
    int32_t n_processors =  1;
    int32_t offset_t_ms  =  0;
    int32_t offset_n     =  0;
    int32_t duration_ms  =  0;
    int32_t progress_step =  5;
    int32_t max_context  = -1;
    int32_t max_len      =  0;
    int32_t best_of      = whisper_full_default_params(WHISPER_SAMPLING_GREEDY).greedy.best_of;
    int32_t beam_size    = whisper_full_default_params(WHISPER_SAMPLING_BEAM_SEARCH).beam_search.beam_size;

    float word_thold    =  0.01f;
    float entropy_thold =  2.40f;
    float logprob_thold = -1.00f;

    bool speed_up        = false;
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
    bool print_special   = false;
    bool print_colors    = false;
    bool print_progress  = false;
    bool no_timestamps   = false;
    bool log_score       = false;
    bool use_gpu         = true;

    std::string language  = "en";
    std::string prompt;
    std::string font_path = "/System/Library/Fonts/Supplemental/Courier New Bold.ttf";
    std::string model     = "models/ggml-base.en.bin";

    // [TDRZ] speaker turn string
    std::string tdrz_speaker_turn = " [SPEAKER_TURN]"; // TODO: set from command line

    std::string openvino_encode_device = "CPU";

    std::vector<std::string> fname_inp = {};
    std::vector<std::string> fname_out = {};
};


struct whisper_print_user_data {
    const whisper_params * params;

    const std::vector<std::vector<float>> * pcmf32s;
    int progress_prev;
};

std::string estimate_diarization_speaker(std::vector<std::vector<float>> pcmf32s, int64_t t0, int64_t t1, bool id_only = false) {
    std::string speaker = "";
    const int64_t n_samples = pcmf32s[0].size();

    const int64_t is0 = timestamp_to_sample(t0, n_samples);
    const int64_t is1 = timestamp_to_sample(t1, n_samples);

    double energy0 = 0.0f;
    double energy1 = 0.0f;

    for (int64_t j = is0; j < is1; j++) {
        energy0 += fabs(pcmf32s[0][j]);
        energy1 += fabs(pcmf32s[1][j]);
    }

    if (energy0 > 1.1*energy1) {
        speaker = "0";
    } else if (energy1 > 1.1*energy0) {
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
        fprintf(stderr, "%s: progress = %3d%%\n", __func__, progress);
    }
}

void whisper_print_segment_callback(struct whisper_context * ctx, struct whisper_state * /*state*/, int n_new, void * user_data) {
    const auto & params  = *((whisper_print_user_data *) user_data)->params;
    const auto & pcmf32s = *((whisper_print_user_data *) user_data)->pcmf32s;

    const int n_segments = whisper_full_n_segments(ctx);

    std::string speaker = "";

    int64_t t0 = 0;
    int64_t t1 = 0;

    // print the last n_new segments
    const int s0 = n_segments - n_new;

    if (s0 == 0) {
        printf("\n");
    }

    for (int i = s0; i < n_segments; i++) {
        if (!params.no_timestamps || params.diarize) {
            t0 = whisper_full_get_segment_t0(ctx, i);
            t1 = whisper_full_get_segment_t1(ctx, i);
        }

        if (!params.no_timestamps) {
            printf("[%s --> %s]  ", to_timestamp(t0).c_str(), to_timestamp(t1).c_str());
        }

        if (params.diarize && pcmf32s.size() == 2) {
            speaker = estimate_diarization_speaker(pcmf32s, t0, t1);
        }

        if (params.print_colors) {
            for (int j = 0; j < whisper_full_n_tokens(ctx, i); ++j) {
                if (params.print_special == false) {
                    const whisper_token id = whisper_full_get_token_id(ctx, i, j);
                    if (id >= whisper_token_eot(ctx)) {
                        continue;
                    }
                }

                const char * text = whisper_full_get_token_text(ctx, i, j);
                const float  p    = whisper_full_get_token_p   (ctx, i, j);

                const int col = std::max(0, std::min((int) k_colors.size() - 1, (int) (std::pow(p, 3)*float(k_colors.size()))));

                printf("%s%s%s%s", speaker.c_str(), k_colors[col].c_str(), text, "\033[0m");
            }
        } else {
            const char * text = whisper_full_get_segment_text(ctx, i);

            printf("%s%s", speaker.c_str(), text);
        }

        if (params.tinydiarize) {
            if (whisper_full_get_segment_speaker_turn_next(ctx, i)) {
                printf("%s", params.tdrz_speaker_turn.c_str());
            }
        }

        // with timestamps or speakers: each segment on new line
        if (!params.no_timestamps || params.diarize) {
            printf("\n");
        }

        fflush(stdout);
    }
}



// Functionality to free the Rcpp::XPtr
class WhisperModel {
    public: 
        struct whisper_context * ctx;
        WhisperModel(std::string model){
          struct whisper_context_params cparams;
          cparams.use_gpu = false;
          ctx = whisper_init_from_file_with_params(model.c_str(), cparams);
        }
        ~WhisperModel(){
            whisper_free(ctx);
        }
};

// [[Rcpp::export]]
SEXP whisper_load_model(std::string model) {
    // Load language model and return the pointer to be used by whisper_encode
    //struct whisper_context * ctx = whisper_init(model.c_str());
    //Rcpp::XPtr<whisper_context> ptr(ctx, false);
    WhisperModel * wp = new WhisperModel(model);
    Rcpp::XPtr<WhisperModel> ptr(wp, false);
    return ptr;
}
    

// [[Rcpp::export]]
Rcpp::List whisper_encode(SEXP model, std::string path, std::string language, 
                          bool token_timestamps = false, bool translate = false, bool print_special = false, int duration = 0, int offset = 0, bool trace = false,
                          int n_threads = 1, int n_processors = 1,
                          float entropy_thold = 2.40,
                          float logprob_thold = -1.00,
                          int beam_size = -1,
                          int best_of = 5,
                          bool split_on_word = false,
                          int max_context = -1) {
    whisper_params params;
    params.language = language;
    params.translate = translate;
    params.print_special = print_special;
    params.duration_ms = duration;
    params.offset_t_ms = offset;
    params.fname_inp.push_back(path);
    params.n_threads = n_threads;
    params.n_processors = n_processors;
    
    params.entropy_thold = entropy_thold;
    params.logprob_thold = logprob_thold;
    params.beam_size = beam_size;
    params.best_of = best_of;
    params.split_on_word = split_on_word;
    params.max_context = max_context;
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
        
    for (int f = 0; f < (int) params.fname_inp.size(); ++f) {
        const auto fname_inp = params.fname_inp[f];
        std::vector<float> pcmf32;               // mono-channel F32 PCM
        std::vector<std::vector<float>> pcmf32s; // stereo-channel F32 PCM

        if (!::read_wav(fname_inp, pcmf32, pcmf32s, params.diarize)) {
          Rprintf("error: failed to read WAV file '%s'\n", fname_inp.c_str());
          Rcpp::stop("The input audio needs to be a 16-bit .wav file.");
        }
        
        /*
        // print system information
        {
            fprintf(stderr, "\n");
            fprintf(stderr, "system_info: n_threads = %d / %d | %s\n",
                    params.n_threads*params.n_processors, std::thread::hardware_concurrency(), whisper_print_system_info());
        }
        */
        {
            if (!whisper_is_multilingual(ctx)) {
                if (params.language != "en" || params.translate) {
                    params.language = "en";
                    params.translate = false;
                    Rcpp::warning("WARNING: model is not multilingual, ignoring language and translation options");
                }
            }
            Rcpp::Rcout << "Processing " << fname_inp << " (" << int(pcmf32.size()) << " samples, " << float(pcmf32.size())/WHISPER_SAMPLE_RATE << " sec)" << ", lang = " << params.language << ", translate = " << params.translate << ", timestamps = " << token_timestamps << ", beam_size = " << params.beam_size << ", best_of = " << params.best_of << "\n";
        }
        
        // run the inference
        {
            whisper_full_params wparams = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
            
            wparams.strategy = params.beam_size > 1 ? WHISPER_SAMPLING_BEAM_SEARCH : WHISPER_SAMPLING_GREEDY;

            wparams.print_realtime   = false;
            wparams.print_progress   = params.print_progress;
            wparams.print_timestamps = !params.no_timestamps;
            wparams.print_special    = params.print_special;
            wparams.translate        = params.translate;
            wparams.language         = params.language.c_str();
            wparams.detect_language  = params.detect_language;
            wparams.n_threads        = params.n_threads;
            wparams.n_max_text_ctx   = params.max_context >= 0 ? params.max_context : wparams.n_max_text_ctx;
            wparams.offset_ms        = params.offset_t_ms;
            wparams.duration_ms      = params.duration_ms;

            wparams.token_timestamps = params.output_wts || params.output_jsn_full || params.max_len > 0;
            wparams.thold_pt         = params.word_thold;
            wparams.max_len          = params.output_wts && params.max_len == 0 ? 60 : params.max_len;
            wparams.split_on_word    = params.split_on_word;

            wparams.speed_up         = params.speed_up;
            wparams.debug_mode       = params.debug_mode;

            wparams.tdrz_enable      = params.tinydiarize; // [TDRZ]

            wparams.initial_prompt   = params.prompt.c_str();

            wparams.greedy.best_of        = params.best_of;
            wparams.beam_search.beam_size = params.beam_size;

            wparams.temperature_inc  = params.no_fallback ? 0.0f : wparams.temperature_inc;
            wparams.entropy_thold    = params.entropy_thold;
            wparams.logprob_thold    = params.logprob_thold;
            
            whisper_print_user_data user_data = { &params, &pcmf32s, 0 };
            
            // this callback is called on each new segment
            if (!wparams.print_realtime) {
                wparams.new_segment_callback           = whisper_print_segment_callback;
                wparams.new_segment_callback_user_data = &user_data;
            }
            
            // examples for abort mechanism
            // in examples below, we do not abort the processing, but we could if the flag is set to true

            // the callback is called before every encoder run - if it returns false, the processing is aborted
            {
                static bool is_aborted = false; // NOTE: this should be atomic to avoid data race

                wparams.encoder_begin_callback = [](struct whisper_context * /*ctx*/, struct whisper_state * /*state*/, void * user_data) {
                    bool is_aborted = *(bool*)user_data;
                    return !is_aborted;
                };
                wparams.encoder_begin_callback_user_data = &is_aborted;
            }

            // the callback is called before every computation - if it returns true, the computation is aborted
            {
                static bool is_aborted = false; // NOTE: this should be atomic to avoid data race

                wparams.abort_callback = [](void * user_data) {
                    bool is_aborted = *(bool*)user_data;
                    return is_aborted;
                };
                wparams.abort_callback_user_data = &is_aborted;
            }
            
            if (whisper_full_parallel(ctx, wparams, pcmf32.data(), pcmf32.size(), params.n_processors) != 0) {
                Rcpp::stop("failed to process audio");
            }
        }
    }
    
    // Get the data back in R
    const int n_segments = whisper_full_n_segments(ctx);
    std::vector<int> segment_nr;
    Rcpp::StringVector transcriptions(n_segments);
    Rcpp::StringVector transcriptions_from(n_segments);
    Rcpp::StringVector transcriptions_to(n_segments);
    std::vector<int> token_segment_nr;
    std::vector<int> token_segment_id;
    std::vector<std::string> token_segment_text;
    std::vector<float> token_segment_probability;
    std::vector<std::string> token_segment_from;
    std::vector<std::string> token_segment_to;
    for (int i = 0; i < n_segments; ++i) {
        segment_nr.push_back(i + 1);
        const char * text = whisper_full_get_segment_text(ctx, i);
        transcriptions[i] = Rcpp::String(text);
        int64_t t0 = whisper_full_get_segment_t0(ctx, i);
        int64_t t1 = whisper_full_get_segment_t1(ctx, i);
        transcriptions_from[i] = Rcpp::String(to_timestamp(t0).c_str());
        transcriptions_to[i] = Rcpp::String(to_timestamp(t1).c_str());
        
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
                token_segment_from.push_back(Rcpp::String(to_timestamp(t0).c_str()));
                token_segment_to.push_back(to_timestamp(token.t1));
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
            Rcpp::Named("stringsAsFactors") = false);
    }else{
        tokens = Rcpp::DataFrame::create(
            Rcpp::Named("segment") = token_segment_nr, 
            Rcpp::Named("token_id") = token_segment_id, 
            Rcpp::Named("token") = token_segment_text, 
            Rcpp::Named("token_prob") = token_segment_probability,
            Rcpp::Named("stringsAsFactors") = false);
    }
    
    //whisper_free(ctx);
    Rcpp::List output = Rcpp::List::create(Rcpp::Named("n_segments") = n_segments,
                                           Rcpp::Named("data") = Rcpp::DataFrame::create(
                                               Rcpp::Named("segment") = segment_nr, 
                                               Rcpp::Named("from") = transcriptions_from,
                                               Rcpp::Named("to") = transcriptions_to,
                                               Rcpp::Named("text") = transcriptions, 
                                               Rcpp::Named("stringsAsFactors") = false),
                                           Rcpp::Named("tokens") = tokens,
                                           Rcpp::Named("params") = Rcpp::List::create(
                                               Rcpp::Named("audio") = path,
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
                                               Rcpp::Named("split_on_word") = params.split_on_word));
    

    
    return output;
}



/*
// [[Rcpp::export]]
void whisper_print_benchmark(SEXP model, int n_threads = 1) {
  whisper_params params;
  params.n_threads = n_threads;
  // whisper init
  Rcpp::XPtr<WhisperModel> whispermodel(model);
  struct whisper_context * ctx = whispermodel->ctx;
  Rprintf("\n");
  Rprintf("system_info: n_threads = %d / %d | %s\n", params.n_threads, std::thread::hardware_concurrency(), whisper_print_system_info());
  if (int ret = whisper_set_mel(ctx, nullptr, 0, WHISPER_N_MEL)) {
    Rprintf("error: failed to set mel: %d\n", ret);
  }
  if (int ret = whisper_encode(ctx, 0, params.n_threads) != 0) {
    Rprintf("error: failed to encode model: %d\n", ret);
  }
  whisper_print_timings(ctx);
}
 */