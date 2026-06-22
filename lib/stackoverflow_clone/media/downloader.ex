defmodule StackoverflowClone.Media.Downloader do
  @moduledoc "Downloads video from a URL using yt-dlp."

  @callback download(url :: String.t()) :: {:ok, String.t()} | {:error, String.t()}

  require Logger

  alias StackoverflowClone.CircuitBreaker
  alias StackoverflowClone.Security.UrlValidator

  @impl_mod __MODULE__

  @spec download(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def download(url) do
    with :ok <- UrlValidator.validate(url) do
      CircuitBreaker.call(:yt_dlp, fn -> do_download(url) end)
    end
  end

  defp do_download(url) do
    job_id = random_id()
    output_template = "/tmp/reel_#{job_id}.%(ext)s"

    Logger.info("Downloading job=#{job_id} url=#{url}")

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
        Logger.error("yt-dlp exit=#{exit_code} output=#{String.slice(output, 0, 300)}")
        {:error, "Download failed (exit #{exit_code})"}
    end
  end

  defp find_downloaded_file(job_id) do
    case Path.wildcard("/tmp/reel_#{job_id}.*") do
      [path | _] -> {:ok, path}
      [] -> {:error, "Downloaded file not found for job #{job_id}"}
    end
  end

  defp random_id do
    :crypto.strong_rand_bytes(8) |> Base.hex_encode32(case: :lower, padding: false)
  end
end
