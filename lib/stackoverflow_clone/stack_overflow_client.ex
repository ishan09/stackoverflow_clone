defmodule StackoverflowClone.StackOverflowClient do
  @moduledoc """
  This is a client for making request to StackOverflow
  """

  @behaviour StackoverflowClone.StackOverflowClientBehaviour

  @base_url "https://api.stackexchange.com/2.3"
  @default_timeout 10_000
  @page_size 50

  def search_questions(query) do
    params = build_search_params(query)
    url = "#{@base_url}/search?#{URI.encode_query(params)}"
    do_http_request(url)
  end

  def get_answers(question_id) do
    params = build_answers_params([])
    url = "#{@base_url}/questions/#{question_id}/answers?#{URI.encode_query(params)}"
    do_http_request(url)
  end

  def get_question_details(question_id) do
    params = build_question_details_params()
    url = "#{@base_url}/questions/#{question_id}?#{URI.encode_query(params)}"
    {:ok, [question | _]} = do_http_request(url)
    {:ok, question}
  end

  defp build_search_params(query) do
    [
      {"intitle", query},
      {"site", "stackoverflow"},
      {"order", "desc"},
      {"sort", "relevance"},
      {"filter", "withbody"},
      {"pagesize", @page_size}
    ]
  end

  defp build_answers_params(_opts) do
    [
      {"site", "stackoverflow"},
      {"order", "desc"},
      {"sort", "votes"},
      {"filter", "withbody"},
      {"pagesize", @page_size}
    ]
  end

  defp build_question_details_params do
    [
      {"site", "stackoverflow"},
      {"filter", "withbody"}
    ]
  end

  defp do_http_request(url) do
    case HTTPoison.get(url, [], timeout: @default_timeout, recv_timeout: @default_timeout) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        decode_response(body)

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, "Stack Overflow API returned status #{status_code}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "HTTP request failed: #{reason}"}
    end
  end

  defp decode_response(body) do
    case Jason.decode(body) do
      {:ok, %{"items" => items}} ->
        {:ok, items}

      {:ok, response} ->
        {:error, "Unexpected response format: #{inspect(response)}"}

      {:error, reason} ->
        {:error, "JSON decode failed: #{reason}"}
    end
  end
end
