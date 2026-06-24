defmodule StackoverflowClone.Slack.Client do
  @moduledoc "Thin wrapper around the Slack Web API."

  @callback reply_to_thread(channel :: String.t(), thread_ts :: String.t(), text :: String.t()) ::
              :ok | {:error, String.t()}

  require Logger

  alias StackoverflowClone.CircuitBreaker

  @api_base "https://slack.com/api"
  @timeout_ms 15_000

  @spec reply_to_thread(String.t(), String.t(), String.t()) :: :ok | {:error, String.t()}
  def reply_to_thread(channel, thread_ts, text) do
    CircuitBreaker.call(:slack, fn -> do_reply(channel, thread_ts, text) end)
  end

  defp do_reply(channel, thread_ts, text) do
    body = %{channel: channel, thread_ts: thread_ts, text: text}

    case post("chat.postMessage", body) do
      {:ok, %{"ok" => true}} ->
        :ok

      {:ok, %{"ok" => false, "error" => reason}} ->
        Logger.error("Slack API error: #{reason}")
        {:error, reason}

      {:error, reason} ->
        Logger.error("Slack request failed: #{reason}")
        {:error, reason}
    end
  end

  defp post(method, body) do
    token = Application.get_env(:stackoverflow_clone, :slack_bot_token, "")

    headers = [
      {"Authorization", "Bearer #{token}"},
      {"Content-Type", "application/json"}
    ]

    url = "#{@api_base}/#{method}"

    case HTTPoison.post(url, Jason.encode!(body), headers,
           timeout: @timeout_ms,
           recv_timeout: @timeout_ms
         ) do
      {:ok, %HTTPoison.Response{status_code: 200, body: resp_body}} ->
        Jason.decode(resp_body)

      {:ok, %HTTPoison.Response{status_code: status}} ->
        {:error, "HTTP #{status}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "#{reason}"}
    end
  end
end
