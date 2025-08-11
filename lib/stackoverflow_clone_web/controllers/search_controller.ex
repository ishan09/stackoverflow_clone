defmodule StackoverflowCloneWeb.SearchController do
  use StackoverflowCloneWeb, :controller

  alias StackoverflowClone.SearchService

  def search(conn, %{"q" => query}) when is_binary(query) and query != "" do
    with {:ok, results} <- SearchService.search_questions(query) do
      render(conn, :search, query: query, results: results)
    else
      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{
          error: "Search failed: #{reason}",
          query: query,
          results: [],
          total: 0
        })
    end
  end

  def search(conn, _params) do
    render(conn, :search, query: "", results: [])
  end

  def answers(conn, %{"question_id" => question_id}) do
    with {:ok, question_with_answers} <-
           SearchService.get_question_answers_with_both_orders(question_id) do
      render(conn, :question, question: question_with_answers)
    end
  end
end
