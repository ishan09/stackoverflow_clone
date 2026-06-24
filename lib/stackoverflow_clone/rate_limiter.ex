defmodule StackoverflowClone.RateLimiter do
  @moduledoc """
  Fixed-window rate limiter backed by ETS. No external dependency.

  Each bucket is keyed by "{scope}:{window_start_ms}" so windows rotate
  automatically. Stale windows are deleted when a new one is created for
  the same scope.

  Limits (all configurable via application env):
  - Slack channel enqueue: 10 URLs / 60 s  — prevents Slack floods
  - OpenAI API:            50 calls / 60 s  — stays within free-tier limits
  - Ollama:                20 calls / 60 s  — protects local GPU/CPU
  """

  use GenServer
  require Logger

  @table :stackoverflow_clone_rate_limiter

  @limits %{
    slack_channel: {10, 60_000},
    openai: {50, 60_000},
    ollama: {20, 60_000}
  }

  # ── Public API ────────────────────────────────────────────────────────────

  def start_link(_opts), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  @spec check(atom(), String.t()) :: :ok | {:error, {:rate_limited, non_neg_integer()}}
  def check(scope, key) when is_atom(scope) do
    {limit, scale_ms} = Map.get(@limits, scope, {100, 60_000})
    bucket = bucket_key(scope, key, scale_ms)
    prev_bucket = bucket_key(scope, key, scale_ms, -1)

    :ets.delete(@table, prev_bucket)
    count = :ets.update_counter(@table, bucket, {2, 1}, {bucket, 0})

    if count <= limit do
      :ok
    else
      retry_after_ms = ms_until_next_window(scale_ms)
      Logger.warning(
        "Rate limited scope=#{scope} key=#{key} count=#{count} limit=#{limit} " <>
          "retry_after_ms=#{retry_after_ms}"
      )
      {:error, {:rate_limited, retry_after_ms}}
    end
  end

  # ── GenServer ─────────────────────────────────────────────────────────────

  @impl true
  def init(_) do
    :ets.new(@table, [:named_table, :public, :set, write_concurrency: true])
    {:ok, nil}
  end

  # ── Helpers ───────────────────────────────────────────────────────────────

  defp bucket_key(scope, key, scale_ms, offset \\ 0) do
    window = div(System.system_time(:millisecond), scale_ms) + offset
    "#{scope}:#{key}:#{window}"
  end

  defp ms_until_next_window(scale_ms) do
    now_ms = System.system_time(:millisecond)
    current_window = div(now_ms, scale_ms)
    next_window_start_ms = (current_window + 1) * scale_ms
    max(1, next_window_start_ms - now_ms)
  end
end
