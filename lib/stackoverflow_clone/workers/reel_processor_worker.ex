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
  alias StackoverflowClone.Slack.Formatter

  @impl Oban.Worker
  def perform(%Oban.Job{
        id: job_id,
        args: %{"url" => url, "channel" => channel, "thread_ts" => thread_ts}
      }) do
    Logger.metadata(oban_job_id: job_id)
    Logger.info("Processing: #{url}")

    downloader = module(:downloader_module, StackoverflowClone.Media.Downloader)
    audio_extractor = module(:audio_extractor_module, StackoverflowClone.Media.AudioExtractor)
    metadata_extractor = module(:metadata_extractor_module, StackoverflowClone.Media.MetadataExtractor)
    slack_client = module(:slack_client_module, StackoverflowClone.Slack.Client)

    with {:ok, reel} <- Reels.find_or_create(url),
         :ok <- skip_if_processed(reel, channel, thread_ts, slack_client),
         {:ok, _} <- Reels.update_status(reel, :processing),
         {:ok, video_path} <- downloader.download(url),
         {caption, raw_metadata} <- fetch_metadata_soft(url, metadata_extractor),
         {:ok, audio_path} <- audio_extractor.extract(video_path),
         {transcript, temp_files} <- transcribe_soft(audio_path, [video_path]),
         {:ok, processed_input} <- assemble(caption, transcript),
         {:ok, summary} <- summarize(processed_input),
         {:ok, reel} <- persist(reel, caption, transcript, processed_input, summary, raw_metadata),
         :ok <- reply_to_slack(channel, thread_ts, reel, slack_client) do
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

  defp fetch_metadata_soft(url, metadata_extractor) do
    case metadata_extractor.fetch_metadata(url) do
      {:ok, %{caption: caption, raw: raw}} ->
        Logger.info("caption_present=#{!is_nil(caption)}")
        {caption, raw}

      {:error, reason} ->
        Logger.warning("Metadata fetch skipped: #{reason}")
        {nil, nil}
    end
  end

  defp transcribe_soft(audio_path, existing_temp_files) do
    transcription_mod = module(:transcription_module, nil)
    provider = StackoverflowClone.Transcription.Provider

    transcribe_fn =
      if transcription_mod do
        fn path -> transcription_mod.transcribe(path) end
      else
        fn path -> provider.transcribe(path) end
      end

    case transcribe_fn.(audio_path) do
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

    llm_mod = module(:llm_module, nil)

    if llm_mod do
      llm_mod.summarize(processed_input)
    else
      StackoverflowClone.LLM.Provider.summarize(processed_input)
    end
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

  defp skip_if_processed(%{status: :processed} = reel, channel, thread_ts, slack_client) do
    Logger.info("Already processed, replying from cache: #{reel.url}")
    reply_to_slack(channel, thread_ts, reel, slack_client)
    {:skip, :already_processed}
  end

  defp skip_if_processed(_reel, _channel, _thread_ts, _slack_client), do: :ok

  defp reply_to_slack(channel, thread_ts, reel, slack_client) do
    message = Formatter.format_reply(reel.summary, reel.transcript)
    slack_client.reply_to_thread(channel, thread_ts, message)
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

  defp module(key, default) do
    Application.get_env(:stackoverflow_clone, key, default)
  end
end
