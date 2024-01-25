library(audio.whisper)

## Load the model, predict a small fragment which does not detect anything
model <- whisper(system.file(package = "audio.whisper", "models", "for-tests-ggml-tiny.bin"))
trans <- predict(model, newdata = system.file(package = "audio.whisper", "samples", "jfk.wav"), language = "en", duration = 1000 / 2)
expect_inherits(trans, "whisper_transcription")
expect_equal(trans$n_segments, 0)
expect_true(is.data.frame(trans$data))
expect_equal(nrow(trans$data), 0)
expect_true(is.data.frame(trans$tokens))
expect_equal(nrow(trans$tokens), 0)

if(Sys.getenv("TINYTEST_CI", unset = "yes") == "yes"){
  ## JFK example full fragment using tiny model
  model <- whisper("tiny")
  trans <- predict(model, newdata = system.file(package = "audio.whisper", "samples", "jfk.wav"), language = "en")
  expect_inherits(trans, "whisper_transcription")
  expect_equal(trans$n_segments, 1)
  expect_true(is.data.frame(trans$data))
  expect_equal(nrow(trans$data), 1)
  expect_true(is.data.frame(trans$tokens))
  expect_equal(nrow(trans$tokens), 23)
  onlyalpha <- function(x){
    x <- gsub("[^[:alnum:] ]", "", x)
    x <- x[nchar(x) > 0]
    x <- tolower(x)
    x
  }
  expect_equal(onlyalpha(trimws(trans$data$text)), onlyalpha("And so my fellow Americans ask not what your country can do for you ask what you can do for your country."))
  expect_equal(onlyalpha(trimws(trans$tokens$token)), onlyalpha(c("And", "so", "my", "fellow", "Americans", "ask", "not", "what", 
                                             "your", "country", "can", "do", "for", "you", "ask", "what", 
                                             "you", "can", "do", "for", "your", "country", ".")))
  
  ## Dutch example with base model
  model <- whisper("base")
  trans <- predict(model, newdata = system.file(package = "audio.whisper", "samples", "proficiat.wav"), language = "nl", trim = FALSE)
  expect_inherits(trans, "whisper_transcription")
  expect_equal(trans$n_segments, 1)
  expect_true(is.data.frame(trans$data))
  expect_equal(nrow(trans$data), 1)
  expect_true(is.data.frame(trans$tokens))
  expect_equal(trimws(trans$data$text), "Proficiat goed gedaan.")
}
