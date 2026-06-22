defmodule StackoverflowClone.LLM.OpenAIProvider do
  @moduledoc "Summarizes reel transcripts using the OpenAI Chat Completions API."

  @behaviour StackoverflowClone.LLM.SummarizerBehaviour

  require Logger

  @base_url "https://api.openai.com/v1"
  @timeout_ms 60_000

  @system_prompt "You are a concise content summarizer for social media videos."

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
    api_key = Application.get_env(:stackoverflow_clone, :openai_api_key, "")

    if api_key == "" do
      {:error, "OPENAI_API_KEY not configured"}
    else
      do_summarize(text, api_key)
    end
  end

  defp do_summarize(text, api_key) do
    model = get_model()

    body = %{
      model: model,
      messages: [
        %{role: "system", content: @system_prompt},
        %{role: "user", content: @user_prefix <> text}
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
