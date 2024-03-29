library(audio.whisper)

if(Sys.getenv("TINYTEST_CI", unset = "yes") == "yes"){
  ## Download a model
  path  <- whisper_download_model("tiny", overwrite = FALSE)
  expect_inherits(path, "data.frame")
  expect_true(path$download_success)
  
  ## Load the model
  model <- whisper("tiny")
  expect_inherits(model, class = "whisper")
  expect_inherits(model$model, class = "externalptr")
  expect_false(identical(model$model, new("externalptr")))
  
  if(file.exists(path$file_model)) file.remove(path$file_model)
  
  ## Download a quantised model + load it
  path  <- whisper_download_model("tiny-q5_1", overwrite = FALSE)
  expect_inherits(path, "data.frame")
  expect_true(path$download_success)
  
  model <- whisper("tiny")
  expect_inherits(model, class = "whisper")
  expect_inherits(model$model, class = "externalptr")
  expect_false(identical(model$model, new("externalptr")))
  
  if(file.exists(path$file_model)) file.remove(path$file_model)
}
