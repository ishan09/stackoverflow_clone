defmodule StackoverflowClone.ContentAssembler do
  @moduledoc """
  Merges multiple content sources into a single structured input for the LLM.

  Designed for extensibility: sources are `{type, content}` tuples. Adding a new
  input type (OCR, embedded subtitles, comments, etc.) requires only:
    - A new `clean/2` clause for the type
    - A new `section_header/1` clause
    - One extra tuple in the `assemble/1` call-site

  No changes to providers, the worker, or the prompt builder needed.
  """

  @hashtag_pattern ~r/#\w+/u
  @excessive_whitespace ~r/[ \t]{2,}/
  @newline_runs ~r/\n{3,}/

  @type source :: {atom(), String.t() | nil}

  @doc """
  Convenience wrapper used by the worker.
  Returns `{:ok, text}` when at least one source has usable content,
  `{:error, :no_usable_content}` when both are empty/nil.
  """
  @spec build_input(String.t() | nil, String.t() | nil) ::
          {:ok, String.t()} | {:error, :no_usable_content}
  def build_input(caption, transcript) do
    assemble([
      {:caption, caption},
      {:transcript, transcript}
    ])
  end

  @doc """
  Generic assembler. Pass any ordered list of `{type, content}` tuples.
  Skips nil/blank entries and formats each remaining source with a labelled header.
  Future sources: `{:ocr, text}`, `{:comments, text}`, `{:embeddings_context, text}`, …
  """
  @spec assemble([source()]) :: {:ok, String.t()} | {:error, :no_usable_content}
  def assemble(sources) do
    assembled =
      sources
      |> Enum.map(fn {type, content} -> {type, clean(type, content)} end)
      |> Enum.reject(fn {_type, content} -> blank?(content) end)
      |> Enum.map(fn {type, content} -> "#{section_header(type)}\n#{content}" end)
      |> Enum.join("\n\n")

    if assembled == "" do
      {:error, :no_usable_content}
    else
      {:ok, assembled}
    end
  end

  # ── Cleaning per source type ──────────────────────────────────────────────

  defp clean(:caption, nil), do: nil

  defp clean(:caption, text) do
    text
    |> String.replace(@hashtag_pattern, "")
    |> String.replace(@excessive_whitespace, " ")
    |> String.replace(@newline_runs, "\n\n")
    |> String.trim()
    |> then(fn s -> if blank?(s), do: nil, else: s end)
  end

  defp clean(:transcript, nil), do: nil
  defp clean(:transcript, text), do: text |> String.replace(@newline_runs, "\n\n") |> String.trim()

  # Generic fallback for future source types (OCR, comments, etc.)
  defp clean(_type, nil), do: nil
  defp clean(_type, text), do: String.trim(text)

  # ── Section labels ────────────────────────────────────────────────────────

  defp section_header(:caption), do: "[CAPTION]"
  defp section_header(:transcript), do: "[TRANSCRIPT]"
  defp section_header(:ocr), do: "[FRAME TEXT]"
  defp section_header(:comments), do: "[COMMENTS]"

  defp section_header(type) do
    label = type |> to_string() |> String.upcase() |> String.replace("_", " ")
    "[#{label}]"
  end

  # ── Helpers ───────────────────────────────────────────────────────────────

  defp blank?(nil), do: true
  defp blank?(""), do: true
  defp blank?(s) when is_binary(s), do: String.trim(s) == ""
end
