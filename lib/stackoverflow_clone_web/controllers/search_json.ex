defmodule StackoverflowCloneWeb.SearchJSON do
  alias StackoverflowCloneWeb.QuestionJSON

  @doc """
  Renders search results.
  """
  def search(%{query: query, results: results}) do
    %{
      query: query,
      results: Enum.map(results, &search_result_data(&1)),
      total: length(results)
    }
  end

  @doc """
  Renders a single question with answers.
  """
  def question(%{question: question}) do
    %{
      question: QuestionJSON.data(question)
    }
  end

  defp search_result_data(item) do
    %{
      stackoverflow_id: item["question_id"],
      title: HtmlEntities.decode(item["title"]),
      body: HtmlSanitizeEx.strip_tags(item["body"])
    }
  end
end
