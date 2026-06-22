defmodule StackoverflowClone.LLM.OllamaProvider do
  @moduledoc "Summarizes content using a locally running Ollama instance."

  @behaviour StackoverflowClone.LLM.SummarizerBehaviour

  require Logger

  alias StackoverflowClone.LLM.PromptBuilder

  @timeout_ms 120_000

  @impl true
  def summarize(assembled_input) do
    base_url = Application.get_env(:stackoverflow_clone, :ollama_base_url, "http://localhost:11434")
    model = get_model()

    body = %{
      model: model,
      system: PromptBuilder.system_prompt(),
      prompt: PromptBuilder.user_message(assembled_input),
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
