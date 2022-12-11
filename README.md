# audio.whisper

This repository contains an R package which is an Rcpp wrapper around the whisper.cpp C++ library (https://github.com/ggerganov/whisper.cpp).

The package allows to transcribe audio files using the "Whisper" Automatic Speech Recognition model

### Installation

- For regular users, install the package from your local CRAN mirror `install.packages("audio.whisper")`
- For installing the development version of this package: `remotes::install_github("bnosac/audio.whisper")`

Look to the documentation of the functions

```
help(package = "audio.whisper")
```

## Available models

- `tiny` & `tiny.en`: 75 MB, RAM required: ~390 MB. Multilingual and English only version.
- `base` & `base.en`: 142 MB, RAM required: ~500 MB. Multilingual and English only version.
- `small` & `small.en`: 466 MB, RAM required: ~1.0 GB. Multilingual and English only version.
- `medium` & `medium.en`: 1.5 GB, RAM required: ~2.6 GB. Multilingual and English only version.
- `large-v1` & `large`: 2.9 GB, RAM required: ~4.7 GB. Multilingual version 1 and version 2

## Example

- Load the model either by providing the full path to the model or specify the shorthand
- For a list of available models and to download a model, see the help of `whisper_download_model`

```
library(audio.whisper)
model <- whisper("tiny")
model <- whisper("base")
model <- whisper("small")
model <- whisper("medium")
model <- whisper("large")
```

- Make sure you have a 16-bit .wav file or use ffmpeg to create one based on an another format

```
ffmpeg                 -i 00-intro.wmv -ar 16000 -ac 1 -c:a pcm_s16le output.wav
ffmpeg                 -i input.mp3    -ar 16000 -ac 1 -c:a pcm_s16le output.wav
ffmpeg -loglevel -0 -y -i hp0.ogg      -ar 16000 -ac 1 -c:a pcm_s16le output.wav
```

- Transcribe the audio file using `predict(model, "path-to-file.wav")` and provide a language which the audio file is in (e.g. en, nl, fr, de, es, zh, ru, jp)

```
audio <- system.file(package = "audio.whisper", "samples", "jfk.wav")
trans <- predict(model, newdata = audio, language = "en")
trans$data
                                                                                                       text         from           to
  And so my fellow Americans ask not what your country can do for you ask what you can do for your country. 00:00:00.000 00:00:11.000
```

## Support in text mining

Need support in text mining?
Contact BNOSAC: http://www.bnosac.be

