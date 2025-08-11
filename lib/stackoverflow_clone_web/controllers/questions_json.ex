defmodule StackoverflowCloneWeb.QuestionsJSON do
  @moduledoc """
  Renders questions data as JSON.
  """

  @doc """
  render a list of latest questions.
  """
  def latest(%{questions: questions}) do
    %{questions: for(question <- questions, do: data(question))}
  end

  defp data(%StackoverflowClone.Questions.Question{} = question) do
    %{
      id: question.id,
      stackoverflow_id: question.stackoverflow_id,
      title: HtmlEntities.decode(question.title),
      body: HtmlSanitizeEx.strip_tags(question.body),
      inserted_at: question.inserted_at
    }
  end
end
