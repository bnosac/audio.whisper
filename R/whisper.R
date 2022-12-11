

#' @title Transcribe audio files using a Whisper model
#' @description Automatic Speech Recognition using Whisper on 16-bit WAV files
#' @param object a whisper object
#' @param newdata the path to a 16-bit .wav file
#' @param language the language of the audio. Defaults to 'en'
#' @param ... further arguments, for expert usage only
#' @return a list with the following elements:
#' \itemize{
#' \item{n_segments: the number of audio segments}
#' \item{data: a data.frame with the transcription with columns segment, text, from and to}
#' \item{tokens: a data.frame with the transcription tokens with columns segment, token, token_prob indicating the token probability given the context}
#' \item{params: a list with parameters used for inference}
#' }
#' @export
#' @seealso \code{\link{whisper}}
#' @examples
#' \dontrun{ 
#' model <- whisper("tiny")
#' audio <- system.file(package = "audio.whisper", "samples", "jfk.wav")
#' trans <- predict(model, newdata = audio)
#' trans <- predict(model, newdata = audio, token_timestamps = TRUE)
#' }
predict.whisper <- function(object, newdata, language = "en", ...){
  stopifnot(length(newdata) == 1)
  stopifnot(file.exists(newdata))
  whisper_encode(model = object$file, path = newdata, language = language, ...)
}


#' @title Automatic Speech Recognition using Whisper
#' @description Automatic Speech Recognition using Whisper on 16-bit WAV files
#' @param x the path to a model, an object returned by \code{\link{whisper_download_model}} or a character string with 
#' the name of the model which can be passed on to \code{\link{whisper_download_model}}
#' @param ... further arguments, not used currently
#' @return a list with the following elements: TODO
#' @export
#' @examples
#' \dontrun{ 
#' model <- whisper("tiny")
#' trans <- predict(model, newdata = system.file(package = "audio.whisper", "samples", "jfk.wav"))
#' trans
#' model <- whisper("medium")
#' trans <- predict(model, newdata = system.file(package = "audio.whisper", "samples", "jfk.wav"))
#' 
#' ## Or download the model explicitely
#' path  <- whisper_download_model("tiny")
#' model <- whisper(path)
#' trans <- predict(model, newdata = system.file(package = "audio.whisper", "samples", "jfk.wav"))
#' }
#' 
#' \dontshow{
#' ## Or provide the path to the model
#' path  <- system.file(package = "audio.whisper", "models", "for-tests-ggml-tiny.bin")
#' model <- whisper(path)
#' trans <- predict(model, newdata = system.file(package = "audio.whisper", "samples", "jfk.wav"))
#' }
whisper <- function(x, ...){
  if(x %in% c("tiny", "tiny.en", "base", "base.en", "small", "small.en", "medium", "medium.en", "large-v1", "large")){
    x <- whisper_download_model(x, overwrite = FALSE, ...)
  }
  if(inherits(x, "whisper_download")){
    out        <- list(file = x$file_model)
  }else{
    out        <- list(file = x)  
  }
  class(out) <- "whisper"
  out
}

#' @title Download a pretrained Whisper model
#' @description Download a pretrained Whisper model. The list of available models are
#' \itemize{
#' \item{tiny & tiny.en: 75 MB, RAM required: ~390 MB. Multilingual and English only version.}
#' \item{base & base.en: 142 MB, RAM required: ~500 MB. Multilingual and English only version.}
#' \item{small & small.en: 466 MB, RAM required: ~1.0 GB. Multilingual and English only version.}
#' \item{medium & medium.en: 1.5 GB, RAM required: ~2.6 GB. Multilingual and English only version.}
#' \item{large-v1 & large: 2.9 GB, RAM required: ~4.7 GB. Multilingual version 1 and version 2}
#' }
#' @param x the name of the model
#' @param model_dir a path where the model will be downloaded to. Defaults to the current working directory
#' @param repos character string with the repository to download the model from. Either
#' \itemize{
#' \item{'ggerganov': https://ggml.ggerganov.com/}
#' \item{'huggingface': https://huggingface.co/datasets/ggerganov/whisper.cpp}
#' }
#' @param overwrite logical indicating to overwrite the file if the file was already downloaded. Defaults to \code{TRUE} indicating 
#' it will download the model and overwrite the file if the file already existed. If set to \code{FALSE},
#' the model will only be downloaded if it does not exist on disk yet in the \code{model_dir} folder.
#' @param ... currently not used
#' @return A data.frame with 1 row and the following columns: 
#' \itemize{
#'  \item{model: }{The model as provided by the input parameter \code{x}}
#'  \item{file_model: }{The path to the file on disk where the model was downloaded to}
#'  \item{url: }{The URL where the model was downloaded from}
#'  \item{download_failed: }{A logical indicating if the download has failed or not due to internet connectivity issues}
#'  \item{download_message: }{A character string with the error message in case the downloading of the model failed}
#' }
#' @export
#' @examples
#' path <- whisper_download_model("tiny")
#' path <- whisper_download_model("tiny", overwrite = FALSE)
#' \dontrun{
#' whisper_download_model("tiny.en")
#' whisper_download_model("base")
#' whisper_download_model("base.en")
#' whisper_download_model("small")
#' whisper_download_model("small.en")
#' whisper_download_model("medium")
#' whisper_download_model("medium.en")
#' whisper_download_model("large-v1")
#' whisper_download_model("large")
#' 
#' whisper_download_model("tiny", repos = "ggerganov")
#' whisper_download_model("tiny.en", repos = "ggerganov")
#' }
#' \dontshow{
#' if(file.exists(path$file_model)) file.remove(path$file_model)
#' }
whisper_download_model <- function(x = c("tiny", "tiny.en", "base", "base.en", "small", "small.en", "medium", "medium.en", "large-v1", "large"),
                                   model_dir = getwd(),
                                   repos = c("huggingface", "ggerganov"),
                                   overwrite = TRUE, 
                                   ...){
  x     <- match.arg(x)
  repos <- match.arg(repos)
  if(repos == "huggingface"){
    f   <- sprintf("ggml-%s.bin", x)
    url <- sprintf("https://huggingface.co/datasets/ggerganov/whisper.cpp/resolve/main/%s", f)
  }else if(repos == "ggerganov"){
    f   <- sprintf("ggml-model-whisper-%s.bin", x)
    url <- sprintf("https://ggml.ggerganov.com/%s", f)
  }
  if(!dir.exists(model_dir)){
    dir.create(model_dir, recursive = TRUE)  
  }
  to <- file.path(model_dir, basename(url))
  download_failed  <- FALSE
  download_message <- "OK"
  if(overwrite || !file.exists(to)){
    dl <- suppressWarnings(try(
      utils::download.file(url = url, destfile = to, mode = "wb"),  
      silent = TRUE))
    if(inherits(dl, "try-error")){
      download_failed  <- TRUE
      download_message <- as.character(dl)
    }else if(inherits(dl, "integer") && dl != 0){
      download_failed  <- TRUE
      download_message <- "Download failed. Please check internet connectivity"
    }
    if(download_failed){
      message("Something went wrong")
      message(download_message)
    }else{
      message(sprintf("Downloading finished, model stored at '%s'", to))
    }
  }
  out <- data.frame(model = x,
                    file_model = to,
                    url = url,
                    download_failed = download_failed,
                    download_message = download_message,
                    stringsAsFactors = FALSE)
  class(out) <- c("data.frame", "whisper_download")
  out
}