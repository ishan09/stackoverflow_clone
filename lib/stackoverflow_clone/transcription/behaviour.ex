defmodule StackoverflowClone.Transcription.Behaviour do
  @doc "Transcribe an audio file and return the plain-text transcript."
  @callback transcribe(audio_path :: String.t()) :: {:ok, String.t()} | {:error, String.t()}
end
