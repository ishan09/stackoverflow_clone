defmodule StackoverflowCloneWeb.QuestionJSON do
  alias StackoverflowCloneWeb.AnswerJSON

  @doc """
  Renders a single question with its answers.
  """
  def data(%StackoverflowClone.Questions.Question{} = question) do
    %{
      id: question.id,
      stackoverflow_id: question.stackoverflow_id,
      title: HtmlEntities.decode(question.title),
      body: HtmlEntities.decode(question.body || ""),
      answers: Enum.map(question.answers, &AnswerJSON.data/1)
    }
  end
end
