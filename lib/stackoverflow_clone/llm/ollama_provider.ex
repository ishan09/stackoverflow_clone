defmodule StackoverflowClone.LLM.OllamaProvider do
  @moduledoc "Summarizes reel transcripts using a locally running Ollama instance."

  @behaviour StackoverflowClone.LLM.SummarizerBehaviour

  require Logger

  @timeout_ms 120_000

  @system_prompt """
  You are a concise content summarizer. When given a transcript, return a plain-text summary
  with exactly three sections separated by blank lines:
  1. What this is about (1-2 sentences)
  2. Key insights (bullet points starting with -)
  3. Who it is useful for (1 sentence)
  Do not add headers or extra formatting.
  """

  @user_prefix """
  Summarize this Instagram reel transcript.

  Return:
  1. What is this about (1-2 lines)
  2. Key insights (bullet points)
  3. Who is it useful for

  Transcript:
  """

  @impl true
  def summarize(text) do
    base_url = Application.get_env(:stackoverflow_clone, :ollama_base_url, "http://localhost:11434")
    model = get_model()

    body = %{
      model: model,
      system: @system_prompt,
      prompt: @user_prefix <> text,
      stream: false,
      options: %{temperature: 0.3}
    }

    Logger.info("Summarizing via Ollama model=#{model}")

    case HTTPoison.post(
           "#{base_url}/api/generate",
           Jason.encode!(body),
           [{"Content-Type", "application/json"}],
           timeout: @timeout_ms,
           recv_timeout: @timeout_ms
         ) do
      {:ok, %HTTPoison.Response{status_code: 200, body: resp_body}} ->
        case Jason.decode(resp_body) do
          {:ok, %{"response" => response}} -> {:ok, String.trim(response)}
          _ -> {:error, "Unexpected Ollama response format"}
        end

      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        Logger.error("Ollama #{status}: #{body}")
        {:error, "Ollama error #{status}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "#{reason}"}
    end
  end

  defp get_model do
    models = Application.get_env(:stackoverflow_clone, :llm_models, %{})
    Map.get(models, :ollama, "llama3.2")
  end
end
