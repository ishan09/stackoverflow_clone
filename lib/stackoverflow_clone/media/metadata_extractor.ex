defmodule StackoverflowClone.Media.MetadataExtractor do
  @moduledoc """
  Extracts metadata (caption, title, etc.) from a video URL using yt-dlp --dump-json.
  Works for Instagram reels/posts and YouTube videos/shorts.
  Does NOT download the video — fast, network-only call.
  """

  require Logger

  @type metadata :: %{
          title: String.t() | nil,
          caption: String.t() | nil,
          uploader: String.t() | nil,
          duration: number() | nil,
          platform: String.t() | nil,
          raw: map()
        }

  @spec fetch_metadata(String.t()) :: {:ok, metadata()} | {:error, String.t()}
  def fetch_metadata(url) do
    Logger.info("Fetching metadata: #{url}")

    args = ["--dump-json", "--no-download", "--no-warnings", url]

    case System.cmd("yt-dlp", args, stderr_to_stdout: true) do
      {output, 0} ->
        parse_output(output)

      {output, exit_code} ->
        snippet = String.slice(output, 0, 300)
        Logger.warning("yt-dlp metadata exit #{exit_code}: #{snippet}")
        {:error, "Metadata fetch failed (exit #{exit_code})"}
    end
  end

  defp parse_output(output) do
    # yt-dlp may emit multiple JSON lines for playlists; take the first
    line = output |> String.split("\n", trim: true) |> List.first("")

    case Jason.decode(line) do
      {:ok, data} ->
        {:ok, extract_fields(data)}

      {:error, _} ->
        Logger.warning("Could not parse yt-dlp JSON output")
        {:error, "Failed to parse metadata JSON"}
    end
  end

  defp extract_fields(data) do
    %{
      title: get_string(data, "title"),
      # Instagram stores the post caption in "description"; YouTube uses "description" for the bio
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
