defmodule StackoverflowClone.Slack.FormatterTest do
  use ExUnit.Case, async: true

  alias StackoverflowClone.Slack.Formatter

  describe "format_reply/2" do
    test "returns summary when no transcript" do
      result = Formatter.format_reply("🎯 Core Idea: something cool", nil)
      assert result == "🎯 Core Idea: something cool"
    end

    test "appends transcript section when present" do
      result = Formatter.format_reply("Summary here", "This is the transcript")
      assert result =~ "Summary here"
      assert result =~ "📜 *Transcript*"
      assert result =~ "This is the transcript"
    end

    test "uses fallback message when summary is nil" do
      result = Formatter.format_reply(nil, nil)
      assert result == "_No summary available._"
    end

    test "trims excessive whitespace from summary" do
      result = Formatter.format_reply("  trimmed  ", nil)
      assert result == "trimmed"
    end

    test "truncates long transcripts to configured max_length" do
      long_transcript = String.duplicate("a", 1000)
      result = Formatter.format_reply("Summary", long_transcript)
      assert result =~ "…"
      # Transcript section should be truncated
      assert String.length(result) < 1000 + 200
    end

    test "does not add ellipsis for short transcripts" do
      result = Formatter.format_reply("Summary", "Short")
      refute result =~ "…"
    end

    test "skips empty string transcript" do
      result = Formatter.format_reply("Summary", "")
      refute result =~ "📜"
      assert result == "Summary"
    end
  end
end
