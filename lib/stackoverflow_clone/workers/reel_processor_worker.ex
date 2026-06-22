defmodule StackoverflowClone.Workers.ReelProcessorWorker do
  @moduledoc """
  Oban worker — full processing pipeline:

    1. Download video (yt-dlp)
    2. Fetch metadata / caption (yt-dlp --dump-json)  ← soft failure: continue on error
    3. Extract audio (ffmpeg)
    4. Transcribe (Whisper local | OpenAI)             ← soft failure: caption-only mode
    5. Assemble unified input (ContentAssembler)       ← hard fail if nothing to work with
    6. Summarize (Ollama | OpenAI)
    7. Persist all results
    8. Reply in Slack thread
    9. Clean up temp files

  Supports Instagram reels/posts and YouTube videos/shorts.
  """

  use Oban.Worker,
    queue: :reels,
    max_attempts: 3,
    unique: [period: 3600, fields: [:args]]

  require Logger

  alias StackoverflowClone.Reels
  alias StackoverflowClone.ContentAssembler
  alias StackoverflowClone.Media.Downloader
  alias StackoverflowClone.Media.AudioExtractor
  alias StackoverflowClone.Media.MetadataExtractor
  alias StackoverflowClone.Transcription.Provider, as: TranscriptionProvider
  alias StackoverflowClone.LLM.Provider, as: LLMProvider
  alias StackoverflowClone.Slack.Client, as: SlackClient
  alias StackoverflowClone.Slack.Formatter

  @impl Oban.Worker
  def perform(%Oban.Job{
        id: job_id,
        args: %{"url" => url, "channel" => channel, "thread_ts" => thread_ts}
      }) do
    Logger.metadata(oban_job_id: job_id)
    Logger.info("Processing: #{url}")

    with {:ok, reel} <- Reels.find_or_create(url),
         :ok <- skip_if_processed(reel, channel, thread_ts),
         {:ok, _} <- Reels.update_status(reel, :processing),
         {:ok, video_path} <- Downloader.download(url),
         {caption, raw_metadata} <- fetch_metadata_soft(url),
         {:ok, audio_path} <- AudioExtractor.extract(video_path),
         {transcript, temp_files} <- transcribe_soft(audio_path, [video_path]),
         {:ok, processed_input} <- assemble(caption, transcript),
         {:ok, summary} <- summarize(processed_input),
         {:ok, reel} <- persist(reel, caption, transcript, processed_input, summary, raw_metadata),
         :ok <- reply_to_slack(channel, thread_ts, reel) do
      cleanup(temp_files)
      Logger.info("Processed successfully: #{url}")
      :ok
    else
      {:skip, :already_processed} ->
        :ok

      {:error, reason} ->
        Reels.mark_failed(url)
        Logger.error("Failed #{url}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # ── Step helpers ───────────────────────────────────────────────────────────

  # Metadata is best-effort; a missing caption doesn't block processing.
  defp fetch_metadata_soft(url) do
    case MetadataExtractor.fetch_metadata(url) do
      {:ok, %{caption: caption, raw: raw}} ->
        Logger.info("caption_present=#{!is_nil(caption)}")
        {caption, raw}

      {:error, reason} ->
        Logger.warning("Metadata fetch skipped: #{reason}")
        {nil, nil}
    end
  end

  # Transcription is best-effort when caption is available.
  # Returns {transcript | nil, temp_file_paths}.
  defp transcribe_soft(audio_path, existing_temp_files) do
    case TranscriptionProvider.transcribe(audio_path) do
      {:ok, transcript} ->
        Logger.info("transcript_length=#{String.length(transcript)}")
        {transcript, [audio_path | existing_temp_files]}

      {:error, reason} ->
        Logger.warning("Transcription skipped: #{reason}")
        {nil, [audio_path | existing_temp_files]}
    end
  end

  defp assemble(caption, transcript) do
    case ContentAssembler.build_input(caption, transcript) do
      {:ok, _} = ok ->
        ok

      {:error, :no_usable_content} ->
        Logger.error("No usable content from caption or transcript")
        {:error, "No usable content to summarize"}
    end
  end

  defp summarize(processed_input) do
    provider = Application.get_env(:stackoverflow_clone, :llm_provider, :ollama)
    Logger.info("provider_used=#{provider}")
    LLMProvider.summarize(processed_input)
  end

  defp persist(reel, caption, transcript, processed_input, summary, raw_metadata) do
    Reels.mark_processed(reel, %{
      caption: caption,
      transcript: transcript,
      processed_input: processed_input,
      summary: summary,
      raw_metadata: raw_metadata
    })
  end

  # ── Slack reply ────────────────────────────────────────────────────────────

  defp skip_if_processed(%{status: :processed} = reel, channel, thread_ts) do
    Logger.info("Already processed, replying from cache: #{reel.url}")
    reply_to_slack(channel, thread_ts, reel)
    {:skip, :already_processed}
  end

  defp skip_if_processed(_reel, _channel, _thread_ts), do: :ok

  defp reply_to_slack(channel, thread_ts, reel) do
    message = Formatter.format_reply(reel.summary, reel.transcript)
    SlackClient.reply_to_thread(channel, thread_ts, message)
  end

  # ── Cleanup ────────────────────────────────────────────────────────────────

  defp cleanup(paths) do
    Enum.each(paths, fn path ->
      if path && File.exists?(path) do
        case File.rm(path) do
          :ok -> Logger.debug("Cleaned up #{path}")
          {:error, reason} -> Logger.warning("Could not delete #{path}: #{reason}")
        end
      end
    end)
  end
end
