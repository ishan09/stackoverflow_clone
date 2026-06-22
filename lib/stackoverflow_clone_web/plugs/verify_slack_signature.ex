defmodule StackoverflowCloneWeb.Plugs.VerifySlackSignature do
  @moduledoc """
  Verifies the X-Slack-Signature header using HMAC-SHA256.
  Rejects requests with missing, stale, or invalid signatures.

  Set `config :stackoverflow_clone, :skip_slack_verification, true` to bypass
  in test/dev environments.
  """

  import Plug.Conn
  require Logger

  @max_timestamp_age_seconds 300

  def init(opts), do: opts

  def call(conn, _opts) do
    if Application.get_env(:stackoverflow_clone, :skip_slack_verification, false) do
      conn
    else
      verify(conn)
    end
  end

  defp verify(conn) do
    with {:ok, signature} <- fetch_header(conn, "x-slack-signature"),
         {:ok, timestamp} <- fetch_header(conn, "x-slack-request-timestamp"),
         :ok <- check_timestamp_freshness(timestamp),
         {:ok, raw_body} <- fetch_raw_body(conn),
         :ok <- check_hmac(signature, timestamp, raw_body) do
      conn
    else
      {:error, reason} ->
        Logger.warning("Slack signature verification failed: #{reason}")

        conn
        |> send_resp(401, Jason.encode!(%{error: "Unauthorized"}))
        |> halt()
    end
  end

  defp fetch_header(conn, name) do
    case get_req_header(conn, name) do
      [value | _] -> {:ok, value}
      [] -> {:error, "missing #{name}"}
    end
  end

  defp check_timestamp_freshness(timestamp_str) do
    case Integer.parse(timestamp_str) do
      {ts, ""} ->
        age = System.system_time(:second) - ts

        if abs(age) <= @max_timestamp_age_seconds do
          :ok
        else
          {:error, "timestamp too old (#{age}s)"}
        end

      _ ->
        {:error, "invalid timestamp format"}
    end
  end

  defp fetch_raw_body(conn) do
    case conn.assigns[:raw_body] do
      nil -> {:error, "raw body not cached"}
      body -> {:ok, body}
    end
  end

  defp check_hmac(expected, timestamp, raw_body) do
    signing_secret = Application.get_env(:stackoverflow_clone, :slack_signing_secret, "")

    computed =
      "v0=" <>
        Base.encode16(
          :crypto.mac(:hmac, :sha256, signing_secret, "v0:#{timestamp}:#{raw_body}"),
          case: :lower
        )

    if Plug.Crypto.secure_compare(expected, computed) do
      :ok
    else
      {:error, "signature mismatch"}
    end
  end
end
