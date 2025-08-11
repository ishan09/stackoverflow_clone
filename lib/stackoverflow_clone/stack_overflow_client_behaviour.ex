defmodule StackoverflowClone.StackOverflowClientBehaviour do
  @moduledoc """
  Behaviour for Stack Overflow API client
  """

  @callback search_questions(String.t()) :: {:ok, list()} | {:error, String.t()}
  @callback get_question_details(integer()) :: {:ok, map()} | {:error, String.t()}
  @callback get_answers(integer()) :: {:ok, list()} | {:error, String.t()}
end
