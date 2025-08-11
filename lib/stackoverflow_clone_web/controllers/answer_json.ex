defmodule StackoverflowCloneWeb.AnswerJSON do
  @doc """
  Renders a single answer.
  """
  def data(%StackoverflowClone.Answers.Answer{} = answer) do
    %{
      id: answer.id,
      stackoverflow_id: answer.stackoverflow_id,
      body: HtmlEntities.decode(answer.body),
      score: answer.score,
      is_accepted: answer.is_accepted,
      llm_score: answer.llm_score
    }
  end
end
