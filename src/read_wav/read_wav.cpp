#include <Rcpp.h>

// User dr_wav instead of read_audio_data in whisper.cpp as it needs stb_vorbis.c which does not compile well in Mac/Win making it not cross-platform
#define DR_WAV_IMPLEMENTATION
#include "dr_wav.h"
#include "read_wav.h"


bool read_wav(const std::string & fname, std::vector<float>& pcmf32, std::vector<std::vector<float>>& pcmf32s, bool stereo) {
  drwav wav;
  std::vector<uint8_t> wav_data; // used for pipe input from stdin
  
  if (fname == "-") {
    {
      uint8_t buf[1024];
      while (true)
      {
        const size_t n = fread(buf, 1, sizeof(buf), stdin);
        if (n == 0) {
          break;
        }
        wav_data.insert(wav_data.end(), buf, buf + n);
      }
    }
    
    if (drwav_init_memory(&wav, wav_data.data(), wav_data.size(), nullptr) == false) {
      Rprintf("error: failed to open WAV file from stdin\n");
      return false;
    }
    
    Rprintf("%s: read %zu bytes from stdin\n", __func__, wav_data.size());
  }
  else if (drwav_init_file(&wav, fname.c_str(), nullptr) == false) {
    Rprintf("error: failed to open '%s' as WAV file\n", fname.c_str());
    return false;
  }
  
  if (wav.channels != 1 && wav.channels != 2) {
    Rprintf("%s: WAV file '%s' must be mono or stereo\n", __func__, fname.c_str());
    return false;
  }
  
  if (stereo && wav.channels != 2) {
    Rprintf("%s: WAV file '%s' must be stereo for diarization\n", __func__, fname.c_str());
    return false;
  }
  
  if (wav.sampleRate != COMMON_SAMPLE_RATE) {
    Rprintf("%s: WAV file '%s' must be %i kHz\n", __func__, fname.c_str(), COMMON_SAMPLE_RATE/1000);
    return false;
  }
  
  if (wav.bitsPerSample != 16) {
    Rprintf("%s: WAV file '%s' must be 16-bit\n", __func__, fname.c_str());
    return false;
  }
  
  const uint64_t n = wav_data.empty() ? wav.totalPCMFrameCount : wav_data.size()/(wav.channels*wav.bitsPerSample/8);
  
  std::vector<int16_t> pcm16;
  pcm16.resize(n*wav.channels);
  drwav_read_pcm_frames_s16(&wav, n, pcm16.data());
  drwav_uninit(&wav);
  
  // convert to mono, float
  pcmf32.resize(n);
  if (wav.channels == 1) {
    for (uint64_t i = 0; i < n; i++) {
      pcmf32[i] = float(pcm16[i])/32768.0f;
    }
  } else {
    for (uint64_t i = 0; i < n; i++) {
      pcmf32[i] = float(pcm16[2*i] + pcm16[2*i + 1])/65536.0f;
    }
  }
  
  if (stereo) {
    // convert to stereo, float
    pcmf32s.resize(2);
    
    pcmf32s[0].resize(n);
    pcmf32s[1].resize(n);
    for (uint64_t i = 0; i < n; i++) {
      pcmf32s[0][i] = float(pcm16[2*i])/32768.0f;
      pcmf32s[1][i] = float(pcm16[2*i + 1])/32768.0f;
    }
  }
  
  return true;
}