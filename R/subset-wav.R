

if(FALSE){
  library(av)
  library(audio.vadwebrtc)
  library(audio)
  download.file(url = "https://www.ubu.com/media/sound/dec_francis/Dec-Francis-E_rant1.mp3", 
                destfile = "rant1.mp3", mode = "wb")
  av_audio_convert("rant1.mp3", output = "output.wav", format = "wav", sample_rate = 16000, channels = 1)
  av_media_info("output.wav")
  vad    <- VAD("output.wav")
  voiced <- is.voiced(vad, units = "milliseconds")
  voiced <- subset(voiced, has_voice == TRUE)
  p <- subset.wav("output.wav", offset = voiced$start, duration = voiced$duration)
  av_media_info(p$file)
  play(audio::load.wave(p$file))
  p <- subset.wav("output.wav", offset = voiced$start, duration = 5*60*1000)
  av_media_info(p$file)
  play(audio::load.wave(p$file))
  p <- subset.wav("output.wav", offset = c(1, 7000), duration = c(1009, 5*60*1000))
  av_media_info(p$file)
  play(audio::load.wave(p$file))
}

subset.wav <- function(x, offset, duration){
  # x: wav file
  # offset: vector of integer offsets in milliseconds
  # duration: vector of durations in milliseconds
  requireNamespace("audio")
  #download.file("https://github.com/jwijffels/example/raw/main/example.wav", "example.wav")
  #x <- "example.wav"
  #x <- system.file(package = "audio.whisper", "samples", "stereo.wav")
  stopifnot(length(offset) == length(duration))
  wave <- audio::load.wave(x)
  sample_rate <- attributes(wave)$rate
  bits        <- attributes(wave)$bits
  if(is.matrix(wave)){
    audio_duration <- ncol(wave) / sample_rate
  }else{
    audio_duration <- length(wave) / sample_rate
  }
  regions <- list()
  regions <- lapply(seq_along(offset), FUN = function(i){
    seq.int(offset[i] * bits, by = 1L, length.out = duration[i] * bits)
  })
  regions <- unlist(regions, use.names = FALSE)
  if(is.matrix(wave)){
    wave <- wave[, regions, drop = FALSE]
  }else{
    wave <- wave[regions]
  }
  p <- file.path(tempdir(check = TRUE), basename(x))
  audio::save.wave(wave, p)
  
  ## extract what was removed
  voiced     <- data.frame(start = offset, end = offset + duration, duration = duration, has_voice = TRUE, stringsAsFactors = FALSE)
  required   <- c(1, voiced$end + 1)
  voiced     <- rbind(voiced, 
                      data.frame(start = required, end = rep(NA_integer_, length(required)), duration = rep(NA, length(required)), has_voice = rep(FALSE, length(required)), stringsAsFactors = FALSE))
  voiced     <- voiced[order(voiced$start, decreasing = FALSE), ]
  voiced     <- voiced[!duplicated(voiced$start), ]
  voiced$end <- ifelse(is.na(voiced$end), c(voiced$start[-1] - 1, audio_duration * 1000L), voiced$end)
  voiced$duration <- voiced$end - voiced$start
  skipped     <- voiced[voiced$has_voice == FALSE, ]
  skipped$taken_away <- cumsum(skipped$duration)
  skipped <- data.frame(start = skipped$end, removed = skipped$taken_away)

  
  
  # sentences$start <- as.numeric(difftime(as.POSIXct(paste(Sys.Date(), sentences$from, sep = " "), "%Y-%m-%d %H:%M:%S:OS"), as.POSIXct(Sys.Date()), units = "secs"))
  # sentences$end   <- as.numeric(difftime(as.POSIXct(paste(Sys.Date(), sentences$to, sep = " "), "%Y-%m-%d %H:%M:%S:OS"), as.POSIXct(Sys.Date()), units = "secs"))
  
  
  
  
  list(file = p, skipped = skipped, voiced = voiced)
}