######################################################################################v
## Speed evaluation on audio file from Ubu containing 398 seconds - 6.6 minutes
##  - using whisper medium model
##
######################################################################################
library(av)
download.file(url = "https://www.ubu.com/media/sound/dec_francis/Dec-Francis-E_rant1.mp3", 
              destfile = "rant1.mp3", mode = "wb")
av_audio_convert("rant1.mp3", output = "output.wav", format = "wav", sample_rate = 16000, channels = 1)
av_media_info("output.wav")
## 398 secs = 6.6 minutes

## Detect segments with voice, predict these
library(audio.vadwebrtc)
vad    <- VAD("output.wav")
voiced <- is.voiced(vad, units = "milliseconds")
voiced <- subset(voiced, has_voice == TRUE)

path  <- system.file(package = "audio.whisper", "repo", "ggml-tiny.en-q5_1.bin")
model <- whisper(path)
i <- 2
trans <- predict(model, newdata = "output.wav", language = "en", 
                 offset = voiced$start[i] * 1000, duration = 10000, trace = FALSE)
trans$data

## Function to make sure you unset environment variables relevant when installing audio.whisper
## to avoid mistakingly compiling with settings not wanted for the test
unset_whisper_env <- function(){
  Sys.unsetenv("WHISPER_CFLAGS")
  Sys.unsetenv("WHISPER_CPPFLAGS")
  Sys.unsetenv("WHISPER_LIBS")
  Sys.unsetenv("WHISPER_ACCELERATE")
  Sys.unsetenv("WHISPER_METAL")
  Sys.unsetenv("WHISPER_OPENBLAS")
}

##
## Install - default is with AVX intrinsics / SSE optimisations
##
unset_whisper_env()
remotes::install_github("bnosac/audio.whisper", force = TRUE)
##
## Install - no AVX / SSE optimisations
##
unset_whisper_env()
Sys.setenv(WHISPER_CFLAGS = "")
Sys.setenv(WHISPER_CPPFLAGS = "")
Sys.setenv(WHISPER_LIBS = "")
remotes::install_github("bnosac/audio.whisper", force = TRUE)
##
## Install - with OpenBLAS and default AVX / SSE optimisations 
##   note: on ubuntu install openblas with `sudo apt install libopenblas-dev`
unset_whisper_env()
Sys.setenv(WHISPER_OPENBLAS = TRUE)
remotes::install_github("bnosac/audio.whisper", force = TRUE)

##
## 
##
library(audio.whisper)
# Download the model if it does not exist yet
options(timeout = 60*10)
whisper_download_model("medium", model_dir = "inst/model-repository/1.5.4", version = "1.5.4", overwrite = FALSE)
# Load the model
model <- whisper("medium", model_dir = "inst/model-repository/1.5.4")
trans <- predict(model, newdata = "output.wav", language = "en", n_threads = 1, trace = TRUE)
trans$timing$duration
trans <- predict(model, newdata = "output.wav", language = "en", n_threads = 2, trace = TRUE)
trans$timing$duration
trans <- predict(model, newdata = "output.wav", language = "en", n_threads = 4, trace = TRUE)
trans$timing$duration

# 
# I whisper.cpp build info: 
# I UNAME_S:  Linux
# I UNAME_P:  x86_64
# I UNAME_M:  x86_64
# I PKG_CFLAGS:   -mavx -msse3 -mssse3 -DGGML_USE_OPENBLAS -L/usr/lib/x86_64-linux-gnu/openblas-pthread/ -lopenblas -D_XOPEN_SOURCE=600 -D_GNU_SOURCE -pthread
# I PKG_CPPFLAGS: -mavx -msse3 -mssse3 -DSTRICT_R_HEADERS -I./dr_libs -I./whisper_cpp  -D_XOPEN_SOURCE=600 -D_GNU_SOURCE -pthread
# I PKG_LIBS:   -I/usr/include/x86_64-linux-gnu/openblas-pthread/
