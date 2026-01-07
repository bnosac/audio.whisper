# audio.whisper

This repository contains an R package which is an Rcpp wrapper around the [whisper.cpp C++ library](https://github.com/ggerganov/whisper.cpp).

![](tools/logo-audio-whisper-x100.png)

- The package allows to transcribe audio files using the ["Whisper" Automatic Speech Recognition model](https://github.com/openai/whisper)
- The package is based on an inference engine written in C++11, no external software is needed, so that you can directly install and use it from R

[![Actions Status](https://github.com/bnosac/audio.whisper/workflows/R-CMD-check/badge.svg)](https://github.com/bnosac/audio.whisper/actions)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## Available models

| Model                  | Language                    |  Size  | RAM needed | Comment                      |
|:-----------------------|:---------------------------:|-------:|-----------:|-----------------------------:|
| `tiny` & `tiny.en`     | Multilingual & English only | 75 MB  | 390 MB     | audio.whisper >=0.3 & 0.2.2  |
| `base` & `base.en`     | Multilingual & English only | 142 MB | 500 MB     | audio.whisper >=0.3 & 0.2.2  |
| `small` & `small.en`   | Multilingual & English only | 466 MB | 1.0 GB     | audio.whisper >=0.3 & 0.2.2  |
| `medium` & `medium.en` | Multilingual & English only | 1.5 GB | 2.6 GB     | audio.whisper >=0.3 & 0.2.2  |
| `large-v1`             | Multilingual                | 2.9 GB | 4.7 GB     | audio.whisper >=0.3 & 0.2.2  |
| `large-v2`             | Multilingual                | 2.9 GB | 4.7 GB     | audio.whisper >=0.3          |
| `large-v3`             | Multilingual                | 2.9 GB | 4.7 GB     | audio.whisper >=0.3          |
| `large-v3-turbo`       | Multilingual                | 1.5 GB | 2.6 GB     | audio.whisper >=0.5.0        |

Available quantized models are:

- tiny-q5_1, tiny-q8_0, tiny.en-q5_1, tiny.en-q8_0
- base-q5_1, base-q8_0, base.en-q5_1, base.en-q8_0
- small-q5_1, small-q8_0, small.en-q5_1, small.en-q8_0
- medium-q5_0, medium-q8_0, medium.en-q5_0, medium.en-q8_0
- large-v2-q5_0, large-v2-q8_0, large-v3-q5_0
- large-v3-turbo-q5_0, large-v3-turbo-q8_0

If you need specialised models, you can download other gguf whisper.cpp-compatible models from Huggingface - e.g. [distilled models](https://huggingface.co/distil-whisper)

### Installation

For the *stable* version of this package: 

- `remotes::install_github("bnosac/audio.whisper")`                (audio.whisper 0.5.0, uses whisper.cpp 1.8.2)
- `remotes::install_github("bnosac/audio.whisper", ref = "0.4.1")` (audio.whisper 0.4.1, uses whisper.cpp 1.5.4)
- `remotes::install_github("bnosac/audio.whisper", ref = "0.3.3")` (audio.whisper 0.3.3, uses whisper.cpp 1.5.4)
- `remotes::install_github("bnosac/audio.whisper", ref = "0.2.2")` (audio.whisper 0.2.2, uses whisper.cpp 1.2.1)

> From version 0.5.0 of audio.whisper, you need to have cmake installed to be able to install the package (e.g. apt-get install cmake / brew install cmake / for Windows go to cmake.org).

Look to the documentation of the functions: `help(package = "audio.whisper")`

- For the *development* version of this package: `remotes::install_github("bnosac/audio.whisper")`
- Once you gain familiarity with the flow, you can gain faster transcription speeds [by reading this section](#speed-of-transcribing).

## Example

**Load the model** either by providing the full path to the model or specify the shorthand which will download the model
  - see the help of `whisper_download_model` for a list of available models and to download a model
  - you can always download the model manually at https://huggingface.co/ggerganov/whisper.cpp

```{r}
library(audio.whisper)
model <- whisper("tiny")
model <- whisper("base")
model <- whisper("small")
model <- whisper("medium")
model <- whisper("large-v1")
model <- whisper("large-v2")
model <- whisper("large-v3")
model <- whisper("large-v3-turbo")
model <- whisper("large-v3-turbo-q8_0")
path  <- system.file(package = "audio.whisper", "repo", "ggml-tiny.en-q5_1.bin")
model <- whisper(path)
```

  - If you have a GPU (e.g. Mac with Metal or Linux with CUDA and [installed audio.whisper as indicated below](#speed-of-transcribing)), you can use it by specifying `use_gpu`, otherwise you will use your CPU.
      - `model <- whisper("medium", use_gpu = TRUE)`
  - If you want to use Flash Attention
     - `model <- whisper("medium", use_gpu = TRUE, flash_attn = TRUE)`

**Transcribe a `.wav` audio file** 
  - using `predict(model, "path/to/audio/file.wav")` and 
  - provide a language which the audio file is in (e.g. en, nl, fr, de, es, zh, ru, jp or others listed up in `whisper_languages()`)
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

Note that the audio file needs to be a **`16000Hz 16-bit .wav` file**. 

  - you can use R package [`av`](https://cran.r-project.org/package=av) which provides bindings to ffmpeg to convert to that format as shown below
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


-----

### Notes on silences

If you want remove silences from your audio files, it's now possible since audio.whisper 0.5.0 to use the integrated Voice Activity Detection which uses the [Silero](https://github.com/snakers4/silero-vad/) v5.1.2 LSTM model.

```{bash}
library(audio.whisper)
model <- whisper("medium", use_gpu = TRUE, flash_attn = TRUE)
audio <- system.file(package = "audio.whisper", "samples", "jfk.wav")
trans <- predict(model, newdata = audio, language = "en", n_threads = 2, 
                 vad = TRUE, vad_min_speech_duration_ms = 250, vad_min_silence_duration_ms = 100)
```

Alternatively, you could use R packages and pass on the selected voiced segments to the predict function

- [audio.vadwebrtc](https://github.com/bnosac/audio.vadwebrtc)
- [audio.vadsilero](https://github.com/bnosac/audio.vadsilero)


-----

### Speed of transcribing

Next to using the arguments `n_threads` and doing the transcription with a quantised model, 
the main way to improve the transcription speed is either to have a GPU or use another matrix library like OpenBlas or to compile the package with SIMD instructions enabled. 
For this to work you need to set some compilation instructions when installing the package.

#### For the latest version of audio.whisper (>= 0.5.0)

The default cmake setup from `whisper.cpp` is used to compile the package. 
To speed up transcriptions you set cmake compilation instructions by setting the environment variable 
`WHISPER_CMAKE_FLAGS` before installing the package.


##### Linux

> If you have a Linux machine with OpenBlas installed on a CPU machine (e.g. `apt-get install -y libopenblas-dev`)

```
Sys.setenv(WHISPER_CMAKE_FLAGS = "-DGGML_BLAS=1")
remotes::install_github("bnosac/audio.whisper", force = TRUE)
Sys.unsetenv("WHISPER_CMAKE_FLAGS")
```

> If you have a Linux machine with CUDA enabled GPU

- Make sure the nvcc compiler is in your PATH
- Make sure that the LD_LIBRARY_PATH is set such that the package can link to the cuda libraries
- Make sure CUDA_PATH is set to the path where CUDA is installed
- Example at https://github.com/bnosac/images/blob/main/whisper/Dockerfile.cuda#L7-L13
- Change -DCMAKE_CUDA_ARCHITECTURES according to your specs. For example if you run on 
  - NVIDIA T4 GPU's, `-DCMAKE_CUDA_ARCHITECTURES='75'` (Turing architecture, e.g. g4dn on AWS)
  - NVIDIA L4 GPU's, `-DCMAKE_CUDA_ARCHITECTURES='89'` (Ada Lovelace architecture, e.g. g6 on AWS)
    
```
Sys.setenv(WHISPER_CMAKE_FLAGS="-DGGML_CUDA=1 -DCMAKE_CUDA_COMPILER=nvcc -DCMAKE_CUDA_ARCHITECTURES=native -DGGML_BLAS=1 -DGGML_BLAS_VENDOR=OpenBlas")
remotes::install_github("bnosac/audio.whisper", force = TRUE)
Sys.unsetenv("WHISPER_CMAKE_FLAGS")
```

##### MacOS

> If you have a Mac with Accelerate or GPU with the METAL framework, both are enabled by default. So normally you don't need to do anything.

```
Sys.setenv(WHISPER_CMAKE_FLAGS = "-DGGML_ACCELERATE=1 -DGGML_METAL=1")
remotes::install_github("bnosac/audio.whisper", force = TRUE)
Sys.unsetenv("WHISPER_CMAKE_FLAGS")
```

##### Windows

> If you are on Windows and your hardware allows specific compilation with specific SIMD instructions sets

```
Sys.setenv(WHISPER_CMAKE_FLAGS="-DGGML_AVX=0 -DGGML_AVX2=1 -DGGML_SSE42=0 -DGGML_F16C=1 -DGGML_FMA=1 -DGGML_BMI2=0")
remotes::install_github("bnosac/audio.whisper", force = TRUE)
Sys.unsetenv("WHISPER_CMAKE_FLAGS")
```

> If you are on Windows and you have an NVIDIA GPU. 

- The easiest make the library use the GPU is to install the Vulkan SDK in your ucrt Rtools MSYS shell which is e.g. ´C:\rtools45\ucrt64.exe´ if you are running R 4.5. Similarly as indicated [here](https://github.com/ggml-org/llama.cpp/blob/master/docs/build.md#vulkan)

```
pacman -S git \
    mingw-w64-ucrt-x86_64-gcc \
    mingw-w64-ucrt-x86_64-cmake \
    mingw-w64-ucrt-x86_64-vulkan-devel \
    mingw-w64-ucrt-x86_64-shaderc
```

- Make sure the compilation can find Vulkan by doing the following steps:
  - Create an environment variable VULKAN_SDK and set it to the path of Rtools ucrt64 'C:\rtools45\ucrt64' 
  - Add 'C:\rtools45\ucrt64\bin' to your PATH and restart R
  - Make sure you use the C and C++ compilers from Rtools ucrt64 by setting the environment variables and install the package as follows by using the `-DGGML_VULKAN=1` flag

```
Sys.setenv(CC = "C:/rtools45/ucrt64/bin/gcc.exe", CXX = "C:/rtools45/ucrt64/bin/g++.exe")
Sys.setenv(WHISPER_CMAKE_FLAGS="-DGGML_VULKAN=1 -DGGML_AVX=0 -DGGML_AVX2=1 -DGGML_SSE42=0 -DGGML_F16C=1 -DGGML_FMA=1 -DGGML_BMI2=0 -DGGML_OPENMP=0")
remotes::install_github("bnosac/audio.whisper", force = TRUE)
Sys.unsetenv("WHISPER_CMAKE_FLAGS")
```

- Next you can use the package. Note that possibly if you have several devices on your Windows machine, you can specify the device order by setting the GGML_VK_VISIBLE_DEVICES environment variable
- Note that using Vulkan on Windows has not been tested thoroughly
    
<details>
  <summary>Uncollapse to show details</summary>

```
## Reorder the devices before loading the package to put Vulkan GPU on first place
Sys.setenv(GGML_VK_VISIBLE_DEVICES = "1,0") 
library(audio.whisper)
## Show the devices 
audio.whisper:::ggml_devices()
model <- whisper("medium", use_gpu = TRUE, gpu_device = 0, flash_attn = TRUE)

> Sys.setenv(GGML_VK_VISIBLE_DEVICES = "1,0")
> library(audio.whisper)
> audio.whisper:::ggml_devices()
ggml_vulkan: Found 2 Vulkan devices:
ggml_vulkan: 0 = NVIDIA GeForce RTX 4090 Laptop GPU (NVIDIA) | uma: 0 | fp16: 1 | bf16: 0 | warp size: 32 | shared memory: 49152 | int dot: 1 | matrix cores: NV_coopmat2
ggml_vulkan: 1 = Intel(R) RaptorLake-S Mobile Graphics Controller (Intel Corporation) | uma: 1 | fp16: 1 | bf16: 0 | warp size: 32 | shared memory: 32768 | int dot: 1 | matrix cores: none
$n
[1] 3

$devices
            id    name                                      description                          type
1 0000:01:00.0 Vulkan0               NVIDIA GeForce RTX 4090 Laptop GPU  GGML_BACKEND_DEVICE_TYPE_GPU
2   unknown id Vulkan1 Intel(R) RaptorLake-S Mobile Graphics Controller GGML_BACKEND_DEVICE_TYPE_IGPU
3   unknown id     CPU            13th Gen Intel(R) Core(TM) i9-13900HX  GGML_BACKEND_DEVICE_TYPE_CPU

$backends_registered
[1] "Vulkan"                                                                                                        
[2] "CPU : SSE3 = 1 | SSSE3 = 1 | AVX = 1 | AVX_VNNI = 1 | AVX2 = 1 | F16C = 1 | FMA = 1 | BMI2 = 1 | REPACK = 1 | "

> model <- whisper("medium", use_gpu = TRUE, flash_attn = TRUE)
system_info: hardware_concurrency = 32 | WHISPER : COREML = 0 | OPENVINO = 0 | CPU : SSE3 = 1 | SSSE3 = 1 | AVX = 1 | AVX_VNNI = 1 | AVX2 = 1 | F16C = 1 | FMA = 1 | BMI2 = 1 | REPACK = 1 | 
whisper_init_from_file_with_params_no_state: loading model from 'C:/Users/jwijf/Desktop/audio.whisper/ggml-medium.bin'
whisper_init_with_params_no_state: use gpu    = 1
whisper_init_with_params_no_state: flash attn = 1
whisper_init_with_params_no_state: gpu_device = 0
whisper_init_with_params_no_state: dtw        = 0
whisper_init_with_params_no_state: devices    = 3
whisper_init_with_params_no_state: backends   = 2
whisper_model_load: loading model
whisper_model_load: n_vocab       = 51865
whisper_model_load: n_audio_ctx   = 1500
whisper_model_load: n_audio_state = 1024
whisper_model_load: n_audio_head  = 16
whisper_model_load: n_audio_layer = 24
whisper_model_load: n_text_ctx    = 448
whisper_model_load: n_text_state  = 1024
whisper_model_load: n_text_head   = 16
whisper_model_load: n_text_layer  = 24
whisper_model_load: n_mels        = 80
whisper_model_load: ftype         = 1
whisper_model_load: qntvr         = 0
whisper_model_load: type          = 4 (medium)
whisper_model_load: adding 1608 extra tokens
whisper_model_load: n_langs       = 99
whisper_model_load:      Vulkan0 total size =  1533.14 MB
whisper_model_load: model size    = 1533.14 MB
whisper_backend_init_gpu: device 0: Vulkan0 (type: 1)
whisper_backend_init_gpu: found GPU device 0: Vulkan0 (type: 1, cnt: 0)
whisper_backend_init_gpu: using Vulkan0 backend
whisper_init_state: kv self size  =   50.33 MB
whisper_init_state: kv cross size =  150.99 MB
whisper_init_state: kv pad  size  =    6.29 MB
whisper_init_state: compute buffer (conv)   =   29.53 MB
whisper_init_state: compute buffer (encode) =   44.60 MB
whisper_init_state: compute buffer (cross)  =    7.73 MB
whisper_init_state: compute buffer (decode) =   99.12 MB
```

</details> 




#### For older versions of audio.whisper (< 0.5.0)

<details>
  <summary>Uncollapse to show details</summary>
 

The tensor operations contained in [ggml.h](src/whisper_cpp/ggml.h) / [ggml.c](src/whisper_cpp/ggml.c) are *highly optimised* depending on the hardware of your CPU

  - It has AVX intrinsics support for x86 architectures, VSX intrinsics support for POWER architectures, Mixed F16 / F32 precision, for Apple silicon allows optimisation via Arm Neon, the Accelerate framework and Metal and provides GPU support for NVIDIA
  - In order to gain from these **massive transcription speedups**, you need to set the correct compilation flags when you install the R package, *otherwise transcription speed will be suboptimal* (a 5-minute audio fragment can either be transcribed in 40 minutes or 10 seconds depending on your hardware). 
  - Normally using the installation as described above, some of these compilation flags are detected and you'll see these printed when doing the installation   
  - It is however advised to set these compilation C flags yourself as follows right before you install the package such that [/src/Makevars](/src/Makevars) knows you want these optimisations for sure. This can be done by defining the environment variables `WHISPER_CFLAGS`, `WHISPER_CPPFLAGS`, `WHISPER_LIBS` as follows.

```
Sys.setenv(WHISPER_CFLAGS = "-mavx -mavx2 -mfma -mf16c")
remotes::install_github("bnosac/audio.whisper", ref = "0.3.3", force = TRUE)
Sys.unsetenv("WHISPER_CFLAGS")
```

To find out which hardware acceleration options your hardware supports, you can go to https://github.com/bnosac/audio.whisper/issues/26 and look for the CFLAGS (and optionally CXXFLAGS and LDFLAGS) settings which make sense on your hardware 

  - Common settings to set for `WHISPER_CFLAGS` are `-mavx -mavx2 -mfma -mf16c` and extra possible flags `-msse3` and `mssse3` 
      - E.g. on my local Windows Intel machine I could set `-mavx -mavx2 -mfma -mf16c`
      - For Mac users you can speed up transcriptions by setting before installation of audio.whisper
          - `Sys.setenv(WHISPER_ACCELERATE = "1")` if your computer has the Accelerate framework
          - `Sys.setenv(WHISPER_METAL = "1")` if your computer has a GPU based on Metal
      - For Linux users which have a NVIDIA GPU, processing can be offloaded to the GPU to a large extent through cuBLAS. For this speedup, install the R package with following settings
          - `Sys.setenv(WHISPER_CUBLAS = "1")`  
          - make sure nvcc is in the PATH (e.g. `export PATH=/usr/local/cuda-12.3/bin${PATH:+:${PATH}}`) and set the path to CUDA if it is not at `/usr/local/cuda` as in `Sys.setenv(CUDA_PATH = "/usr/local/cuda-12.3")`
      - On my older local Ubuntu machine there were no optimisation possibilities. Your mileage may vary.
      - If you have OpenBLAS installed, you can considerably speed up transcription by installing the R package with `Sys.setenv(WHISPER_OPENBLAS = "1")`
  - If you need extra settings in `PKG_CPPFLAGS` (`CXXFLAGS`), you can e.g. use `Sys.setenv(WHISPER_CPPFLAGS = "-mcpu=native")` before installing the package
  - If you need extra settings in `PKG_LIBS`, you can e.g. use `Sys.setenv(WHISPER_LIBS = "-framework Accelerate")` before installing the package
  - If you need custom settings, you can update `PKG_CFLAGS` / `PKG_CPPFLAGS` / `PKG_LIBS` in [/src/Makevars](/src/Makevars) directly.

Note that *if your hardware does not support these compilation flags, you'll get a crash* when transcribing audio.

</details>

-----

## Support in text mining

Need support in text mining?
Contact BNOSAC: http://www.bnosac.be

