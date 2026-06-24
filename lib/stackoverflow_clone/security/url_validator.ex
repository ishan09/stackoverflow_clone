defmodule StackoverflowClone.Security.UrlValidator do
  @moduledoc """
  Validates video URLs before they are passed to external tools (yt-dlp).

  Although System.cmd/3 does not invoke a shell (so shell injection is not
  possible), an unvalidated URL could exploit yt-dlp's own parser or trigger
  unexpected network calls. This module provides defence-in-depth:

  1. Length check — reject suspiciously long URLs
  2. Scheme check — only http/https
  3. Host allowlist — only known video platforms
  4. No null bytes or control characters
  """

  @max_url_length 2_048

  @allowed_hosts ~w(
    instagram.com
    www.instagram.com
    youtube.com
    www.youtube.com
    youtu.be
    m.youtube.com
  )

  @spec validate(String.t()) :: :ok | {:error, String.t()}
  def validate(url) when is_binary(url) do
    with :ok <- check_length(url),
         :ok <- check_safe_bytes(url),
         {:ok, uri} <- parse_uri(url),
         :ok <- check_scheme(uri),
         :ok <- check_host(uri) do
      :ok
    end
  end

  def validate(_), do: {:error, "URL must be a string"}

  # ── Checks ────────────────────────────────────────────────────────────────

  defp check_length(url) when byte_size(url) > @max_url_length,
    do: {:error, "URL exceeds maximum length of #{@max_url_length} bytes"}

  defp check_length(_url), do: :ok

  defp check_safe_bytes(url) do
    if String.match?(url, ~r/[\x00-\x1f\x7f]/u) do
      {:error, "URL contains control characters"}
    else
      :ok
    end
  end

  defp parse_uri(url) do
    case URI.parse(url) do
      %URI{host: nil} -> {:error, "Invalid URL: missing host"}
      %URI{host: ""} -> {:error, "Invalid URL: empty host"}
      uri -> {:ok, uri}
    end
  end

  defp check_scheme(%URI{scheme: s}) when s in ["http", "https"], do: :ok
  defp check_scheme(%URI{scheme: s}), do: {:error, "Scheme '#{s}' not allowed; use http or https"}

  defp check_host(%URI{host: host}) do
    if host in @allowed_hosts do
      :ok
    else
      {:error, "Host '#{host}' is not an allowed video platform"}
    end
  end
end
