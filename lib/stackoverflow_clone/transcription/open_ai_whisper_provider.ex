defmodule StackoverflowClone.Transcription.OpenAIWhisperProvider do
  @moduledoc "Transcribes audio using the OpenAI Whisper API."

  @behaviour StackoverflowClone.Transcription.Behaviour

  require Logger

  alias StackoverflowClone.CircuitBreaker
  alias StackoverflowClone.RateLimiter

  @whisper_url "https://api.openai.com/v1/audio/transcriptions"
  @timeout_ms 120_000

  @impl true
  def transcribe(audio_path) do
    api_key = Application.get_env(:stackoverflow_clone, :openai_api_key, "")

    if api_key == "" do
      {:error, "OPENAI_API_KEY not configured"}
    else
      with :ok <- RateLimiter.check(:openai, "global") do
        CircuitBreaker.call(:openai, fn -> do_transcribe(audio_path, api_key) end)
      end
    end
  end

  defp do_transcribe(audio_path, api_key) do
    Logger.info("Sending #{audio_path} to OpenAI Whisper")

    form = {
      :multipart,
      [
        {:file, audio_path,
         {"form-data", [{"name", "file"}, {"filename", Path.basename(audio_path)}]},
         [{"Content-Type", "audio/mpeg"}]},
        {"model", "whisper-1"}
      ]
    }

    headers = [{"Authorization", "Bearer #{api_key}"}]

    case HTTPoison.post(@whisper_url, form, headers,
           timeout: @timeout_ms,
           recv_timeout: @timeout_ms
         ) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"text" => text}} -> {:ok, String.trim(text)}
          _ -> {:error, "Unexpected Whisper response format"}
        end

      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        Logger.error("Whisper API #{status}: #{body}")
        {:error, "Whisper API error #{status}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "#{reason}"}
    end
  end
end
