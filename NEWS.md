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