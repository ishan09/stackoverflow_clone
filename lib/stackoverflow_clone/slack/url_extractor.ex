defmodule StackoverflowClone.Slack.UrlExtractor do
  @moduledoc """
  Extracts supported video URLs from Slack message text.
  Currently supports Instagram reels/posts and YouTube videos/shorts.
  Add new platform patterns to @patterns to extend.
  """

  @patterns [
    # Instagram reels and posts
    ~r/https?:\/\/(?:www\.)?instagram\.com\/(?:reel|p)\/([\w-]+)/,
    # YouTube long-form: youtube.com/watch?v=ID
    ~r/https?:\/\/(?:www\.)?youtube\.com\/watch\?(?:[^&\s]*&)*v=([\w-]+)/,
    # YouTube short URL: youtu.be/ID
    ~r/https?:\/\/youtu\.be\/([\w-]+)/,
    # YouTube Shorts: youtube.com/shorts/ID
    ~r/https?:\/\/(?:www\.)?youtube\.com\/shorts\/([\w-]+)/
  ]

  @doc "Returns all unique supported video URLs found in text."
  @spec extract_urls(String.t() | nil) :: [String.t()]
  def extract_urls(nil), do: []

  def extract_urls(text) do
    @patterns
    |> Enum.flat_map(&Regex.scan(&1, text, capture: :first))
    |> List.flatten()
    |> Enum.uniq()
  end

  # Kept for backward compatibility
  @doc false
  @spec extract_instagram_urls(String.t() | nil) :: [String.t()]
  def extract_instagram_urls(text), do: extract_urls(text)
end
