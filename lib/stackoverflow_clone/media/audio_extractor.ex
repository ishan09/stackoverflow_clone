defmodule StackoverflowClone.Media.AudioExtractor do
  @moduledoc "Extracts audio track from a video file using ffmpeg."

  require Logger

  @spec extract(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def extract(video_path) do
    audio_path = Path.rootname(video_path) <> ".mp3"

    Logger.info("Extracting audio: #{video_path} -> #{audio_path}")

    args = [
      "-i", video_path,
      "-vn",
      "-acodec", "libmp3lame",
      "-q:a", "4",
      "-y",
      audio_path
    ]

    case System.cmd("ffmpeg", args, stderr_to_stdout: true) do
      {_output, 0} ->
        {:ok, audio_path}

      {output, exit_code} ->
        Logger.error("ffmpeg exited #{exit_code}: #{output}")
        {:error, "Audio extraction failed (exit #{exit_code})"}
    end
  end
end
