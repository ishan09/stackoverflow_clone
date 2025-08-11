defmodule StackoverflowClone.AI.Clients.OllamaClient do
  @moduledoc """
  Simplified Ollama client that only handles HTTP requests and response extraction
  """

  @behaviour StackoverflowClone.AI.LLMBehaviour

  @default_timeout 60_000

  @impl true
  def make_llm_request(prompt, opts) do
    model = Keyword.fetch!(opts, :model)
    temperature = Keyword.get(opts, :temperature, 0.1)
    max_tokens = Keyword.get(opts, :max_tokens, 200)

    request_body = %{
      model: model,
      messages: prompt,
      stream: false,
      options: %{
        temperature: temperature,
        num_predict: max_tokens
      },
      format: "json"
    }

    "/api/chat"
    |> make_ollama_http_request(request_body)
    |> validate_and_extract_response()
  end

  defp validate_and_extract_response(response) do
    case response do
      {:ok, response} ->
        case response do
          %{
            "done" => true,
            "message" => %{
              "content" => content
            }
          } ->
            {:ok, Jason.decode!(content)}

          %{
            "done" => false
          } ->
            {:error, "reached the max_tokens"}

          _ ->
            {:error, "Invalid response format"}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp make_ollama_http_request(endpoint, body) do
    base_url = get_base_url()
    url = "#{base_url}#{endpoint}"

    headers = [
      {"Content-Type", "application/json"}
    ]

    case HTTPoison.post(url, Jason.encode!(body), headers,
           timeout: @default_timeout,
           recv_timeout: @default_timeout
         ) do
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

  defp get_base_url, do: Application.get_env(:stackoverflow_clone, :ollama_base_url)
end
