defmodule StackoverflowClone.AI.LLMBehaviour do
  @moduledoc """
  LLM client behaviour - only handles HTTP requests and response extraction
  """

  @doc """
  Make a request to the LLM with the given prompt and options
  """
  @callback make_llm_request(prompt :: list(map()), opts :: Keyword.t()) ::
              {:ok, String.t()} | {:error, String.t()}
end
