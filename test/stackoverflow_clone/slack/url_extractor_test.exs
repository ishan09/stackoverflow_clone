defmodule StackoverflowClone.Slack.UrlExtractorTest do
  use ExUnit.Case, async: true

  alias StackoverflowClone.Slack.UrlExtractor

  describe "extract_urls/1" do
    test "extracts Instagram reel URL" do
      text = "Check this out https://www.instagram.com/reel/ABC123def/ cool right?"
      assert UrlExtractor.extract_urls(text) == ["https://www.instagram.com/reel/ABC123def/"]
    end

    test "extracts Instagram post URL" do
      text = "https://instagram.com/p/xyz789/"
      assert UrlExtractor.extract_urls(text) == ["https://instagram.com/p/xyz789/"]
    end

    test "extracts YouTube watch URL" do
      text = "Watch https://www.youtube.com/watch?v=dQw4w9WgXcQ"
      assert UrlExtractor.extract_urls(text) == ["https://www.youtube.com/watch?v=dQw4w9WgXcQ"]
    end

    test "extracts short YouTube URL" do
      text = "https://youtu.be/dQw4w9WgXcQ nice"
      assert UrlExtractor.extract_urls(text) == ["https://youtu.be/dQw4w9WgXcQ"]
    end

    test "extracts YouTube Shorts URL" do
      text = "https://www.youtube.com/shorts/abc123"
      assert UrlExtractor.extract_urls(text) == ["https://www.youtube.com/shorts/abc123"]
    end

    test "extracts multiple URLs from one message" do
      text = """
      First: https://www.instagram.com/reel/AAA111/
      Second: https://youtu.be/BBB222
      """

      urls = UrlExtractor.extract_urls(text)
      assert length(urls) == 2
      assert "https://www.instagram.com/reel/AAA111/" in urls
      assert "https://youtu.be/BBB222" in urls
    end

    test "deduplicates the same URL appearing twice" do
      url = "https://www.instagram.com/reel/ABC123/"
      text = "#{url} and again #{url}"
      assert UrlExtractor.extract_urls(text) == [url]
    end

    test "returns empty list when no supported URL found" do
      assert UrlExtractor.extract_urls("just some text without URLs") == []
    end

    test "ignores unknown domains" do
      assert UrlExtractor.extract_urls("https://tiktok.com/video/123") == []
    end

    test "returns empty list for nil input" do
      assert UrlExtractor.extract_urls(nil) == []
    end

    test "extract_instagram_urls/1 is a backward-compat alias" do
      url = "https://www.instagram.com/reel/ABC123/"
      assert UrlExtractor.extract_instagram_urls(url) == [url]
    end
  end
end
