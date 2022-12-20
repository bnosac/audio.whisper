library(audio.whisper)
audio <- system.file(package = "audio.whisper", "samples", "jfk.wav")

## Load the model, predict a small fragment which does not detect anything
model <- whisper(system.file(package = "audio.whisper", "models", "for-tests-ggml-tiny.bin"))
trans <- predict(model, newdata = audio, language = "en", duration = 1000 / 2)
expect_inherits(trans, "whisper_transcription")
expect_true(trans$n_segments == 0)
expect_true(is.data.frame(trans$data))
expect_true(nrow(trans$data) == 0)
expect_true(is.data.frame(trans$tokens))
expect_true(nrow(trans$tokens) == 0)

if(Sys.getenv("TINYTEST_CI", unset = "yes") == "yes"){
  ## JFK example full fragment using tiny model
  model <- whisper("tiny")
  trans <- predict(model, newdata = audio, language = "en")
  expect_inherits(trans, "whisper_transcription")
  expect_true(trans$n_segments == 1)
  expect_true(is.data.frame(trans$data))
  expect_true(nrow(trans$data) == 1)
  expect_true(is.data.frame(trans$tokens))
  expect_true(nrow(trans$tokens) == 13)
  expect_equal(trimws(trans$data$text), "And so my fellow Americans ask not what your country can do for you ask what you can do for your country.")
  expect_equal(trimws(trans$tokens$token), c("And", "so", "my", "fellow", "Americans", "ask", "not", "what", 
                                             "your", "country", "can", "do", "for", "you", "ask", "what", 
                                             "you", "can", "do", "for", "your", "country", "."))
}
