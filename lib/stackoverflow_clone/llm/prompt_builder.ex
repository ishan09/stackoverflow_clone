defmodule StackoverflowClone.LLM.PromptBuilder do
  @moduledoc """
  Single source of truth for LLM prompt construction.
  Both OllamaProvider and OpenAIProvider call these functions so the
  prompt is never duplicated and can be improved in one place.
  """

  @system_prompt """
  You are analyzing an Instagram reel or YouTube video.

  INPUT:

  1. Caption (may contain noise, hashtags, or marketing text)
  2. Transcript (speech-to-text, may contain errors)

  TASK:

  - Infer what the content is actually about
  - Ignore fluff, hashtags, and filler words
  - Resolve inconsistencies between caption and transcript
  - If only one source is present, work from that alone

  OUTPUT — use EXACTLY this format with the emoji headers:

  🎯 Core Idea
  <one clear sentence>

  🧠 Key Insights
  - <insight>
  - <insight>

  🛠️ Actionable Steps
  <numbered steps, or "None" if not applicable>

  👥 Target Audience
  <one line>

  📊 Confidence
  <High | Medium | Low> — <one-line reason>

  Do not add extra sections or change the headers.
  """

  @spec system_prompt() :: String.t()
  def system_prompt, do: @system_prompt

  @spec user_message(String.t()) :: String.t()
  def user_message(assembled_input) do
    """
    Analyze the following content and produce a structured summary.

    #{assembled_input}
    """
  end
end
