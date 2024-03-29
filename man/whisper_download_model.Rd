% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/whisper.R
\name{whisper_download_model}
\alias{whisper_download_model}
\title{Download a pretrained Whisper model}
\usage{
whisper_download_model(
  x = c("tiny", "tiny.en", "base", "base.en", "small", "small.en", "medium",
    "medium.en", "large-v1", "large-v2", "large-v3", "large", "tiny-q5_1",
    "tiny.en-q5_1", "base-q5_1", "base.en-q5_1", "small-q5_1", "small.en-q5_1",
    "medium-q5_0", "medium.en-q5_0", "large-v2-q5_0", "large-v3-q5_0"),
  model_dir = Sys.getenv("WHISPER_MODEL_DIR", unset = getwd()),
  repos = c("huggingface", "ggerganov"),
  version = c("1.5.4", "1.2.1"),
  overwrite = TRUE,
  ...
)
}
\arguments{
\item{x}{the name of the model}

\item{model_dir}{a path where the model will be downloaded to. Defaults to the environment variable \code{WHISPER_MODEL_DIR} and if this is not set, the current working directory}

\item{repos}{character string with the repository to download the model from. Either
\itemize{
\item{'huggingface': https://huggingface.co/ggerganov/whisper.cpp - the default}
\item{'ggerganov': https://ggml.ggerganov.com/ - no longer supported as the resource by ggerganov can become unavailable}
}}

\item{version}{character string with the version of the model. Defaults to "1.5.4".}

\item{overwrite}{logical indicating to overwrite the file if the file was already downloaded. Defaults to \code{TRUE} indicating 
it will download the model and overwrite the file if the file already existed. If set to \code{FALSE},
the model will only be downloaded if it does not exist on disk yet in the \code{model_dir} folder.}

\item{...}{currently not used}
}
\value{
A data.frame with 1 row and the following columns: 
\itemize{
 \item{model: The model as provided by the input parameter \code{x}}
 \item{file_model: The path to the file on disk where the model was downloaded to}
 \item{url: The URL where the model was downloaded from}
 \item{download_success: A logical indicating if the download has succeeded or not due to internet connectivity issues}
 \item{download_message: A character string with the error message in case the downloading of the model failed}
}
}
\description{
Download a pretrained Whisper model. The list of available models are
\itemize{
\item{tiny & tiny.en: 75 MB, RAM required: ~390 MB. Multilingual and English only version.}
\item{base & base.en: 142 MB, RAM required: ~500 MB. Multilingual and English only version.}
\item{small & small.en: 466 MB, RAM required: ~1.0 GB. Multilingual and English only version.}
\item{medium & medium.en: 1.5 GB, RAM required: ~2.6 GB. Multilingual and English only version.}
\item{large-v1, large-v2, large-v3: 2.9 GB, RAM required: ~4.7 GB. Multilingual}
\item{quantised models: tiny-q5_1, tiny.en-q5_1, base-q5_1, base.en-q5_1, small-q5_1, small.en-q5_1, medium-q5_0, medium.en-q5_0, large-v2-q5_0 and large-v3-q5_0 (only - from version 1.5.4 onwards)}
}
Note that the larger models may take longer than 60 seconds to download, so consider 
increasing the timeout option in R via \code{options(timeout = 120)}
}
\examples{
path <- whisper_download_model("tiny")
path <- whisper_download_model("tiny", overwrite = FALSE)
\dontrun{
whisper_download_model("tiny.en")
whisper_download_model("base")
whisper_download_model("base.en")
whisper_download_model("small")
whisper_download_model("small.en")
whisper_download_model("medium")
whisper_download_model("medium.en")
whisper_download_model("large-v1")
whisper_download_model("large-v2")
whisper_download_model("large-v3")
whisper_download_model("tiny-q5_1")
whisper_download_model("base-q5_1")
whisper_download_model("small-q5_1")
whisper_download_model("medium-q5_0")
whisper_download_model("large-v2-q5_0")
whisper_download_model("large-v3-q5_0")
}
\dontshow{
if(file.exists(path$file_model)) file.remove(path$file_model)
}
}
\seealso{
\code{\link{whisper}}, \code{\link{predict.whisper}}, \code{\link{whisper_languages}}
}
