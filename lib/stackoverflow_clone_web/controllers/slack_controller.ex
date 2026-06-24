defmodule StackoverflowCloneWeb.SlackController do
  use StackoverflowCloneWeb, :controller

  require Logger

  alias StackoverflowClone.RateLimiter
  alias StackoverflowClone.Slack.EventDeduplicator
  alias StackoverflowClone.Slack.UrlExtractor
  alias StackoverflowClone.Workers.ReelProcessorWorker

  # Slack Events API URL verification handshake
  def events(conn, %{"type" => "url_verification", "challenge" => challenge}) do
    json(conn, %{challenge: challenge})
  end

  # Incoming event callback
  def events(conn, %{"type" => "event_callback", "event_id" => event_id, "event" => event}) do
    if EventDeduplicator.seen?(event_id) do
      send_resp(conn, 200, "")
    else
      EventDeduplicator.mark_seen(event_id)
      handle_slack_event(event)
      send_resp(conn, 200, "")
    end
  end

  # Fallback for event_callback without event_id (shouldn't happen with Slack but be safe)
  def events(conn, %{"type" => "event_callback", "event" => event}) do
    handle_slack_event(event)
    send_resp(conn, 200, "")
  end

  # Unknown event types — always acknowledge immediately
  def events(conn, _params) do
    send_resp(conn, 200, "")
  end

  defp handle_slack_event(%{"type" => type, "text" => text, "channel" => channel} = event)
       when type in ["message", "app_mention"] do
    unless Map.has_key?(event, "bot_id") do
      case RateLimiter.check(:slack_channel, channel) do
        :ok ->
          thread_ts = Map.get(event, "thread_ts") || Map.get(event, "ts")

          text
          |> UrlExtractor.extract_urls()
          |> Enum.each(fn url ->
            enqueue_reel(url, channel, thread_ts)
          end)

        {:error, :rate_limited} ->
          Logger.warning("Rate limit hit for Slack channel=#{channel}")
      end
    end
  end

  defp handle_slack_event(_event), do: :ok

  defp enqueue_reel(url, channel, thread_ts) do
    %{url: url, channel: channel, thread_ts: thread_ts}
    |> ReelProcessorWorker.new()
    |> Oban.insert()
    |> case do
      {:ok, job} ->
        Logger.info("Enqueued reel job #{job.id} for #{url}")

      {:error, reason} ->
        Logger.error("Failed to enqueue reel job for #{url}: #{inspect(reason)}")
    end
  end
end
