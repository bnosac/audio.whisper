# audio.whisper

This repository contains an R package which is an Rcpp wrapper around the [whisper.cpp C++ library](https://github.com/ggerganov/whisper.cpp).

![](tools/logo-audio-whisper-x100.png)

- The package allows to transcribe audio files using the ["Whisper" Automatic Speech Recognition model](https://github.com/openai/whisper)
- The package is based on a direct C++ inference engine written in C++11, no external software is needed, so that you can directly install and use it from R


## Available models

| Model                  | Language                    |  Size  | RAM needed |
|:-----------------------|:---------------------------:|-------:|-----------:|
| `tiny` & `tiny.en`     | Multilingual & English only | 75 MB  | 390 MB     |
| `base` & `base.en`     | Multilingual & English only | 142 MB | 500 MB     |
| `small` & `small.en`   | Multilingual & English only | 466 MB | 1.0 GB     |
| `medium` & `medium.en` | Multilingual & English only | 1.5 GB | 2.6 GB     |
| `large-v1` & `large`   | Multilingual                | 2.9 GB | 4.7 GB     |

## Example

**Load the model** either by providing the full path to the model or specify the shorthand which will download the model
  - see the help of `whisper_download_model` for a list of available models and to download a model

```{r}
library(audio.whisper)
model <- whisper("tiny")
model <- whisper("base")
model <- whisper("small")
model <- whisper("medium")
model <- whisper("large")
```

**Transcribe a `.wav` audio file** 
  - using `predict(model, "path-to-file.wav")` and 
  - provide a language which the audio file is in (e.g. en, nl, fr, de, es, zh, ru, jp)

```{r}
audio <- system.file(package = "audio.whisper", "samples", "jfk.wav")
trans <- predict(model, newdata = audio, language = "en")
trans$data
                                                                                                       text         from           to
  And so my fellow Americans ask not what your country can do for you ask what you can do for your country. 00:00:00.000 00:00:11.000
```

Note about that the audio file needs to be a **`16-bit .wav` file**. 
  - you can use R package [`av`](https://cran.r-project.org/package=av) to convert to that format 
  - or alternatively, use `ffmpeg` to create one if you have another format. 

```{r}
library(av)
av_audio_convert("00-intro.wmv", output = "output.wav", format = "wav", verbose = TRUE, sample_rate = 16000)
predict(model, newdata = "output.wav", language = "nl")
```

```{bash}
ffmpeg                 -i input.wmv -ar 16000 -ac 1 -c:a pcm_s16le output.wav
ffmpeg                 -i input.mp3 -ar 16000 -ac 1 -c:a pcm_s16le output.wav
ffmpeg -loglevel -0 -y -i input.ogg -ar 16000 -ac 1 -c:a pcm_s16le output.wav
```


### Installation

- For installing the development version of this package: `remotes::install_github("bnosac/audio.whisper")`

Look to the documentation of the functions

```
help(package = "audio.whisper")
```

## Support in text mining

Need support in text mining?
Contact BNOSAC: http://www.bnosac.be

