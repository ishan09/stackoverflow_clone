defmodule StackoverflowClone.Transcription.Provider do
  @moduledoc "Resolves the active transcription provider from config and delegates."

  alias StackoverflowClone.Transcription.{LocalWhisperProvider, OpenAIWhisperProvider}

  @spec transcribe(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def transcribe(audio_path) do
    resolve_provider().transcribe(audio_path)
  end

  defp resolve_provider do
    case Application.get_env(:stackoverflow_clone, :transcription_provider, :local) do
      :openai -> OpenAIWhisperProvider
      _ -> LocalWhisperProvider
    end
  end
end
