defmodule StackoverflowCloneWeb.QuestionsController do
  use StackoverflowCloneWeb, :controller
  alias StackoverflowClone.Questions

  @doc """
  GET /api/questions/latest
  Returns the latest 5 searched questions
  """
  def latest(conn, _params) do
    questions = Questions.get_latest_questions(5)
    render(conn, :latest, questions: questions)
  end
end
