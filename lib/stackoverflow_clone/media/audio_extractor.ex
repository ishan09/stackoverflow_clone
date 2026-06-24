defmodule StackoverflowClone.Media.AudioExtractor do
  @moduledoc "Extracts audio track from a video file using ffmpeg."

  @callback extract(video_path :: String.t()) :: {:ok, String.t()} | {:error, String.t()}

  require Logger

  @spec extract(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def extract(video_path) do
    with :ok <- validate_path(video_path) do
      do_extract(video_path)
    end
  end

  defp do_extract(video_path) do
    audio_path = Path.rootname(video_path) <> ".mp3"

    Logger.info("Extracting audio video_path=#{video_path}")

    args = ["-i", video_path, "-vn", "-acodec", "libmp3lame", "-q:a", "4", "-y", audio_path]

    case System.cmd("ffmpeg", args, stderr_to_stdout: true) do
      {_output, 0} ->
        {:ok, audio_path}

      {output, exit_code} ->
        Logger.error("ffmpeg exit=#{exit_code} output=#{String.slice(output, 0, 300)}")
        {:error, "Audio extraction failed (exit #{exit_code})"}
    end
  end

  # Prevent path traversal: file must be in /tmp and have no null bytes
  defp validate_path(path) do
    cond do
      not String.starts_with?(path, "/tmp/") ->
        {:error, "Video path must be inside /tmp"}

      String.contains?(path, "\x00") ->
        {:error, "Path contains null bytes"}

      String.match?(path, ~r/\.\./) ->
        {:error, "Path traversal not allowed"}

      true ->
        :ok
    end
  end
end
