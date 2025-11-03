

#' @title Voice Activity Detection using Silero
#' @description Voice Activity Detection using Silero
#' @param path TODO
#' @param vad_model TODO
#' @param ... passed on to the C++ silero_vad function
#' @return TODO
#' @export
#' @seealso \code{\link{predict.whisper}}
#' @examples
#' audio <- system.file(package = "audio.whisper", "samples", "jfk.wav")
#' voice <- vad(audio)
#' voice <- vad(audio, use_gpu = TRUE)
vad <- function(path = system.file(package = "audio.whisper", "samples", "jfk.wav"), 
                vad_model = system.file(package = "audio.whisper", "silero", "ggml-silero-v5.1.2.bin"), ...){
  out <- silero_vad(path, vad_model, ...)
  class(out) <- "silero_vad"
  out
}

#start = Sys.time()
#i = (audio.whisper:::vad("audio.wav"))
#end = Sys.time()
#difftime(end, start, units = "secs")