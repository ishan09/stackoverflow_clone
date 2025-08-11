defmodule StackoverflowClone.AI.LLMManagerBehaviour do
  @moduledoc """
  Behaviour for LLM Manager
  """

  @callback rerank(map(), list()) :: {:ok, list()} | {:error, String.t()}
end
