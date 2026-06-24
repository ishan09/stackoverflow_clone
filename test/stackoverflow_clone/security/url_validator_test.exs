defmodule StackoverflowClone.Security.UrlValidatorTest do
  use ExUnit.Case, async: true

  alias StackoverflowClone.Security.UrlValidator

  describe "validate/1 — allowed URLs" do
    test "accepts Instagram reel URL" do
      assert :ok = UrlValidator.validate("https://www.instagram.com/reel/ABC123def/")
    end

    test "accepts Instagram post URL" do
      assert :ok = UrlValidator.validate("https://instagram.com/p/ABC123/")
    end

    test "accepts YouTube watch URL" do
      assert :ok = UrlValidator.validate("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
    end

    test "accepts short YouTube URL" do
      assert :ok = UrlValidator.validate("https://youtu.be/dQw4w9WgXcQ")
    end

    test "accepts YouTube Shorts URL" do
      assert :ok = UrlValidator.validate("https://www.youtube.com/shorts/abc123")
    end

    test "accepts mobile YouTube URL" do
      assert :ok = UrlValidator.validate("https://m.youtube.com/watch?v=dQw4w9WgXcQ")
    end

    test "accepts http scheme" do
      assert :ok = UrlValidator.validate("http://www.youtube.com/watch?v=abc123")
    end
  end

  describe "validate/1 — scheme rejection" do
    test "rejects ftp scheme" do
      assert {:error, msg} = UrlValidator.validate("ftp://www.youtube.com/watch?v=abc")
      assert msg =~ "not allowed"
    end

    test "rejects file scheme" do
      assert {:error, _} = UrlValidator.validate("file:///etc/passwd")
    end

    test "rejects javascript scheme" do
      assert {:error, _} = UrlValidator.validate("javascript://www.youtube.com/watch?v=x")
    end
  end

  describe "validate/1 — host rejection" do
    test "rejects unknown host" do
      assert {:error, msg} = UrlValidator.validate("https://evil.com/reel/abc")
      assert msg =~ "not an allowed video platform"
    end

    test "rejects subdomain of allowed host" do
      assert {:error, _} = UrlValidator.validate("https://evil.instagram.com/reel/abc")
    end

    test "rejects URL with no host" do
      assert {:error, msg} = UrlValidator.validate("https:///path")
      assert msg =~ "Invalid URL"
    end
  end

  describe "validate/1 — control characters" do
    test "rejects null byte" do
      assert {:error, msg} = UrlValidator.validate("https://www.youtube.com/watch?v=\x00abc")
      assert msg =~ "control characters"
    end

    test "rejects newline" do
      assert {:error, msg} = UrlValidator.validate("https://www.youtube.com/\nwatch?v=abc")
      assert msg =~ "control characters"
    end

    test "rejects carriage return" do
      assert {:error, _} = UrlValidator.validate("https://www.youtube.com/\rwatch?v=abc")
    end
  end

  describe "validate/1 — length check" do
    test "rejects URL exceeding 2048 bytes" do
      long_path = String.duplicate("a", 2050)
      url = "https://www.youtube.com/#{long_path}"
      assert {:error, msg} = UrlValidator.validate(url)
      assert msg =~ "maximum length"
    end

    test "accepts URL at exactly 2048 bytes" do
      padding = String.duplicate("a", 2048 - String.length("https://www.youtube.com/"))
      url = "https://www.youtube.com/#{padding}"
      # May fail host check but must not fail length check
      case UrlValidator.validate(url) do
        :ok -> assert true
        {:error, msg} -> refute msg =~ "maximum length"
      end
    end
  end

  describe "validate/1 — type check" do
    test "rejects non-string input" do
      assert {:error, "URL must be a string"} = UrlValidator.validate(nil)
      assert {:error, "URL must be a string"} = UrlValidator.validate(123)
    end
  end
end
