# audio.whisper

This repository contains an R package which is an Rcpp wrapper around the [whisper.cpp C++ library](https://github.com/ggerganov/whisper.cpp).

![](tools/logo-audio-whisper-x100.png)

- The package allows to transcribe audio files using the ["Whisper" Automatic Speech Recognition model](https://github.com/openai/whisper)
- The package is based on CPU-only inference engine written in C++11, no external software is needed, so that you can directly install and use it from R

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
trans <- predict(model, newdata = audio, language = "en", n_threads = 2)

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
[1] 11

$data
 segment         from           to                                                             text
       1 00:00:07.000 00:00:09.000                                             Look at the picture.
       2 00:00:09.000 00:00:11.000                                                   See the skull.
       3 00:00:11.000 00:00:13.000                                        The part of bone removed.
       4 00:00:13.000 00:00:16.000                     The master race Frankenstein radio controls.
       5 00:00:16.000 00:00:18.000                           The brain thoughts broadcasting radio.
       6 00:00:18.000 00:00:21.000        The eyesight television. The Frankenstein earphone radio.
       7 00:00:21.000 00:00:25.000  The threshold brain wash radio. The latest new skull reforming.
       8 00:00:25.000 00:00:28.000                            To contain all Frankenstein controls.
       9 00:00:28.000 00:00:31.000                     Even in thin skulls of white pedigree males.
      10 00:00:31.000 00:00:34.000                                   Visible Frankenstein controls.
      11 00:00:34.000 00:00:37.000            The synthetic nerve radio, directional and an alloop.

$tokens
 segment         token token_prob   token_from     token_to
       1          Look  0.4281234 00:00:07.290 00:00:07.420
       1            at  0.9485379 00:00:07.420 00:00:07.620
       1           the  0.9758387 00:00:07.620 00:00:07.940
       1       picture  0.9734664 00:00:08.150 00:00:08.580
       1             .  0.9688568 00:00:08.680 00:00:08.910
       2           See  0.9847929 00:00:09.000 00:00:09.420
       2           the  0.7588121 00:00:09.420 00:00:09.840
       2         skull  0.9989663 00:00:09.840 00:00:10.310
       2             .  0.9548351 00:00:10.550 00:00:11.000
       3           The  0.9914295 00:00:11.000 00:00:11.170
       3          part  0.9789217 00:00:11.560 00:00:11.600
       3            of  0.9958754 00:00:11.600 00:00:11.770
       3          bone  0.9759618 00:00:11.770 00:00:12.030
       3       removed  0.9956936 00:00:12.190 00:00:12.710
       3             .  0.9965582 00:00:12.710 00:00:12.940
       4           The  0.9923794 00:00:13.000 00:00:13.210
       4        master  0.9875370 00:00:13.350 00:00:13.640
       4          race  0.9803119 00:00:13.640 00:00:13.930
       4       Franken  0.9982004 00:00:13.930 00:00:14.440
       4         stein  0.9998384 00:00:14.440 00:00:14.800
       4         radio  0.9780943 00:00:14.800 00:00:15.160
       4      controls  0.9893969 00:00:15.160 00:00:15.700
       4             .  0.9796444 00:00:15.750 00:00:16.000
       5           The  0.9870584 00:00:16.000 00:00:16.140
       5         brain  0.9964160 00:00:16.330 00:00:16.430
       5      thoughts  0.9657190 00:00:16.490 00:00:16.870
       5  broadcasting  0.9860524 00:00:16.870 00:00:17.530
       5         radio  0.9439469 00:00:17.530 00:00:17.800
       5             .  0.9973570 00:00:17.800 00:00:17.960
       6           The  0.9774312 00:00:18.000 00:00:18.210
       6      eyesight  0.9293824 00:00:18.250 00:00:18.910
       6    television  0.9896797 00:00:18.910 00:00:19.690
       6             .  0.9961249 00:00:19.810 00:00:20.000
       6           The  0.5245560 00:00:20.000 00:00:20.090
       6       Franken  0.9829712 00:00:20.090 00:00:20.300
       6         stein  0.9999006 00:00:20.320 00:00:20.470
       6           ear  0.9958365 00:00:20.470 00:00:20.560
       6         phone  0.9876402 00:00:20.560 00:00:20.720
       6         radio  0.9854031 00:00:20.720 00:00:20.860
       6             .  0.9930948 00:00:20.950 00:00:21.000
       7           The  0.9887797 00:00:21.000 00:00:21.200
       7     threshold  0.9979410 00:00:21.200 00:00:21.750
       7         brain  0.9938735 00:00:21.880 00:00:22.160
       7          wash  0.9781434 00:00:22.160 00:00:22.430
       7         radio  0.9931799 00:00:22.430 00:00:22.770
       7             .  0.9941305 00:00:22.770 00:00:23.000
       7           The  0.5658014 00:00:23.000 00:00:23.230
       7        latest  0.9985833 00:00:23.230 00:00:23.690
       7           new  0.9956740 00:00:23.690 00:00:23.920
       7         skull  0.9990881 00:00:23.920 00:00:24.300
       7        reform  0.9664753 00:00:24.300 00:00:24.760
       7           ing  0.9966548 00:00:24.760 00:00:24.870
       7             .  0.9644036 00:00:25.000 00:00:25.000
       8            To  0.9600158 00:00:25.010 00:00:25.170
       8       contain  0.9938834 00:00:25.170 00:00:25.770
       8           all  0.9625537 00:00:25.770 00:00:26.020
       8       Franken  0.9710320 00:00:26.020 00:00:26.620
       8         stein  0.9998924 00:00:26.620 00:00:27.040
       8      controls  0.9955972 00:00:27.040 00:00:27.720
       8             .  0.9759502 00:00:27.720 00:00:28.000
       9          Even  0.9824280 00:00:28.000 00:00:28.300
       9            in  0.9928908 00:00:28.300 00:00:28.450
       9          thin  0.9970337 00:00:28.450 00:00:28.750
       9         skull  0.9954430 00:00:28.750 00:00:29.120
       9             s  0.9987136 00:00:29.120 00:00:29.180
       9            of  0.9772032 00:00:29.280 00:00:29.350
       9         white  0.9897125 00:00:29.350 00:00:29.720
       9           ped  0.9980962 00:00:29.810 00:00:29.960
       9            ig  0.9971448 00:00:29.960 00:00:30.100
       9           ree  0.9996273 00:00:30.100 00:00:30.320
       9         males  0.9934869 00:00:30.390 00:00:30.700
       9             .  0.9789821 00:00:30.780 00:00:30.990
      10           Vis  0.8950536 00:00:31.050 00:00:31.250
      10          ible  0.9988410 00:00:31.290 00:00:31.690
      10       Franken  0.9976653 00:00:31.690 00:00:32.360
      10         stein  0.9999056 00:00:32.430 00:00:32.880
      10      controls  0.9977503 00:00:32.880 00:00:33.670
      10             .  0.9917345 00:00:33.680 00:00:34.000
      11           The  0.9685771 00:00:34.000 00:00:34.180
      11     synthetic  0.9910653 00:00:34.180 00:00:34.730
      11         nerve  0.9979016 00:00:34.730 00:00:35.030
      11         radio  0.9594643 00:00:35.030 00:00:35.330
      11             ,  0.8811045 00:00:35.330 00:00:35.450
      11   directional  0.9930993 00:00:35.450 00:00:36.120
      11           and  0.8905478 00:00:36.120 00:00:36.300
      11            an  0.9520693 00:00:36.300 00:00:36.420
      11           all  0.7639735 00:00:36.420 00:00:36.600
      11           oop  0.9988559 00:00:36.600 00:00:36.730
      11             .  0.9924630 00:00:36.830 00:00:37.000
  ```
</details>






### Installation

- For installing the development version of this package: `remotes::install_github("bnosac/audio.whisper")`

Look to the documentation of the functions

```
help(package = "audio.whisper")
```

#### Compilation

Note: speed of the transcription depends highly on setting the C compilation flags `-mavx -mavx2 -mfma -mf16c` which depend on the computer you have running. You might need to change these compilations flags in [/src/Makevars](/src/Makevars) to tune the package to your needs.

## Support in text mining

Need support in text mining?
Contact BNOSAC: http://www.bnosac.be

