defmodule StackoverflowClone.SearchService do
  @moduledoc """
  Service for handling search operations
  """

  alias StackoverflowClone.StackOverflowClient
  alias StackoverflowClone.AI.LLMManager
  alias StackoverflowClone.Questions
  alias StackoverflowClone.Repo

  @stackoverflow_client Application.compile_env(
                          :stackoverflow_clone,
                          :stackoverflow_client,
                          StackOverflowClient
                        )
  @llm_manager Application.compile_env(:stackoverflow_clone, :llm_manager, LLMManager)

  def search_questions(query) do
    @stackoverflow_client.search_questions(query)
  end

  @doc """
  Get question with answers, persisting to database if not already saved

  ## Parameters
  - stackoverflow_id

  ## Returns
  {:ok, question_with_answers} | {:error, reason}
  """
  def get_question_answers_with_both_orders(stackoverflow_id) do
    case Questions.get_question_by_stackoverflow_id(stackoverflow_id) do
      %Questions.Question{} = existing_question ->
        {:ok, Repo.preload(existing_question, :answers)}

      nil ->
        # Question not in database, fetch from API and persist
        fetch_and_persist_question_with_answers(stackoverflow_id)
    end
  end

  defp fetch_and_persist_question_with_answers(stackoverflow_id) do
    with {:ok, question_details} <-
           @stackoverflow_client.get_question_details(stackoverflow_id),
         {:ok, default_answers} <-
           @stackoverflow_client.get_answers(stackoverflow_id),
         {:ok, llm_scored_answers} <- @llm_manager.rerank(question_details, default_answers) do
      case Questions.create_question_with_answers(
             question_details,
             llm_scored_answers
           ) do
        {:ok, question_with_answers} -> {:ok, question_with_answers}
        {:error, reason} -> {:error, "Failed to persist question: #{inspect(reason)}"}
      end
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
