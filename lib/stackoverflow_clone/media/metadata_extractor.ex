defmodule StackoverflowClone.Media.MetadataExtractor do
  @moduledoc """
  Extracts metadata (caption, title, platform, etc.) from a video URL
  using yt-dlp --dump-json. Works for Instagram and YouTube.
  Does NOT download the video — network-only call.
  """

  @callback fetch_metadata(url :: String.t()) ::
              {:ok, map()} | {:error, String.t()}

  require Logger

  alias StackoverflowClone.CircuitBreaker
  alias StackoverflowClone.Security.UrlValidator

  @spec fetch_metadata(String.t()) :: {:ok, map()} | {:error, String.t()}
  def fetch_metadata(url) do
    with :ok <- UrlValidator.validate(url) do
      CircuitBreaker.call(:yt_dlp, fn -> do_fetch(url) end)
    end
  end

  defp do_fetch(url) do
    Logger.info("Fetching metadata url=#{url}")

    args = ["--dump-json", "--no-download", "--no-warnings", url]

    case System.cmd("yt-dlp", args, stderr_to_stdout: true) do
      {output, 0} ->
        parse_output(output)

      {output, exit_code} ->
        Logger.warning("yt-dlp metadata exit=#{exit_code}: #{String.slice(output, 0, 300)}")
        {:error, "Metadata fetch failed (exit #{exit_code})"}
    end
  end

  defp parse_output(output) do
    line = output |> String.split("\n", trim: true) |> List.first("")

    case Jason.decode(line) do
      {:ok, data} -> {:ok, extract_fields(data)}
      {:error, _} -> {:error, "Failed to parse metadata JSON"}
    end
  end

  defp extract_fields(data) do
    %{
      title: get_string(data, "title"),
      caption: get_string(data, "description"),
      uploader: get_string(data, "uploader"),
      duration: Map.get(data, "duration"),
      platform: get_string(data, "extractor_key"),
      raw: data
    }
  end

  defp get_string(map, key) do
    case Map.get(map, key) do
      v when is_binary(v) and v != "" -> v
      _ -> nil
    end
  end
end
