## CHANGES IN audio.whisper VERSION 0.3.3

- Add option to download quantised models
  - medium-q5_0, medium.en-q5_0 and remove medium-q5_1, medium.en-q5_1

## CHANGES IN audio.whisper VERSION 0.3.2

- Documentation of arguments in predict.whisper
- Add option to download quantised models
  - tiny-q5_1, tiny.en-q5_1
  - base-q5_1, base.en-q5_1
  - small-q5_1, small.en-q5_1
  - medium-q5_1, medium.en-q5_1
  - large-v2-q5_0 and large-v3-q5_0
- Allow to disable printing the transcription evolution during the prediction with the trace argument
- Enable O3 optimisations by default

## CHANGES IN audio.whisper VERSION 0.3.1

- Makevars
  - Added detection of AVX512F for adding compilation flags to PKG_CFLAGS/PKG_CPPFLAGS
  - Enable Metal for speeding up transcriptions on the GPU on Mac
  - Enable compiling with OpenBLAS to speed up the transcriptions
- Add whisper_languages to get a data.frame of all languages the Whisper model can handle
- whisper_download_model 
  - change default timeout to 10 minutes if no timeout is set by the user + change output element in the list to 'download_success' instead of 'download_failed'
  - model_dir now defaults to the directory set in the environment variable WHISPER_MODEL_DIR and if this is not set, the current working directory
- whisper
  - Add option use_gpu to be able to run the prediction on a GPU (e.g. Metal)
- predict.whisper
  - Add option to pass on initial prompt
  - Output of predict.whisper adds the audio duration of the wav file in seconds in the params list element
  - Gains an extra argument indicating to transcribe or translate

## CHANGES IN audio.whisper VERSION 0.3

- Upgrade to whisper.cpp version v1.5.4
- whisper_download_model allows to download 'large-v1', 'large-v2', 'large-v3' while model 'large' should no longer be used

## CHANGES IN audio.whisper VERSION 0.2.2

- Add option to pass on float entropy_thold (similar to compression_ratio_threshold), logprob_thold, beam_size, best_of, split_on_word, max_context when doing the prediction
- Output of the predict.whisper function now includes an element called timing indicating how long it took to do the transcription
- whisper gains 2 arguments: the model_dir/overwrite which is passed directly to whisper_download_model
- whisper_download_model 
  - gains an argument version which defaults to models for whisper.cpp version 1.2.1
  - gets the models now from https://huggingface.co/ggerganov/whisper.cpp/resolve/80da2d8bfee42b0e836fc3a9890373e5defc00a6 instead of https://huggingface.co/ggerganov/whisper.cpp/resolve/main

## CHANGES IN audio.whisper VERSION 0.2.1-1

- whisper_download_model now Deprecates downloading from https://ggml.ggerganov.com and changed the URL's to download models from huggingface (Issue #18)

## CHANGES IN audio.whisper VERSION 0.2.1

- Add option to compile with own PKG_CFLAGS by setting environment variable WHISPER_CFLAGS
- Add option to compile with extra PKG_CPPFLAGS by setting environment variable WHISPER_CPPFLAGS

## CHANGES IN audio.whisper VERSION 0.2.0

- Incorporate whisper.cpp version v1.2.1

## CHANGES IN audio.whisper VERSION 0.1.3

- Ongoing work on improving compilation instructions to speed up transcribing while still being CRAN compliant
- Add whisper_benchmark

## CHANGES IN audio.whisper VERSION 0.1.2

- Incorporate whisper.cpp release 1.0.4: https://github.com/ggerganov/whisper.cpp/releases/tag/1.0.4 and up to commit 99da1e5cc853f7cdd61d2f259c8d770ea9279d29
- predict.whisper now uses 'auto' as default language
- predict.whisper now sets resulting text with UTF-8 encoding

## CHANGES IN audio.whisper VERSION 0.1.1

- Incorporate https://github.com/ggerganov/whisper.cpp/pull/257 (Remove C++20 requirement)

## CHANGES IN audio.whisper VERSION 0.1.0

- Initial version based on 
  - https://github.com/ggerganov/whisper.cpp commit 85c9ac18b59125b988cda40f40d8687e1ba88a7a
  - https://github.com/mackron/dr_libs commit dd762b861ecadf5ddd5fb03e9ca1db6707b54fbb
- Added whisper
  - whisper_download_model, whisper and predict.whisper