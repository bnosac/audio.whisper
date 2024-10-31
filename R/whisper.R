

#' @title Transcribe audio files using a Whisper model
#' @description Automatic Speech Recognition using Whisper on 16-bit WAV files
#' @param object a whisper object
#' @param newdata the path to a 16-bit .wav file
#' @param type character string with the type of prediction, can either be 'transcribe' or 'translate', where 'translate' will put the spoken text in English.
#' @param language the language of the audio. Defaults to 'auto'. For a list of all languages the model can handle: see \code{\link{whisper_languages}}.
#' @param sections a data.frame with columns start and duration (measured in milliseconds) indicating voice segments to transcribe. This will make a new audio file with 
#' these sections, do the transcription and make sure the from/to timestamps are aligned to the original audio file. Defaults to transcribing the full audio file. 
#' @param offset an integer vector of offsets in milliseconds to start the transcription. Defaults to 0 - indicating to transcribe the full audio file.
#' @param duration an integer vector of durations in milliseconds indicating how many milliseconds need to be transcribed from the corresponding \code{offset} onwards. Defaults to 0 - indicating to transcribe the full audio file.
#' @param trim logical indicating to trim leading/trailing white space from the transcription using \code{\link{trimws}}. Defaults to \code{FALSE}.
#' @param trace logical indicating to print the trace of the evolution of the transcription. Defaults to \code{TRUE}
#' @param ... further arguments, directly passed on to the C++ function, for expert usage only and subject to naming changes. See the details.
#' @details 
#' \itemize{
#' \item{token_timestamps: logical indicating to get the timepoints of each token}
#' \item{n_threads: how many threads to use to make the prediction. Defaults to 1}
#' \item{prompt: the initial prompt to pass on the model. Defaults to ''}
#' \item{entropy_thold: entropy threshold for decoder fail. Defaults to 2.4}
#' \item{logprob_thold: log probability threshold for decoder fail. Defaults to -1}
#' \item{beam_size: beam size for beam search. Defaults to -1}
#' \item{best_of: number of best candidates to keep. Defaults to 5}
#' \item{max_context: maximum number of text context tokens to store. Defaults to -1}
#' \item{diarize: logical indicating to perform speaker diarization for audio with more than 1 channel}
#' }
#' If sections are provided
#' If multiple offsets/durations are provided 
#' @return an object of class \code{whisper_transcription} which is a list with the following elements:
#' \itemize{
#' \item{n_segments: the number of audio segments}
#' \item{data: a data.frame with the transcription with columns segment, segment_offset, text, from, to and optionally speaker if diarize=TRUE}
#' \item{tokens: a data.frame with the transcription tokens with columns segment, token_id, token, token_prob indicating the token probability given the context}
#' \item{params: a list with parameters used for inference}
#' \item{timing: a list with elements start, end and duration indicating how long it took to do the transcription}
#' }
#' @export
#' @seealso \code{\link{whisper}}, \code{\link{whisper_languages}}
#' @examples
#' \donttest{ 
#' model <- whisper("tiny")
#' audio <- system.file(package = "audio.whisper", "samples", "jfk.wav")
#' trans <- predict(model, newdata = audio)
#' trans <- predict(model, newdata = audio, language = "en")
#' trans <- predict(model, newdata = audio, language = "en", token_timestamps = TRUE)
#' 
#' audio <- system.file(package = "audio.whisper", "samples", "proficiat.wav")
#' model <- whisper("tiny")
#' trans <- predict(model, newdata = audio, language = "nl", type = "transcribe")
#' model <- whisper("tiny")
#' trans <- predict(model, newdata = audio, language = "nl", type = "translate")
#' 
#' \dontshow{
#' if(file.exists(model$file)) file.remove(model$file)
#' }
#' }
#' 
#' ## Predict using a quantised model
#' audio <- system.file(package = "audio.whisper", "samples", "jfk.wav")
#' path  <- system.file(package = "audio.whisper", "repo", "ggml-tiny-q5_1.bin")
#' model <- whisper(path)
#' trans <- predict(model, newdata = audio, language = "en", trace = FALSE)
#' trans <- predict(model, newdata = audio, language = "en", token_timestamps = TRUE)
#' ## Predict using a quantised model with the GPU
#' model <- whisper(path, use_gpu = TRUE)
#' trans <- predict(model, newdata = audio, language = "en")
#' trans <- predict(model, newdata = audio, language = "en", token_timestamps = TRUE)
#' ## Example of providing further arguments to predict.whisper
#' audio <- system.file(package = "audio.whisper", "samples", "stereo.wav")
#' trans <- predict(model, newdata = audio, language = "auto", diarize = TRUE)
predict.whisper <- function(object, newdata, type = c("transcribe", "translate"), language = "auto", 
                            sections = data.frame(start = integer(), duration = integer()), 
                            offset = 0L, duration = 0L,
                            trim = FALSE, trace = TRUE, ...){
  type <- match.arg(type)
  stopifnot(length(newdata) == 1)
  stopifnot(file.exists(newdata))
  stopifnot(is.data.frame(sections) && all(c("start", "duration") %in% colnames(sections)))
  path <- newdata
  ##
  ## If specific audio sections are requested
  ##
  if(nrow(sections) > 0){
    if(length(offset) > 1 || length(duration) > 1 || any(offset != 0) || any(duration != 0)){
      stop("sections can not be combined with offset/duration")
    }
    voiced  <- subset.wav(newdata, offset = sections$start, duration = sections$duration)
    path    <- voiced$file
    on.exit({
      if(file.exists(voiced$file)) file.remove(voiced$file)
    })
    skipped <- voiced$skipped
  }else{
    skipped <- data.frame(start = integer(), removed = integer())
  }
  start <- Sys.time()
  if(type == "transcribe"){
    out <- whisper_encode(model = object$model, path = path, language = language, translate = FALSE, trace = as.integer(trace), offset = offset, duration = duration, ...)
  }else if(type == "translate"){
    out <- whisper_encode(model = object$model, path = path, language = language, translate = TRUE, trace = as.integer(trace), offset = offset, duration = duration, ...)
  }
  Encoding(out$data$text)    <- "UTF-8"
  Encoding(out$tokens$token) <- "UTF-8"
  if(trim){
    out$data$text              <- trimws(out$data$text)
    out$tokens$token           <- trimws(out$tokens$token)  
  }
  end <- Sys.time()
  ##
  ## If specific audio sections are requested - make sure timestamps are correct 
  ##
  if(nrow(sections) > 0){
    out$params$audio <- newdata
    ## Align timestamps for out$data
    sentences <- align_skipped(sentences = out$data, skipped = skipped, from = "from", to = "to")
    sentences <- subset(sentences, sentences$grp == "voiced", select = intersect(c("segment", "segment_offset", "from", "to", "text", "speaker"), colnames(sentences)))
    out$data  <- sentences
    ## Align timestamps for out$tokens if they are requested
    if("token_from" %in% colnames(out$tokens)){
      tokens     <- align_skipped(sentences = out$tokens, skipped = skipped, from = "token_from", to = "token_to")
      tokens     <- subset(tokens, tokens$grp == "voiced", select = intersect(c("segment", "token_id", "token", "token_prob", "token_from", "token_to", "speaker"), colnames(tokens)))
      out$tokens <- tokens
    }
  }
  if(!out$params$diarize){
    out$data$speaker <- NULL
  }
  out$timing <- list(transcription_start = start, 
                     transcription_end = end, 
                     transcription_duration = difftime(end, start, units = "mins"))
  class(out) <- "whisper_transcription"
  out
}

align_skipped <- function(sentences, skipped, from = "from", to = "to"){
  requireNamespace("data.table")
  #sentences       <- out$data
  
  olddigits <- getOption("digits.secs")
  options(digits.secs=3)
  on.exit({
    options(digits.secs = olddigits)
  })
  today <- Sys.Date()
  sentences$start <- as.numeric(difftime(as.POSIXct(paste(today, sentences[[from]], sep = " "), format = "%Y-%m-%d %H:%M:%OS"), as.POSIXct(paste(today, "00:00:00.000", sep = " "), format = "%Y-%m-%d %H:%M:%OS"), units = "secs")) * 1000
  sentences$end   <- as.numeric(difftime(as.POSIXct(paste(today, sentences[[to]],   sep = " "), format = "%Y-%m-%d %H:%M:%OS"), as.POSIXct(paste(today, "00:00:00.000", sep = " "), format = "%Y-%m-%d %H:%M:%OS"), units = "secs")) * 1000
  sentences       <- data.table::rbindlist(list(skipped = skipped, 
                                                voiced  = sentences), 
                                           idcol = "grp", fill = TRUE)
  sentences       <- sentences[order(sentences$start, decreasing = FALSE), ]
  sentences$add   <- data.table::nafill(sentences$removed, type = "locf")
  sentences$add   <- ifelse(is.na(sentences$add), 0, sentences$add)
  sentences$start <- sentences$start + sentences$add
  sentences$end   <- sentences$end   + sentences$add
  sentences[[from]]  <- format(as.POSIXct("1970-01-01 00:00:00", tz = "UTC") + sentences$start / 1000, "%H:%M:%OS")
  sentences[[to]]    <- format(as.POSIXct("1970-01-01 00:00:00", tz = "UTC") + sentences$end   / 1000, "%H:%M:%OS")
  sentences$segment_offset <- data.table::nafill(ifelse(sentences$grp == "skipped", sentences$start, NA_integer_), type = "locf")
  sentences$segment_offset <- ifelse(is.na(sentences$segment_offset), 0L, sentences$segment_offset)
  sentences       <- data.table::setDF(sentences)
  sentences
}


#' @title Automatic Speech Recognition using Whisper
#' @description Automatic Speech Recognition using Whisper on 16-bit WAV files. Load the speech recognition model.
#' @param x the path to a model, an object returned by \code{\link{whisper_download_model}} or a character string with 
#' the name of the model which can be passed on to \code{\link{whisper_download_model}}
#' @param use_gpu logical indicating to use the GPU in case you have Metal or an NVIDIA GPU. Defaults to \code{FALSE}.
#' @param overwrite logical indicating to overwrite the model file if the model file was already downloaded, passed on to \code{\link{whisper_download_model}}. Defaults to \code{FALSE}.
#' @param model_dir a path where the model will be downloaded to, passed on to \code{\link{whisper_download_model}}. 
#' Defaults to the environment variable \code{WHISPER_MODEL_DIR} and if this is not set, the current working directory
#' @param ... further arguments, passed on to the internal C++ function \code{whisper_load_model}
#' @return an object of class \code{whisper} which is list with the following elements: 
#' \itemize{
#' \item{file: path to the model}
#' \item{model: an Rcpp pointer to the loaded Whisper model}
#' }
#' @export
#' @seealso \code{\link{predict.whisper}}
#' @examples
#' \dontrun{ 
#' ## Provide shorthands 'tiny', 'base', 'small', 'medium', ...
#' model <- whisper("tiny")
#' trans <- predict(model, newdata = system.file(package = "audio.whisper", "samples", "jfk.wav"))
#' trans
#' model <- whisper("base")
#' trans <- predict(model, newdata = system.file(package = "audio.whisper", "samples", "jfk.wav"))
#' trans
#' model <- whisper("small")
#' trans <- predict(model, newdata = system.file(package = "audio.whisper", "samples", "jfk.wav"))
#' trans
#' model <- whisper("medium")
#' trans <- predict(model, newdata = system.file(package = "audio.whisper", "samples", "jfk.wav"))
#' trans
#' model <- whisper("large-v1")
#' trans <- predict(model, newdata = system.file(package = "audio.whisper", "samples", "jfk.wav"))
#' trans
#' 
#' ## Or download the model explicitely
#' path  <- whisper_download_model("tiny")
#' model <- whisper(path)
#' trans <- predict(model, newdata = system.file(package = "audio.whisper", "samples", "jfk.wav"))
#' }
#' 
#' ## Or provide the path to the model you have downloaded previously
#' path  <- system.file(package = "audio.whisper", "repo", "ggml-tiny-q5_1.bin")
#' path
#' model <- whisper(path)
#' trans <- predict(model, newdata = system.file(package = "audio.whisper", "samples", "jfk.wav"), 
#'                  language = "en")
#'                  
#' ## Add diarization
#' trans <- predict(model, newdata = system.file(package = "audio.whisper", "samples", "stereo.wav"), 
#'                  language = "es", diarize = TRUE)
#' ## Provide multiple offsets and durations to get the segments in there
#' trans <- predict(model, newdata = system.file(package = "audio.whisper", "samples", "stereo.wav"), 
#'                  language = "es", diarize = TRUE, 
#'                  offset = c( 650, 6060, 10230), duration = c(4990, 3830, 11650))
#' ## Provide sections - this will make a new audio file and next do the transcription
#' if(require(data.table) && require(audio)){
#' trans <- predict(model, newdata = system.file(package = "audio.whisper", "samples", "stereo.wav"), 
#'                  language = "es", diarize = TRUE, 
#'                  sections = data.frame(start    = c( 650, 6060, 10230), 
#'                                        duration = c(4990, 3830, 11650)))
#' }
#' 
#' \dontshow{
#' ## Or provide the path to the model
#' path  <- system.file(package = "audio.whisper", "models", "for-tests-ggml-tiny.bin")
#' model <- whisper(path)
#' trans <- predict(model, newdata = system.file(package = "audio.whisper", "samples", "jfk.wav"), 
#'                  language = "en", duration = 1000)
#' path  <- system.file(package = "audio.whisper", "models", "for-tests-ggml-tiny.en.bin")
#' model <- whisper(path)
#' trans <- predict(model, newdata = system.file(package = "audio.whisper", "samples", "jfk.wav"), 
#'                  language = "en", duration = 1000)
#' }
whisper <- function(x, use_gpu = FALSE, overwrite = FALSE, model_dir = Sys.getenv("WHISPER_MODEL_DIR", unset = getwd()), ...){
  if(x %in% c("tiny", "tiny-q5_1", "tiny-q8_0",
              "tiny.en", "tiny.en-q5_1", "tiny.en-q8_0",
              "base", "base-q5_1", "base-q8_0", 
              "base.en", "base.en-q5_1", "base.en-q8_0",
              "small", "small-q5_1", "small-q8_0",
              "small.en", "small.en-q5_1", "small.en-q8_0",
              "medium", "medium-q5_0", "medium-q8_0",
              "medium.en", "medium.en-q5_0", "medium.en-q8_0", 
              "large-v1", 
              "large-v2", "large-v2-q5_0", "large-v2-q8_0", 
              "large-v3", "large-v3-q5_0",
              "large-v3-turbo", "large-v3-turbo-q5_0", "large-v3-turbo-q8_0")){
    x <- whisper_download_model(x, overwrite = overwrite, model_dir = model_dir)
  }
  if(inherits(x, "whisper_download")){
    out        <- list(file = x$file_model)
  }else{
    out        <- list(file = x)  
  }
  Sys.setenv("GGML_METAL_PATH_RESOURCES" = Sys.getenv("GGML_METAL_PATH_RESOURCES", unset = system.file(package = "audio.whisper", "metal")))
  out$model <- whisper_load_model(out$file, use_gpu = use_gpu, ...)
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
#' \item{large-v1, large-v2, large-v3, large-v3-turbo: 2.9 GB, RAM required: ~4.7 GB. Multilingual}
#' \item{quantised models: tiny-q5_1, tiny-q8_0, tiny.en-q5_1, tiny.en-q8_0, base-q5_1, base-q8_0, base.en-q5_1, base_q8_0, small-q5_1, small-q8_0, small.en-q5_1, small.en-q8_0, medium-q5_0, medium-q8_0, medium.en-q5_0, medium.en-q8_0, large-v2-q5_0, large-v2-q8_0, large-v3-q5_0, large-v3-turbo-q5_0, and large-v3-turbo-q8_0 (only - from version 1.5.4 onwards)}
#' }
#' Note that the larger models may take longer than 60 seconds to download, so consider 
#' increasing the timeout option in R via \code{options(timeout = 120)}
#' @param x the name of the model
#' @param model_dir a path where the model will be downloaded to. Defaults to the environment variable \code{WHISPER_MODEL_DIR} and if this is not set, the current working directory
#' @param repos character string with the repository to download the model from. Either
#' \itemize{
#' \item{'huggingface': https://huggingface.co/ggerganov/whisper.cpp - the default}
#' \item{'ggerganov': https://ggml.ggerganov.com/ - no longer supported as the resource by ggerganov can become unavailable}
#' }
#' @param version character string with the version of the model. Defaults to "1.5.4".
#' @param overwrite logical indicating to overwrite the file if the file was already downloaded. Defaults to \code{TRUE} indicating 
#' it will download the model and overwrite the file if the file already existed. If set to \code{FALSE},
#' the model will only be downloaded if it does not exist on disk yet in the \code{model_dir} folder.
#' @param ... currently not used
#' @return A data.frame with 1 row and the following columns: 
#' \itemize{
#'  \item{model: The model as provided by the input parameter \code{x}}
#'  \item{file_model: The path to the file on disk where the model was downloaded to}
#'  \item{url: The URL where the model was downloaded from}
#'  \item{download_success: A logical indicating if the download has succeeded or not due to internet connectivity issues}
#'  \item{download_message: A character string with the error message in case the downloading of the model failed}
#' }
#' @export
#' @seealso \code{\link{whisper}}, \code{\link{predict.whisper}}, \code{\link{whisper_languages}}
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
#' whisper_download_model("large-v2")
#' whisper_download_model("large-v3")
#' whisper_download_model("tiny-q5_1")
#' whisper_download_model("base-q5_1")
#' whisper_download_model("small-q5_1")
#' whisper_download_model("medium-q5_0")
#' whisper_download_model("large-v2-q5_0")
#' whisper_download_model("large-v3-q5_0")
#' }
#' \dontshow{
#' if(file.exists(path$file_model)) file.remove(path$file_model)
#' }
whisper_download_model <- function(x = c("tiny", "tiny-q5_1", "tiny-q8_0",
                                         "tiny.en", "tiny.en-q5_1", "tiny.en-q8_0",
                                         "base", "base-q5_1", "base-q8_0", 
                                         "base.en", "base.en-q5_1", "base.en-q8_0",
                                         "small", "small-q5_1", "small-q8_0",
                                         "small.en", "small.en-q5_1", "small.en-q8_0",
                                         "medium", "medium-q5_0", "medium-q8_0",
                                         "medium.en", "medium.en-q5_0", "medium.en-q8_0", 
                                         "large-v1", 
                                         "large-v2", "large-v2-q5_0", "large-v2-q8_0", 
                                         "large-v3", "large-v3-q5_0",
                                         "large-v3-turbo", "large-v3-turbo-q5_0", "large-v3-turbo-q8_0"),
                                   model_dir = Sys.getenv("WHISPER_MODEL_DIR", unset = getwd()),
                                   repos = c("huggingface", "ggerganov"),
                                   version = c("1.5.4", "1.2.1"),
                                   overwrite = TRUE, 
                                   ...){
  version <- match.arg(version)
  if(!"force" %in% names(list(...))){
    x     <- match.arg(x)  
  }
  repos <- match.arg(repos)
  if(repos == "huggingface"){
    f   <- sprintf("ggml-%s.bin", x)
    url <- sprintf("https://huggingface.co/datasets/ggerganov/whisper.cpp/resolve/main/%s", f)
    url <- sprintf("https://huggingface.co/ggerganov/whisper.cpp/resolve/main/%s", f)
    if(version == "1.2.1"){
      url <- sprintf("https://huggingface.co/ggerganov/whisper.cpp/resolve/80da2d8bfee42b0e836fc3a9890373e5defc00a6/%s", f)
    }else if(version == "1.5.4"){
      url <- sprintf("https://huggingface.co/ggerganov/whisper.cpp/resolve/d15393806e24a74f60827e23e986f0c10750b358/%s", f)
    }
  }else if(repos == "ggerganov"){
    .Deprecated(msg = "whisper_download_model with argument repos = 'ggerganov' is deprecated as that resource might become unavailable for certain models, please use repos = 'huggingface'")
    f   <- sprintf("ggml-model-whisper-%s.bin", x)
    url <- sprintf("https://ggml.ggerganov.com/%s", f)
  }
  if(!dir.exists(model_dir)){
    dir.create(model_dir, recursive = TRUE)  
  }
  to <- file.path(model_dir, basename(url))
  download_failed  <- FALSE
  download_message <- "OK"
  oldtimeout <- getOption("timeout")
  if(length(oldtimeout) == 0 || is.na(as.integer(oldtimeout)) || as.integer(oldtimeout) < 60*10){
    options(timeout = 60*10)
    on.exit({
      options(timeout = oldtimeout)
    })
  }
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
                    download_success = !download_failed,
                    download_message = download_message,
                    stringsAsFactors = FALSE)
  class(out) <- c("data.frame", "whisper_download")
  out
}





#' @title Benchmark a Whisper model
#' @description Benchmark a Whisper model to see how good it runs on your architecture by printing it's performance on 
#' fake data. \url{https://github.com/ggerganov/whisper.cpp/issues/89}
#' @param object a whisper object
#' @param threads the number of threads to use, defaults to 1
#' @return invisible()
#' @export
#' @seealso \code{\link{whisper}}
#' @examples
#' \dontrun{ 
#' model <- whisper("tiny", overwrite = FALSE)
#' whisper_benchmark(model)
#' }
whisper_benchmark <- function(object = whisper(system.file(package = "audio.whisper", "models", "for-tests-ggml-tiny.bin")), 
                              threads = 1){
  stopifnot(inherits(object, "whisper"))
  whisper_print_benchmark(object$model, threads)
  invisible()
}



#' @title Get the language capabilities of Whisper
#' @description Extract the list of languages a multilingual whisper model is able to handle
#' @return a data.frame with columns id, language and language_label showing the languages
#' @export
#' @examples
#' x <- whisper_languages()
#' x
whisper_languages <- function(){
  whisper_language_info()
}