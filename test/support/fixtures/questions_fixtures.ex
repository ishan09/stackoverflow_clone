defmodule StackoverflowClone.QuestionsFixtures do
  alias StackoverflowClone.Repo
  alias StackoverflowClone.Questions.Question

  @doc """
  Generate a question.
  """
  def question_fixture(attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{
        body: "some body",
        stackoverflow_id: 42,
        title: "some title"
      })

    %Question{}
    |> Question.changeset(attrs)
    |> Repo.insert!()
  end
end
