defmodule StackoverflowClone.AI.LLMManager do
  @moduledoc """
  Centralized manager for LLM operations with shared prompt generation and response parsing
  """

  @behaviour StackoverflowClone.AI.LLMManagerBehaviour

  require Logger
  alias StackoverflowClone.AI.Clients.{OpenAIClient, OllamaClient}

  @batch_size 10

  @doc """
  Rerank answers based on question relevance using LLM
  """
  def rerank(question_details, answers) do
    answers
    |> Enum.chunk_every(@batch_size)
    |> Enum.map(fn chunked_answers ->
      case do_rerank(question_details, chunked_answers) do
        {:ok, scored_answers} ->
          scored_answers

        {:error, error} ->
          Logger.info("LLM scoring failed: #{error}, using default order.")
          chunked_answers
      end
    end)
    |> List.flatten()
    |> then(fn scored_list -> {:ok, scored_list} end)
  end

  defp do_rerank(question_details, answers, retry_count \\ 0) do
    with {:ok, prompt} <- generate_rerank_prompt(question_details, answers, retry_count),
         {:ok, llm_response_map} <- make_llm_request(prompt, prepare_rerank_opts()),
         {:ok, reranked_answers} <- parse_rerank_response(llm_response_map, answers) do
      {:ok, reranked_answers}
    else
      {:error, :llm_response_structure_not_valid} when retry_count < 2 ->
        do_rerank(question_details, answers, retry_count + 1)

      {:error, :llm_response_structure_not_valid} ->
        {:error, :llm_response_structure_not_valid}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp generate_rerank_prompt(_question_details, [], _), do: {:error, "No answer to rerank"}

  defp generate_rerank_prompt(question_details, answers, retry_count) do
    system_prompt = get_rerank_system_prompt()
    answer_count_for_processing = calculate_size(length(answers), retry_count)

    Logger.info(
      "Creating prompt with #{answer_count_for_processing} answers on #{retry_count} retry"
    )

    question_for_llm = %{
      "title" => question_details["title"],
      "description" => question_details["body"],
      "answers" =>
        answers
        |> Enum.take(answer_count_for_processing)
        |> Enum.map(fn answer ->
          %{"answer_id" => answer["answer_id"], "body" => clean_html_content(answer["body"])}
        end)
    }

    user_prompt = """
    Rerank following Stack Overflow answers by quality and relevance to the question title and description:
    """

    {:ok,
     [
       %{role: "system", content: system_prompt},
       %{role: "user", content: user_prompt},
       %{role: "user", content: Jason.encode!(question_for_llm)}
     ]}
  end

  def calculate_size(length, count) do
    round(length / (1 + count * 0.5))
  end

  defp get_rerank_system_prompt do
    """
      You are an expert developer who excels at evaluating the quality and relevance of Stack Overflow answers. Your task is to score answers based on how well they solve the specific problem described in the question.
      Score higher answers that:

      Directly address the question's core problem
      Provide complete, working solutions
      Include clear explanations of how/why the solution works
      Are technically accurate and follow best practices
      Handle edge cases and provide context

      Score lower answers that:

      Only partially address the question
      Are too vague or lack detail
      Contain outdated or incorrect information
      Don't provide practical implementation

      Scoring Scale: 0-100 points where:

      90-100: Exceptional answers that completely solve the problem with clear explanations and best practices
      80-89: Very good answers that solve the problem well with minor gaps
      70-79: Good answers that address the main problem but may lack some detail or completeness
      60-69: Adequate answers that partially solve the problem
      50-59: Below average answers with significant gaps or issues
      40-49: Poor answers that barely address the problem
      0-39: Very poor answers that are incorrect, irrelevant, or misleading

      Evaluate each answer and return a JSON response with scores. Make sure no provided answers are missing in the response.
      Output format:
      json{
        "rankings": [
          {
            "answer_id": 223,
            "llm_score": 90
          }
        ]
      }
    """
  end

  defp parse_rerank_response(%{"rankings" => rankings} = _response_map, original_answers) do
    answers_rank_map =
      Enum.into(rankings, %{}, fn %{
                                    "answer_id" => answer_id,
                                    "llm_score" => llm_score
                                  } ->
        {answer_id, llm_score}
      end)

    llm_scoreed_answer =
      original_answers
      |> Enum.map(fn %{"answer_id" => answer_id} = answer ->
        Map.put(answer, "llm_score", Map.get(answers_rank_map, answer_id))
      end)

    {:ok, llm_scoreed_answer}
  end

  defp parse_rerank_response(_, _original_answers) do
    {:error, :llm_response_structure_not_valid}
  end

  defp clean_html_content(html_content) do
    html_content
    |> HtmlSanitizeEx.strip_tags()
    |> HtmlEntities.decode()
    |> normalize_whitespace()
  end

  defp normalize_whitespace(text) do
    text
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp make_llm_request(prompt, opts) do
    get_client().make_llm_request(prompt, opts)
  end

  defp prepare_rerank_opts do
    [
      model: get_model(),
      temperature: 0.1,
      max_tokens: 1000
    ]
  end

  defp get_client do
    case Application.get_env(:stackoverflow_clone, :llm_provider, :ollama) do
      :openai -> OpenAIClient
      _ -> OllamaClient
    end
  end

  defp get_model() do
    provider = Application.get_env(:stackoverflow_clone, :llm_provider, :ollama)
    models = Application.get_env(:stackoverflow_clone, :llm_models, %{})

    Map.get(models, provider) ||
      raise "Model not configured for #{provider}"
  end
end
