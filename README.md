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
  - using `predict(model, "path/to/audio/file.wav")` and 
  - provide a language which the audio file is in (e.g. en, nl, fr, de, es, zh, ru, jp)
  - the result contains the segments and the tokens

```{r}
audio <- system.file(package = "audio.whisper", "samples", "jfk.wav")
trans <- predict(model, newdata = audio, language = "en")
trans
$n_segments
[1] 1

$data
 segment         from           to                                                                                                       text
       1 00:00:00.000 00:00:11.000  And so my fellow Americans ask not what your country can do for you ask what you can do for your country.

$tokens
 segment      token token_prob
       1        And  0.7476438
       1         so  0.9042299
       1         my  0.6872202
       1     fellow  0.9984470
       1  Americans  0.9589157
       1        ask  0.2573057
       1        not  0.7678108
       1       what  0.6542882
       1       your  0.9386917
       1    country  0.9854987
       1        can  0.9813995
       1         do  0.9937403
       1        for  0.9791515
       1        you  0.9925495
       1        ask  0.3058807
       1       what  0.8303462
       1        you  0.9735528
       1        can  0.9711444
       1         do  0.9616748
       1        for  0.9778513
       1       your  0.9604713
       1    country  0.9923630
       1          .  0.4983074
```

### Format of the audio

Note about that the audio file needs to be a **`16-bit .wav` file**. 

  - you can use R package [`av`](https://cran.r-project.org/package=av) which provides bindings to ffmpeg to convert to that format 
  - or alternatively, use ffmpeg as follows: `ffmpeg -i input.wmv -ar 16000 -ac 1 -c:a pcm_s16le output.wav`

```{r}
library(av)
download.file(url = "https://www.ubu.com/media/sound/dec_francis/Dec-Francis-E_rant1.mp3", 
              destfile = "rant1.mp3", mode = "wb")
av_audio_convert("rant1.mp3", output = "output.wav", format = "wav", sample_rate = 16000)
```

<details>
  <summary>Transcription</summary>
  
  ```{r}
  trans <- predict(model, newdata = "output.wav", language = "en", 
                  duration = 30 * 1000, offset = 7 * 1000, 
                  token_timestamps = TRUE)
  trans
  $n_segments
[1] 3

$data
 segment         from           to
       1 00:00:07.000 00:00:09.000
       2 00:00:09.000 00:00:28.320
       3 00:00:28.320 00:00:47.560
                                                                                                                                                                                                                                                                                 text
                                                                                                                                                                                                                                                                 Look at the picture.
  See the skull the part of bone removed the master race Frankenstein radio controls the brain thoughts broadcasting radio the eyesight television the Frankenstein earphone radio the threshold brain wash radio the latest new skull reforming to contain all Frankenstein controls
               even in thin skulls of white pedigree males visible Frankenstein controls the synthetic nerve radio directional and a loop make copies for yourself there is no escape from this worst gangster police state using all of the deadly gangster Frankenstein controls in

$tokens
 segment         token token_prob   token_from     token_to
       1          Look  0.7920775 00:00:07.290 00:00:07.500
       1            at  0.9533587 00:00:07.500 00:00:07.740
       1           the  0.9930137 00:00:07.740 00:00:07.980
       1       picture  0.9866030 00:00:08.150 00:00:08.910
       1             .  0.4817685 00:00:08.910 00:00:09.000
       2           See  0.9027144 00:00:09.000 00:00:09.600
       2           the  0.9135954 00:00:09.770 00:00:10.200
       2         skull  0.9744173 00:00:10.200 00:00:11.140
       2           the  0.4147968 00:00:11.200 00:00:11.450
       2          part  0.9925929 00:00:11.560 00:00:11.790
       2            of  0.9942859 00:00:11.790 00:00:11.950
       2          bone  0.7485979 00:00:11.950 00:00:12.300
       2       removed  0.9494925 00:00:12.300 00:00:12.890
       2           the  0.8467007 00:00:12.890 00:00:13.360
       2        master  0.7950389 00:00:13.360 00:00:13.760
       2          race  0.7110081 00:00:13.840 00:00:14.080
       2       Franken  0.7477894 00:00:14.080 00:00:14.540
       2         stein  0.9990029 00:00:14.540 00:00:14.880
       2         radio  0.8894377 00:00:14.880 00:00:15.340
       2      controls  0.9662802 00:00:15.340 00:00:15.880
       2           the  0.7160608 00:00:15.880 00:00:16.110
       2         brain  0.8459664 00:00:16.330 00:00:16.600
       2      thoughts  0.8184410 00:00:16.600 00:00:16.960
       2  broadcasting  0.8433461 00:00:16.960 00:00:17.500
       2         radio  0.9331039 00:00:17.500 00:00:18.060
       2           the  0.6228318 00:00:18.060 00:00:18.480
       2      eyesight  0.7125033 00:00:18.480 00:00:18.920
       2    television  0.5934165 00:00:18.920 00:00:19.550
       2           the  0.6777228 00:00:19.570 00:00:19.840
       2       Franken  0.7760635 00:00:19.840 00:00:20.260
       2         stein  0.9995500 00:00:20.260 00:00:20.560
       2           ear  0.8032390 00:00:20.560 00:00:20.800
       2         phone  0.6547742 00:00:20.800 00:00:21.000
       2         radio  0.8285248 00:00:21.000 00:00:21.200
       2           the  0.7571419 00:00:21.200 00:00:21.760
       2     threshold  0.7179375 00:00:21.880 00:00:22.160
       2         brain  0.5357999 00:00:22.160 00:00:22.600
       2          wash  0.4780060 00:00:22.600 00:00:22.880
       2         radio  0.8037748 00:00:22.880 00:00:23.340
       2           the  0.5277757 00:00:23.340 00:00:23.530
       2        latest  0.9907051 00:00:23.650 00:00:24.000
       2           new  0.4997224 00:00:24.010 00:00:24.240
       2         skull  0.6668728 00:00:24.240 00:00:24.600
       2        reform  0.6319429 00:00:24.600 00:00:24.860
       2           ing  0.9930735 00:00:24.860 00:00:24.870
       2            to  0.8599300 00:00:25.010 00:00:25.600
       2       contain  0.9415731 00:00:25.600 00:00:26.000
       2           all  0.7361928 00:00:26.000 00:00:26.220
       2       Franken  0.4516768 00:00:26.310 00:00:27.090
       2         stein  0.9923787 00:00:27.090 00:00:27.640
       2      controls  0.6375496 00:00:27.640 00:00:28.320
       3          even  0.5591227 00:00:28.320 00:00:28.680
       3            in  0.9300127 00:00:28.680 00:00:28.860
       3          thin  0.9598754 00:00:28.860 00:00:29.140
       3         skull  0.9767514 00:00:29.280 00:00:29.670
       3             s  0.9711202 00:00:29.720 00:00:29.750
       3            of  0.8679969 00:00:29.810 00:00:29.940
       3         white  0.9912420 00:00:29.940 00:00:30.260
       3           ped  0.7761678 00:00:30.390 00:00:30.660
       3            ig  0.9073334 00:00:30.660 00:00:30.840
       3           ree  0.9624532 00:00:30.840 00:00:31.110
       3         males  0.8032146 00:00:31.110 00:00:31.560
       3       visible  0.9220356 00:00:31.560 00:00:32.100
       3       Franken  0.9878631 00:00:32.210 00:00:32.730
       3         stein  0.9992224 00:00:32.860 00:00:33.270
       3      controls  0.9944689 00:00:33.270 00:00:34.040
       3           the  0.9478271 00:00:34.040 00:00:34.190
       3     synthetic  0.9090462 00:00:34.320 00:00:34.950
       3         nerve  0.9520817 00:00:34.990 00:00:35.360
       3         radio  0.9673731 00:00:35.360 00:00:35.760
       3   directional  0.5604557 00:00:35.760 00:00:36.480
       3           and  0.7968725 00:00:36.480 00:00:36.920
       3             a  0.3190286 00:00:36.920 00:00:37.000
       3          loop  0.9506577 00:00:37.000 00:00:37.300
       3          make  0.7117329 00:00:37.400 00:00:37.920
       3        copies  0.9524156 00:00:37.920 00:00:38.320
       3           for  0.9619224 00:00:38.320 00:00:38.560
       3      yourself  0.9430138 00:00:38.560 00:00:38.960
       3         there  0.4097285 00:00:38.960 00:00:39.560
       3            is  0.9436054 00:00:39.560 00:00:39.710
       3            no  0.9109243 00:00:39.860 00:00:40.160
       3        escape  0.5427161 00:00:40.160 00:00:41.210
       3          from  0.9396328 00:00:41.390 00:00:41.480
       3          this  0.9665326 00:00:41.480 00:00:41.660
       3         worst  0.3676438 00:00:41.660 00:00:42.120
       3      gangster  0.8119254 00:00:42.120 00:00:43.040
       3        police  0.8284922 00:00:43.040 00:00:43.480
       3         state  0.9333297 00:00:43.480 00:00:43.800
       3         using  0.8431630 00:00:43.800 00:00:44.400
       3           all  0.9206151 00:00:44.400 00:00:44.640
       3            of  0.8506151 00:00:44.640 00:00:44.790
       3           the  0.9328284 00:00:44.790 00:00:44.880
       3        deadly  0.9050536 00:00:44.880 00:00:45.320
       3      gangster  0.9318002 00:00:45.320 00:00:45.840
       3       Franken  0.9444947 00:00:45.840 00:00:46.230
       3         stein  0.9946011 00:00:46.230 00:00:46.520
       3      controls  0.8644955 00:00:46.520 00:00:47.310
       3            in  0.7534380 00:00:47.320 00:00:47.560
  ```
</details>






### Installation

- For installing the development version of this package: `remotes::install_github("bnosac/audio.whisper")`

Look to the documentation of the functions

```
help(package = "audio.whisper")
```

## Support in text mining

Need support in text mining?
Contact BNOSAC: http://www.bnosac.be

