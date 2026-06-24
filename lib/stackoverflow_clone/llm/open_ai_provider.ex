defmodule StackoverflowClone.LLM.OpenAIProvider do
  @moduledoc "Summarizes content using the OpenAI Chat Completions API."

  @behaviour StackoverflowClone.LLM.SummarizerBehaviour

  require Logger

  alias StackoverflowClone.CircuitBreaker
  alias StackoverflowClone.RateLimiter
  alias StackoverflowClone.LLM.PromptBuilder

  @base_url "https://api.openai.com/v1"
  @timeout_ms 60_000

  @impl true
  def summarize(assembled_input) do
    api_key = Application.get_env(:stackoverflow_clone, :openai_api_key, "")

    if api_key == "" do
      {:error, "OPENAI_API_KEY not configured"}
    else
      with :ok <- RateLimiter.check(:openai, "global") do
        CircuitBreaker.call(:openai, fn -> do_summarize(assembled_input, api_key) end)
      end
    end
  end

  defp do_summarize(assembled_input, api_key) do
    model = get_model()

    body = %{
      model: model,
      messages: [
        %{role: "system", content: PromptBuilder.system_prompt()},
        %{role: "user", content: PromptBuilder.user_message(assembled_input)}
      ],
      temperature: 0.3,
      max_tokens: 1000
    }

    headers = [
      {"Authorization", "Bearer #{api_key}"},
      {"Content-Type", "application/json"}
    ]

    Logger.info("Summarizing via OpenAI model=#{model}")

    case HTTPoison.post(
           "#{@base_url}/chat/completions",
           Jason.encode!(body),
           headers,
           timeout: @timeout_ms,
           recv_timeout: @timeout_ms
         ) do
      {:ok, %HTTPoison.Response{status_code: 200, body: resp_body}} ->
        case Jason.decode(resp_body) do
          {:ok, %{"choices" => [%{"message" => %{"content" => content}} | _]}} ->
            {:ok, String.trim(content)}

          _ ->
            {:error, "Unexpected OpenAI response format"}
        end

      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        Logger.error("OpenAI #{status}: #{body}")
        {:error, "OpenAI error #{status}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "#{reason}"}
    end
  end

  defp get_model do
    models = Application.get_env(:stackoverflow_clone, :llm_models, %{})
    Map.get(models, :openai, "gpt-4o-mini-2024-07-18")
  end
end
