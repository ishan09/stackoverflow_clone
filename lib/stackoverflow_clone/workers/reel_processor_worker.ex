defmodule StackoverflowClone.Workers.ReelProcessorWorker do
  @moduledoc """
  Oban worker that orchestrates the full reel processing pipeline:
  download → audio extraction → transcription → summarization → store → Slack reply.
  """

  use Oban.Worker,
    queue: :reels,
    max_attempts: 3,
    unique: [period: 3600, fields: [:args]]

  require Logger

  alias StackoverflowClone.Reels
  alias StackoverflowClone.Media.Downloader
  alias StackoverflowClone.Media.AudioExtractor
  alias StackoverflowClone.Transcription.Provider, as: TranscriptionProvider
  alias StackoverflowClone.LLM.Provider, as: LLMProvider
  alias StackoverflowClone.Slack.Client, as: SlackClient

  @impl Oban.Worker
  def perform(%Oban.Job{
        id: job_id,
        args: %{"url" => url, "channel" => channel, "thread_ts" => thread_ts}
      }) do
    Logger.metadata(oban_job_id: job_id)
    Logger.info("Processing reel: #{url}")

    with {:ok, reel} <- Reels.find_or_create(url),
         :ok <- skip_if_processed(reel, channel, thread_ts),
         {:ok, _} <- Reels.update_status(reel, :processing),
         {:ok, video_path} <- Downloader.download(url),
         {:ok, audio_path} <- AudioExtractor.extract(video_path),
         {:ok, transcript} <- TranscriptionProvider.transcribe(audio_path),
         {:ok, summary} <- LLMProvider.summarize(transcript),
         {:ok, reel} <- Reels.mark_processed(reel, transcript, summary),
         :ok <- reply_to_slack(channel, thread_ts, reel) do
      cleanup([video_path, audio_path])
      Logger.info("Reel processed successfully: #{url}")
      :ok
    else
      {:skip, :already_processed} ->
        :ok

      {:error, reason} ->
        Reels.mark_failed(url)
        Logger.error("Reel processing failed for #{url}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp skip_if_processed(%{status: :processed} = reel, channel, thread_ts) do
    Logger.info("Reel already processed, replying with cached result: #{reel.url}")
    reply_to_slack(channel, thread_ts, reel)
    {:skip, :already_processed}
  end

  defp skip_if_processed(_reel, _channel, _thread_ts), do: :ok

  defp reply_to_slack(channel, thread_ts, reel) do
    message = format_slack_message(reel.summary, reel.transcript)
    SlackClient.reply_to_thread(channel, thread_ts, message)
  end

  defp format_slack_message(summary, transcript) do
    max_len = Application.get_env(:stackoverflow_clone, :transcript_max_length, 500)
    transcript_text = transcript || ""
    trimmed = String.slice(transcript_text, 0, max_len)
    ellipsis = if String.length(transcript_text) > max_len, do: "...", else: ""

    """
    🎯 *Summary*

    #{summary}

    📜 *Transcript*
    #{trimmed}#{ellipsis}
    """
  end

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
