defmodule StackoverflowClone.Slack.UrlExtractor do
  @instagram_pattern ~r/https?:\/\/(?:www\.)?instagram\.com\/(?:reel|p)\/([\w-]+)/

  @doc "Returns all unique Instagram reel/post URLs found in text."
  @spec extract_instagram_urls(String.t()) :: [String.t()]
  def extract_instagram_urls(nil), do: []

  def extract_instagram_urls(text) do
    @instagram_pattern
    |> Regex.scan(text, capture: :first)
    |> List.flatten()
    |> Enum.uniq()
  end
end
