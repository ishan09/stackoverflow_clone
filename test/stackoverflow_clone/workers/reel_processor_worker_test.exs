defmodule StackoverflowClone.Workers.ReelProcessorWorkerTest do
  use ExUnit.Case

  import Mox

  alias StackoverflowClone.Workers.ReelProcessorWorker
  alias StackoverflowClone.Reels
  alias StackoverflowClone.ReelsRepo
  alias StackoverflowClone.Reels.Reel

  setup :verify_on_exit!

  @url "https://www.instagram.com/reel/test_worker/"
  @channel "C_TEST"
  @thread_ts "1234567890.000001"

  @job_args %{"url" => @url, "channel" => @channel, "thread_ts" => @thread_ts}

  setup do
    ReelsRepo.delete_all(Reel)
    :ok
  end

  defp make_job(args \\ @job_args) do
    struct(Oban.Job, id: 1, args: args, attempt: 1, max_attempts: 3)
  end

  describe "perform/1 — happy path" do
    test "downloads, transcribes, summarizes, persists, and replies" do
      StackoverflowClone.Media.DownloaderMock
      |> expect(:download, fn @url -> {:ok, "/tmp/video.mp4"} end)

      StackoverflowClone.Media.MetadataExtractorMock
      |> expect(:fetch_metadata, fn @url ->
        {:ok, %{caption: "Test caption #hashtag", raw: %{"title" => "Test"}, title: "Test",
                uploader: nil, duration: 30, platform: "Instagram"}}
      end)

      StackoverflowClone.Media.AudioExtractorMock
      |> expect(:extract, fn "/tmp/video.mp4" -> {:ok, "/tmp/video.mp3"} end)

      StackoverflowClone.Transcription.ProviderMock
      |> expect(:transcribe, fn "/tmp/video.mp3" -> {:ok, "This is the transcript"} end)

      StackoverflowClone.LLM.ProviderMock
      |> expect(:summarize, fn input ->
        assert input =~ "[CAPTION]"
        assert input =~ "Test caption"
        assert input =~ "[TRANSCRIPT]"
        assert input =~ "This is the transcript"
        {:ok, "🎯 Great summary"}
      end)

      StackoverflowClone.Slack.ClientMock
      |> expect(:reply_to_thread, fn @channel, @thread_ts, text ->
        assert text =~ "🎯 Great summary"
        :ok
      end)

      assert :ok = ReelProcessorWorker.perform(make_job())

      {:ok, reel} = Reels.get_by_url(@url)
      assert reel.status == :processed
      assert reel.summary == "🎯 Great summary"
      assert reel.transcript == "This is the transcript"
    end
  end

  describe "perform/1 — soft failures" do
    test "continues without caption when metadata fetch fails" do
      StackoverflowClone.Media.DownloaderMock
      |> expect(:download, fn @url -> {:ok, "/tmp/video.mp4"} end)

      StackoverflowClone.Media.MetadataExtractorMock
      |> expect(:fetch_metadata, fn @url -> {:error, "yt-dlp timeout"} end)

      StackoverflowClone.Media.AudioExtractorMock
      |> expect(:extract, fn "/tmp/video.mp4" -> {:ok, "/tmp/video.mp3"} end)

      StackoverflowClone.Transcription.ProviderMock
      |> expect(:transcribe, fn "/tmp/video.mp3" -> {:ok, "Transcript only"} end)

      StackoverflowClone.LLM.ProviderMock
      |> expect(:summarize, fn input ->
        refute input =~ "[CAPTION]"
        assert input =~ "[TRANSCRIPT]"
        {:ok, "Transcript-only summary"}
      end)

      StackoverflowClone.Slack.ClientMock
      |> expect(:reply_to_thread, fn @channel, @thread_ts, _text -> :ok end)

      assert :ok = ReelProcessorWorker.perform(make_job())
    end

    test "continues without transcript when transcription fails (caption present)" do
      StackoverflowClone.Media.DownloaderMock
      |> expect(:download, fn @url -> {:ok, "/tmp/video.mp4"} end)

      StackoverflowClone.Media.MetadataExtractorMock
      |> expect(:fetch_metadata, fn @url ->
        {:ok, %{caption: "Caption only", raw: nil, title: nil, uploader: nil,
                duration: nil, platform: nil}}
      end)

      StackoverflowClone.Media.AudioExtractorMock
      |> expect(:extract, fn "/tmp/video.mp4" -> {:ok, "/tmp/video.mp3"} end)

      StackoverflowClone.Transcription.ProviderMock
      |> expect(:transcribe, fn "/tmp/video.mp3" -> {:error, "Whisper failed"} end)

      StackoverflowClone.LLM.ProviderMock
      |> expect(:summarize, fn input ->
        assert input =~ "[CAPTION]"
        refute input =~ "[TRANSCRIPT]"
        {:ok, "Caption-only summary"}
      end)

      StackoverflowClone.Slack.ClientMock
      |> expect(:reply_to_thread, fn @channel, @thread_ts, _text -> :ok end)

      assert :ok = ReelProcessorWorker.perform(make_job())
    end

    test "hard fails when both caption and transcript are unavailable" do
      StackoverflowClone.Media.DownloaderMock
      |> expect(:download, fn @url -> {:ok, "/tmp/video.mp4"} end)

      StackoverflowClone.Media.MetadataExtractorMock
      |> expect(:fetch_metadata, fn @url -> {:error, "metadata error"} end)

      StackoverflowClone.Media.AudioExtractorMock
      |> expect(:extract, fn "/tmp/video.mp4" -> {:ok, "/tmp/video.mp3"} end)

      StackoverflowClone.Transcription.ProviderMock
      |> expect(:transcribe, fn "/tmp/video.mp3" -> {:error, "transcription error"} end)

      assert {:error, _reason} = ReelProcessorWorker.perform(make_job())

      {:ok, reel} = Reels.get_by_url(@url)
      assert reel.status == :failed
    end
  end

  describe "perform/1 — rate limiting" do
    test "snoozes when LLM provider is rate limited" do
      StackoverflowClone.Media.DownloaderMock
      |> expect(:download, fn @url -> {:ok, "/tmp/video.mp4"} end)

      StackoverflowClone.Media.MetadataExtractorMock
      |> expect(:fetch_metadata, fn @url ->
        {:ok, %{caption: "Caption", raw: nil, title: nil, uploader: nil, duration: nil, platform: nil}}
      end)

      StackoverflowClone.Media.AudioExtractorMock
      |> expect(:extract, fn "/tmp/video.mp4" -> {:ok, "/tmp/video.mp3"} end)

      StackoverflowClone.Transcription.ProviderMock
      |> expect(:transcribe, fn "/tmp/video.mp3" -> {:ok, "Transcript"} end)

      StackoverflowClone.LLM.ProviderMock
      |> expect(:summarize, fn _input -> {:error, {:rate_limited, 30_000}} end)

      assert {:snooze, snooze_secs} = ReelProcessorWorker.perform(make_job())
      assert snooze_secs == 30
    end

    test "snoozes when transcription provider is rate limited" do
      StackoverflowClone.Media.DownloaderMock
      |> expect(:download, fn @url -> {:ok, "/tmp/video.mp4"} end)

      StackoverflowClone.Media.MetadataExtractorMock
      |> expect(:fetch_metadata, fn @url ->
        {:ok, %{caption: "Caption", raw: nil, title: nil, uploader: nil, duration: nil, platform: nil}}
      end)

      StackoverflowClone.Media.AudioExtractorMock
      |> expect(:extract, fn "/tmp/video.mp4" -> {:ok, "/tmp/video.mp3"} end)

      StackoverflowClone.Transcription.ProviderMock
      |> expect(:transcribe, fn "/tmp/video.mp3" -> {:error, {:rate_limited, 45_500}} end)

      assert {:snooze, snooze_secs} = ReelProcessorWorker.perform(make_job())
      assert snooze_secs == 46
    end
  end

  describe "perform/1 — download failure" do
    test "marks reel as failed when download fails" do
      StackoverflowClone.Media.DownloaderMock
      |> expect(:download, fn @url -> {:error, "Download failed (exit 1)"} end)

      assert {:error, _} = ReelProcessorWorker.perform(make_job())

      {:ok, reel} = Reels.get_by_url(@url)
      assert reel.status == :failed
    end
  end

  describe "perform/1 — cache hit" do
    test "replies from cache when reel already processed" do
      {:ok, reel} = Reels.find_or_create(@url)

      Reels.mark_processed(reel, %{
        caption: "Cached caption",
        transcript: "Cached transcript",
        processed_input: "[CAPTION]\nCached caption",
        summary: "Cached summary",
        raw_metadata: nil
      })

      # No download/transcribe/LLM calls expected — only Slack reply
      StackoverflowClone.Slack.ClientMock
      |> expect(:reply_to_thread, fn @channel, @thread_ts, text ->
        assert text =~ "Cached summary"
        :ok
      end)

      assert :ok = ReelProcessorWorker.perform(make_job())
    end
  end
end
