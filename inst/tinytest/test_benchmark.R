library(audio.whisper)
path  <- system.file(package = "audio.whisper", "models", "for-tests-ggml-tiny.bin")
model <- whisper(path)
whisper_benchmark(model)
