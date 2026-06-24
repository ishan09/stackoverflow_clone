defmodule StackoverflowClone.Slack.Formatter do
  @moduledoc """
  Formats the LLM summary + transcript for a Slack thread reply.

  The LLM is prompted to emit emoji section headers directly, so this module
  only needs to append the optional transcript footer and trim whitespace.
  """

  @spec format_reply(String.t() | nil, String.t() | nil) :: String.t()
  def format_reply(summary, transcript) do
    max_len = Application.get_env(:stackoverflow_clone, :transcript_max_length, 500)

    [
      String.trim(summary || "_No summary available._"),
      transcript_section(transcript, max_len)
    ]
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n\n")
  end

  defp transcript_section(nil, _), do: ""
  defp transcript_section("", _), do: ""

  defp transcript_section(transcript, max_len) do
    trimmed = String.slice(transcript, 0, max_len)
    ellipsis = if String.length(transcript) > max_len, do: "…", else: ""

    """
    📜 *Transcript*
    #{trimmed}#{ellipsis}
    """
    |> String.trim()
  end
end
