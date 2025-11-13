
#' @title Voice Activity Detection using Silero
#' @description Voice Activity Detection using Silero
#' @param path the path to the wav file
#' @param vad_model the path to the VAD model. Defaults to the ggml-silero-v5.1.2.bin in the silero folder shipped with this package
#' @param threshold VAD threshold for speech recognition. Defaults to 0.5.
#' @param min_speech_duration VAD minimum speech duration of voiced speech in milliseconds. Defaults to 250 milliseconds
#' @param min_silence_duration VAD minimum silence duration in milliseconds in order to split segments. Defaults to 100 milliseconds.
#' @param max_speech_duration VAD maximum speech duration - auto-split longer speech segments. Defaults to -1.
#' @param pad VAD speech padding in milliseconds to extend segments. Defaults to 30.
#' @param overlap VAD samples overlap - seconds between segments - to allow a bit more context. Defaults to 0.1.
#' @param n_threads multithreading - number of threads to use. Defaults to 1.
#' @param probabilities logical indicating to return probabilities. Defaulst to FALSE.
#' @param ... passed on to the C++ silero_vad function
#' @return an object of class \code{silero_vad} which is list with the following elements: 
#' \itemize{
#' \item{n_segments: the number of voiced segments}
#' \item{probabilities: the probabilities of voice in the audio}
#' \item{data: a data.frame with columns: segment, from, to, has_voice where from/to are in seconds. The data contains only voices segments.}
#' \item{params: a list of hyperparameters passed on to the model scoring function}
#' }
#' 
#' 
#' @export
#' @seealso \code{\link{predict.whisper}}
#' @examples
#' model <- system.file(package = "audio.whisper", "silero", "ggml-silero-v6.2.0.bin")
#' model <- system.file(package = "audio.whisper", "silero", "ggml-silero-v5.1.2.bin")
#' audio <- system.file(package = "audio.whisper", "samples", "jfk.wav")
#' voice <- vad(audio, vad_model = model)
#' voice <- vad(audio, threshold = 0.5, min_speech_duration = 1000, min_silence_duration = 100)
#' voice <- vad(audio, probabilities = TRUE)
vad <- function(path = system.file(package = "audio.whisper", "samples", "jfk.wav"), 
                vad_model = system.file(package = "audio.whisper", "silero", "ggml-silero-v5.1.2.bin"), 
                threshold = 0.5,
                min_speech_duration = 250,
                min_silence_duration = 100,
                max_speech_duration = -1,
                pad = 30,
                overlap = 0.1,
                n_threads = 1,
                probabilities = FALSE,
                ...){
  out <- silero_vad(path, vad_model, 
                    vad_threshold = threshold, 
                    vad_min_speech_duration_ms = min_speech_duration, 
                    vad_min_silence_duration_ms = min_silence_duration,
                    vad_max_speech_duration_s = max_speech_duration,
                    vad_speech_pad_ms = pad,
                    vad_samples_overlap = overlap,
                    n_threads = n_threads,
                    probabilities = probabilities,
                    ...)
  class(out) <- "silero_vad"
  out
}

#start = Sys.time()
#i = (audio.whisper:::vad("audio.wav"))
#end = Sys.time()
#difftime(end, start, units = "secs")