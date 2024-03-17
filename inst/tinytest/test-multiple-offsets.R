library(audio.whisper)

if(Sys.getenv("TINYTEST_CI", unset = "yes") == "yes"){
  ## JFK example full fragment using tiny model
  model <- whisper("tiny")
  trans <- predict(model, newdata = system.file(package = "audio.whisper", "samples", "jfk.wav"), language = "en", 
                   offset = c(0, 4000), duration = c(1*1500, 1*5000))
  expect_equal(trans$n_segments, 2)
  expect_equal(nrow(trans$data), 2)
  if(file.exists(model$file)) file.remove(model$file)
  
  ## Longer file
  download.file("https://github.com/jwijffels/example/raw/main/example.wav", "example.wav")
  model <- whisper("tiny")
  trans <- predict(model, newdata = "example.wav", language = "en", 
                   offset = c(7*1000, 60*1000), duration = c(4*1500, 2*1000))
  expect_equal(trans$n_segments, 2)
  expect_equal(nrow(trans$data), 2)
  if(file.exists(model$file)) file.remove(model$file)
  if(file.exists(trans$params$audio)) file.remove(trans$params$audio)
  
  if(FALSE){
    library(audio.whisper)
    library(audio.vadwebrtc)
    library(av)
    audio      <- system.file(package = "audio.whisper", "samples", "stereo.wav")
    audio_mono <- audio
    audio_mono <- tempfile(fileext = ".wav")
    av_audio_convert(audio, channels = 1, output = audio_mono, format = "wav")
    ## Voice activity detection
    vad    <- VAD(audio_mono)
    voiced <- is.voiced(vad, units = "milliseconds", silence_min = 250)
    voiced <- subset(voiced, has_voice == TRUE)
    ## Transcription of voiced segments
    model <- whisper("tiny")
    trans <- predict(model, newdata = audio, language = "es", sections = voiced)
    trans <- predict(model, newdata = audio, language = "es", offset = voiced$start, duration = voiced$duration)
  }
}