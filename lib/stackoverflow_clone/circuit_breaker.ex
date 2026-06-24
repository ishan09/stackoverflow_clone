defmodule StackoverflowClone.CircuitBreaker do
  @moduledoc """
  Circuit breaker wrapper around `:fuse`.

  Trips after N failures within a period and stays open for a reset interval.
  This protects the rest of the pipeline when an external service is degraded.

  Circuit configs:
  - :openai   — 5 failures / 30 s → open for 60 s
  - :ollama   — 3 failures / 30 s → open for 30 s
  - :slack    — 5 failures / 30 s → open for 60 s
  - :yt_dlp   — 3 failures / 60 s → open for 120 s
  """

  require Logger

  # {max_failures_in_period_ms, reset_ms}
  @circuits %{
    openai: {5, 30_000, 60_000},
    ollama: {3, 30_000, 30_000},
    slack: {5, 30_000, 60_000},
    yt_dlp: {3, 60_000, 120_000}
  }

  @type circuit :: :openai | :ollama | :slack | :yt_dlp

  @doc """
  Calls `fun.()` through the circuit breaker for `name`.

  - If the circuit is closed: calls fun, melts on `{:error, _}`, returns result.
  - If the circuit is open: returns `{:error, {:circuit_open, name}}` immediately.
  """
  @spec call(circuit(), (-> result)) :: result | {:error, {:circuit_open, circuit()}}
        when result: {:ok, any()} | {:error, any()}
  def call(name, fun) when is_function(fun, 0) do
    ensure_installed(name)

    case :fuse.ask(name, :sync) do
      :ok ->
        result = fun.()

        case result do
          {:error, _} -> :fuse.melt(name)
          _ -> :ok
        end

        result

      :blown ->
        Logger.warning("Circuit open circuit=#{name}")
        {:error, {:circuit_open, name}}

      {:error, :not_found} ->
        install(name)
        call(name, fun)
    end
  end

  @doc "Resets a blown circuit (useful in tests or after manual remediation)."
  @spec reset(circuit()) :: :ok
  def reset(name) do
    :fuse.reset(name)
    :ok
  end

  # ── Setup ─────────────────────────────────────────────────────────────────

  @doc "Install all circuits. Called from Application.start/2."
  def install_all do
    Enum.each(@circuits, fn {name, _} -> install(name) end)
  end

  defp ensure_installed(name) do
    case :fuse.ask(name, :sync) do
      {:error, :not_found} -> install(name)
      _ -> :ok
    end
  end

  defp install(name) do
    {max_r, period_ms, reset_ms} = Map.fetch!(@circuits, name)
    :fuse.install(name, {{:standard, max_r, period_ms}, {:reset, reset_ms}})
  end
end
