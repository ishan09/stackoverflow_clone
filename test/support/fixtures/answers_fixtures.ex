defmodule StackoverflowClone.AnswersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `StackoverflowClone.Answers` context.
  """

  alias StackoverflowClone.Repo
  alias StackoverflowClone.Answers.Answer

  @doc """
  Generate an answer.
  """
  def answer_fixture(attrs \\ %{}) do
    question = attrs[:question] || StackoverflowClone.QuestionsFixtures.question_fixture()

    attrs =
      attrs
      |> Enum.into(%{
        body: "some body",
        is_accepted: true,
        llm_score: 42,
        score: 42,
        stackoverflow_id: 42,
        question_id: question.id
      })

    %Answer{}
    |> Answer.changeset(attrs)
    |> Repo.insert!()
  end
end
