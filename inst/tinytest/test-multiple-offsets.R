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
}