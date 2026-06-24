defmodule StackoverflowClone.Transcription.LocalWhisperProvider do
  @moduledoc "Transcribes audio using a locally installed whisper CLI."

  @behaviour StackoverflowClone.Transcription.Behaviour

  require Logger

  @impl true
  def transcribe(audio_path) do
    output_dir = Path.dirname(audio_path)
    txt_path = Path.rootname(audio_path) <> ".txt"

    Logger.info("Running local whisper on #{audio_path}")

    args = [audio_path, "--output_dir", output_dir, "--output_format", "txt"]

    case System.cmd("whisper", args, stderr_to_stdout: true) do
      {_output, 0} ->
        read_and_clean(txt_path)

      {output, exit_code} ->
        Logger.error("whisper exited #{exit_code}: #{output}")
        {:error, "Transcription failed (exit #{exit_code})"}
    end
  end

  defp read_and_clean(txt_path) do
    case File.read(txt_path) do
      {:ok, content} ->
        File.rm(txt_path)
        {:ok, String.trim(content)}

      {:error, reason} ->
        {:error, "Could not read whisper output: #{reason}"}
    end
  end
end
