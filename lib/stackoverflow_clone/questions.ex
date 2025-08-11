defmodule StackoverflowClone.Questions do
  @moduledoc """
  The Questions context.
  """

  import Ecto.Query, warn: false
  alias StackoverflowClone.Repo

  alias StackoverflowClone.Questions.Question
  alias StackoverflowClone.Answers.Answer

  @doc """
  Gets a question by stackoverflow_id.
  """
  def get_question_by_stackoverflow_id(stackoverflow_id) do
    Repo.get_by(Question, stackoverflow_id: stackoverflow_id)
  end

  @doc """
  Gets the latest questions ordered by update time (most recent first).

  ## Parameters
  - limit: Number of questions to return (default: 5)

  """
  def get_latest_questions(limit \\ 5) do
    Question
    |> order_by([q], desc: q.updated_at)
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  Creates a question with its answers using bulk update.

  ## Parameters
  - question_attrs: Question attributes map
  - answers: List of answers

  ## Returns
  {:ok, question_with_answers} | {:error, reason}
  """
  def create_question_with_answers(question_attrs, answers) do
    import Ecto.Multi
    # Transform raw API data to formatted data
    formatted_question_attrs = format_question_data(question_attrs)
    formatted_default_answers = format_answers_data(answers)

    # Prepare answers data with both orderings
    Ecto.Multi.new()
    |> insert(:question, Question.changeset(%Question{}, formatted_question_attrs))
    |> run(:answers, fn repo, %{question: question} ->
      # Add question_id to each answer
      answers_with_question_id =
        Enum.map(formatted_default_answers, &Map.put(&1, :question_id, question.id))

      # Bulk insert answers
      {count, _} =
        repo.insert_all(Answer, answers_with_question_id,
          returning: false,
          on_conflict: :nothing
        )

      {:ok, count}
    end)
    |> run(:question_with_answers, fn repo, %{question: question} ->
      question_with_answers = repo.preload(question, :answers)
      {:ok, question_with_answers}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{question_with_answers: question_with_answers}} -> {:ok, question_with_answers}
      {:error, _step, changeset, _changes} -> {:error, changeset}
    end
  end

  # Data transformation helpers
  defp format_question_data(question) do
    %{
      stackoverflow_id: question["question_id"],
      title: question["title"],
      body: question["body"] || ""
    }
  end

  defp format_answers_data(items) do
    Enum.map(items, &format_answer_data/1)
  end

  defp format_answer_data(item) do
    %{
      stackoverflow_id: item["answer_id"],
      body: item["body"],
      score: item["score"] || 0,
      is_accepted: item["is_accepted"] || false,
      llm_score: item["llm_score"] || 0,
      inserted_at: DateTime.utc_now() |> DateTime.truncate(:second),
      updated_at: DateTime.utc_now() |> DateTime.truncate(:second)
    }
  end
end
