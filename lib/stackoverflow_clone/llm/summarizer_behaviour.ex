defmodule StackoverflowClone.LLM.SummarizerBehaviour do
  @doc "Generate a structured summary from a reel transcript."
  @callback summarize(text :: String.t()) :: {:ok, String.t()} | {:error, String.t()}
end
