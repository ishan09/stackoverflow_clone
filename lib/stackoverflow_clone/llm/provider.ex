defmodule StackoverflowClone.LLM.Provider do
  @moduledoc "Resolves the active LLM summarizer from config and delegates."

  alias StackoverflowClone.LLM.{OllamaProvider, OpenAIProvider}

  @spec summarize(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def summarize(text) do
    resolve_provider().summarize(text)
  end

  defp resolve_provider do
    # Allow test injection via :llm_module; fall back to runtime provider config
    case Application.get_env(:stackoverflow_clone, :llm_module) do
      nil ->
        case Application.get_env(:stackoverflow_clone, :llm_provider, :ollama) do
          :openai -> OpenAIProvider
          _ -> OllamaProvider
        end

      mod ->
        mod
    end
  end
end
