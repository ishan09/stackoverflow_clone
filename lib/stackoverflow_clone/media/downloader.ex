defmodule StackoverflowClone.Media.Downloader do
  @moduledoc "Downloads video from a URL using yt-dlp."

  require Logger

  @spec download(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def download(url) do
    job_id = random_id()
    output_template = "/tmp/reel_#{job_id}.%(ext)s"

    Logger.info("Downloading reel #{job_id}: #{url}")

    args = [
      "--no-playlist",
      "--output", output_template,
      "--format", "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best",
      "--merge-output-format", "mp4",
      url
    ]

    case System.cmd("yt-dlp", args, stderr_to_stdout: true) do
      {_output, 0} ->
        find_downloaded_file(job_id)

      {output, exit_code} ->
        Logger.error("yt-dlp exited #{exit_code}: #{output}")
        {:error, "Download failed (exit #{exit_code})"}
    end
  end

  defp find_downloaded_file(job_id) do
    pattern = "/tmp/reel_#{job_id}.*"

    case Path.wildcard(pattern) do
      [path | _] -> {:ok, path}
      [] -> {:error, "Downloaded file not found for job #{job_id}"}
    end
  end

  defp random_id do
    :crypto.strong_rand_bytes(8) |> Base.hex_encode32(case: :lower, padding: false)
  end
end
