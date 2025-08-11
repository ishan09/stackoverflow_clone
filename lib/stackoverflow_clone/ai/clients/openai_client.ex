defmodule StackoverflowClone.AI.Clients.OpenAIClient do
  @moduledoc """
  OpenAI client that only handles HTTP requests and response extraction
  """

  @behaviour StackoverflowClone.AI.LLMBehaviour

  @base_url "https://api.openai.com/v1"
  @default_timeout 30_000

  @impl true
  def make_llm_request(prompt, opts) do
    model = Keyword.fetch!(opts, :model)
    temperature = Keyword.get(opts, :temperature, 0.1)
    max_tokens = Keyword.get(opts, :max_tokens, 200)

    request_body = %{
      model: model,
      messages: prompt,
      temperature: temperature,
      max_tokens: max_tokens,
      response_format: %{type: "json_object"}
    }

    "/chat/completions"
    |> make_openai_http_request(request_body)
    |> validate_and_extract_response()
  end

  defp validate_and_extract_response(response) do
    case response do
      {:ok, response} ->
        case response do
          %{
            "choices" => [
              %{
                "finish_reason" => "stop",
                "message" => %{
                  "content" => content
                }
              }
              | _
            ]
          } ->
            {:ok, Jason.decode!(content)}

          %{
            "choices" => [
              %{
                "finish_reason" => "length"
              }
              | _
            ]
          } ->
            {:error, "reached the max_tokens"}

          _ ->
            {:error, "Invalid response format"}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp make_openai_http_request(endpoint, body) do
    api_key = get_api_key()
    url = "#{@base_url}#{endpoint}"

    headers = [
      {"Authorization", "Bearer #{api_key}"},
      {"Content-Type", "application/json"}
    ]

    case HTTPoison.post(url, Jason.encode!(body), headers, timeout: @default_timeout) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, decoded} -> {:ok, decoded}
          {:error, _} -> {:error, "Failed to decode JSON response"}
        end

      {:ok, %HTTPoison.Response{status_code: status, body: error_body}} ->
        {:error, "HTTP #{status}: #{error_body}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "Request failed: #{reason}"}
    end
  end

  defp get_api_key do
    Application.get_env(:stackoverflow_clone, :openai_api_key) ||
      raise "OpenAI API key not found. Set OPENAI_API_KEY environment variable."
  end
end
