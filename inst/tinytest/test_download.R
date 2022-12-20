library(audio.whisper)

if(Sys.getenv("TINYTEST_CI", unset = "yes") == "yes"){
  ## Download a model
  path  <- whisper_download_model("tiny", overwrite = FALSE)
  expect_inherits(path, "data.frame")
  expect_false(path$download_failed)
  
  ## Load the model
  model <- whisper("tiny")
  expect_inherits(model, class = "whisper")
  expect_inherits(model$model, class = "externalptr")
  expect_false(identical(model$model, new("externalptr")))
}
