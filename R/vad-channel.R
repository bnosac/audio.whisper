

#' @title Predict to which channel a transcription section belongs
#' @description Audio files containing 2 channels which were transcribed with \code{\link{predict.whisper}}, 
#' you can use the results of a Voice Activity Detection by channel (either with R packages 
#' \code{audio.vadwebrtc} or \code{audio.vadsilero}) to assign the text segments to each of the channels.\cr
#' This is done by looking for each text segment how many seconds overlap there is with the voiced sections which are identified
#' by the Voice Activity Detection.
#' @param object an object of class \code{whisper_transcription} as returned by \code{\link{predict.whisper}}
#' @param vad an object of class \code{webrtc-gmm-bychannel} as returned by function \code{VAD_channel} from R package \code{audio.vadwebrtc} with information of the detected voice in at least channels 1 and 2.
#' ar a list with element vad_segments containing a data.frame with columns channel, start, end and has_voice with information at which second
#' there was a voice in the audio
#' @param type character string with currently only possible value: 'channel' which does a 2-speaker channel assignment
#' @param threshold numeric in 0-1 range indicating if the difference between the probability that the segment was from the left channel 1 or the right channel 2 is smaller than this amount, the column \code{channel} will be set to 'both'. Defaults to 0.
#' @param ... not used
#' @return an object of class \code{whisper_transcription} as documented in \code{\link{predict.whisper}} 
#' where element \code{data} contains the following extra columns indicating which channel the transcription is probably from
#' \itemize{
#' \item{channel: either 'left', 'right' or 'both' indicating the transcription segment was either from the left channel (1), the right channel (2) or probably from both as identified by the Voice Activity Detecion}
#' \item{channel_probability: a number between 0 and 1 indicating for that specific segment the ratio of the amount of voiced seconds in the most probably channel to 
#' the sum of the amount of voiced seconds in the left + the right channel}
#' \item{duration: how long (in seconds) the from-to segment is}
#' \item{duration_voiced_left: how many seconds there was a voiced signal on the left channel (channel 1) as identified by \code{vad}}
#' \item{duration_voiced_right: how many seconds there was a voiced signal on the right channel (channel 2) as identified by \code{vad}}
#' }
#' @export
#' @seealso \code{\link{predict.whisper}}
#' @examples
#' library(audio.whisper)
#' model <- whisper("tiny")
#' audio <- system.file(package = "audio.whisper", "samples", "stereo.wav")
#' trans <- predict(model, audio, language = "es")
#' \dontrun{
#' library(audio.vadwebrtc)
#' vad   <- VAD_channel(audio, channels = "all", mode = "veryaggressive", milliseconds = 30)
#' }
#' vad   <- list(vad_segments = rbind(
#'   data.frame(channel = 1, start = c(0, 5, 15, 22), end = c(5, 9, 18, 23), has_voice = TRUE),
#'   data.frame(channel = 2, start = c(2, 9.5, 19, 22), end = c(2.5, 13.5, 21, 23), has_voice = TRUE)))
#' out <- predict(trans, vad, type = "channel", threshold = 0)
#' out$data
predict.whisper_transcription <- function(object, vad, type = "channel", threshold = 0, ...){
  stopifnot(inherits(object, "whisper_transcription"))
  if(!inherits(vad, "webrtc-gmm-bychannel")){
    #warning("provided vad is not of type webrtc-gmm-bychannel")
  }
  fields             <- colnames(object$data)
  sentences          <- object$data
  today              <- Sys.Date()
  sentences$start    <- as.numeric(difftime(as.POSIXct(paste(today, sentences$from, sep = " "), format = "%Y-%m-%d %H:%M:%OS"), as.POSIXct(paste(today, "00:00:00.000", sep = " "), format = "%Y-%m-%d %H:%M:%OS"), units = "secs"))
  sentences$end      <- as.numeric(difftime(as.POSIXct(paste(today, sentences$to,   sep = " "), format = "%Y-%m-%d %H:%M:%OS"), as.POSIXct(paste(today, "00:00:00.000", sep = " "), format = "%Y-%m-%d %H:%M:%OS"), units = "secs"))
  sentences$duration <- sentences$end - sentences$start
  
  #voiced <- audio.vadwebrtc:::VAD_channel(newdata, mode = mode)
  voiced <- vad
  left   <- voiced$vad_segments[voiced$vad_segments$channel %in% 1 & voiced$vad_segments$has_voice, ]
  right  <- voiced$vad_segments[voiced$vad_segments$channel %in% 2 & voiced$vad_segments$has_voice, ]
  sentences$duration_voiced_left <- mapply(start = sentences$start, end = sentences$end, FUN = function(start, end, voiced){
    voiced      <- voiced[voiced$end >= start & voiced$start <= end, ]
    voiced$from <- ifelse(voiced$start > start, voiced$start, start)
    voiced$to   <- ifelse(voiced$end > end, end, voiced$end)
    voiced      <- voiced[voiced$from <= voiced$to, ]
    sum(voiced$to - voiced$from, na.rm = TRUE)
  }, MoreArgs = list(voiced = left), SIMPLIFY = TRUE, USE.NAMES = FALSE)
  sentences$duration_voiced_left <- as.numeric(sentences$duration_voiced_left)
  sentences$duration_voiced_right <- mapply(start = sentences$start, end = sentences$end, FUN = function(start, end, voiced){
    voiced      <- voiced[voiced$end >= start & voiced$start <= end, ]
    voiced$from <- ifelse(voiced$start > start, voiced$start, start)
    voiced$to   <- ifelse(voiced$end > end, end, voiced$end)
    voiced      <- voiced[voiced$from <= voiced$to, ]
    sum(voiced$to - voiced$from, na.rm = TRUE)
  }, MoreArgs = list(voiced = right), SIMPLIFY = TRUE, USE.NAMES = FALSE)
  sentences$duration_voiced_right <- as.numeric(sentences$duration_voiced_right)
  sentences$channel                     <- ifelse(sentences$duration_voiced_left > sentences$duration_voiced_right, "left", "right")
  sentences$channel_left_probability    <- sentences$duration_voiced_left  / (sentences$duration_voiced_left + sentences$duration_voiced_right)
  sentences$channel_right_probability   <- sentences$duration_voiced_right / (sentences$duration_voiced_left + sentences$duration_voiced_right)
  sentences$channel_probability         <- ifelse(sentences$channel_left_probability > sentences$channel_right_probability, sentences$channel_left_probability, sentences$channel_right_probability)
  sentences$left_pct                    <- round(sentences$duration_voiced_left  / (sentences$duration_voiced_left + sentences$duration_voiced_right), digits = 2)
  sentences$right_pct                   <- round(sentences$duration_voiced_right / (sentences$duration_voiced_left + sentences$duration_voiced_right), digits = 2)
  sentences$channel                     <- ifelse(abs(sentences$left_pct - sentences$right_pct) < threshold, "both", sentences$channel)
  sentences$segment_pct_nonsilent_left  <- sentences$duration_voiced_left / sentences$duration
  sentences$segment_pct_nonsilent_right <- sentences$duration_voiced_right / sentences$duration
  #c("segment", "segment_offset", "from", "to", "text", "speaker")
  object$data <- sentences[, unique(c(fields, "channel", "channel_probability", "duration", "duration_voiced_left", "duration_voiced_right"))]
  object
}