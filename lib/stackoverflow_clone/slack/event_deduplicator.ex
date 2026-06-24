defmodule StackoverflowClone.Slack.EventDeduplicator do
  @moduledoc """
  Deduplicates Slack event callbacks by event_id.

  Slack guarantees at-least-once delivery and will retry events that don't
  receive a 200 within 3 seconds. Without deduplication, a slow yt-dlp call
  can cause the same URL to be enqueued multiple times.

  Uses an ETS table owned by this GenServer with a configurable TTL matching
  Slack's 5-minute retry window.
  """

  use GenServer
  require Logger

  @table :slack_event_dedup
  @ttl_seconds 300
  @cleanup_every 50

  # ── Public API ────────────────────────────────────────────────────────────

  def start_link(_opts), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  @spec seen?(String.t()) :: boolean()
  def seen?(event_id) when is_binary(event_id) do
    now = System.system_time(:second)

    case :ets.lookup(@table, event_id) do
      [{^event_id, expires_at}] when expires_at > now ->
        Logger.debug("Duplicate Slack event suppressed event_id=#{event_id}")
        true

      _ ->
        false
    end
  end

  @spec mark_seen(String.t()) :: :ok
  def mark_seen(event_id) when is_binary(event_id) do
    expires_at = System.system_time(:second) + @ttl_seconds
    :ets.insert(@table, {event_id, expires_at})
    maybe_cleanup()
    :ok
  end

  # ── GenServer ─────────────────────────────────────────────────────────────

  @impl true
  def init(_) do
    :ets.new(@table, [:named_table, :public, :set, write_concurrency: true])
    {:ok, 0}
  end

  # ── Cleanup ───────────────────────────────────────────────────────────────

  defp maybe_cleanup do
    if :rand.uniform(@cleanup_every) == 1 do
      now = System.system_time(:second)
      deleted = :ets.select_delete(@table, [{{:_, :"$1"}, [{:<, :"$1", now}], [true]}])
      if deleted > 0, do: Logger.debug("EventDeduplicator pruned #{deleted} expired entries")
    end
  end
end
