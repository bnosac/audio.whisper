
#' @export
vad <- function(path = system.file(package = "audio.whisper", "samples", "jfk.wav"), 
                vad_model = system.file(package = "audio.whisper", "silero", "ggml-silero-v5.1.2.bin"), ...){
  silero_vad(path, vad_model, ...)
}

#start = Sys.time()
#i = (audio.whisper:::vad("audio.wav"))
#end = Sys.time()
#difftime(end, start, units = "secs")