defmodule StackoverflowClone.SearchServiceTest do
  use StackoverflowClone.DataCase

  alias StackoverflowClone.SearchService
  alias StackoverflowClone.Questions

  import Mox

  setup :verify_on_exit!

  describe "search_questions/1" do
    test "delegates to configured client" do
      expect(StackoverflowClone.StackOverflowClientMock, :search_questions, fn "elixir" ->
        {:ok,
         [
           %{
             "question_id" => 12345,
             "title" => "How to use Elixir?",
             "body" => "I want to learn Elixir programming"
           }
         ]}
      end)

      assert {:ok, results} = SearchService.search_questions("elixir")
      assert length(results) == 1
      assert List.first(results)["question_id"] == 12345
    end

    test "handles client errors" do
      expect(StackoverflowClone.StackOverflowClientMock, :search_questions, fn "error" ->
        {:error, "API error"}
      end)

      assert {:error, "API error"} = SearchService.search_questions("error")
    end
  end

  describe "get_question_answers_with_both_orders/1" do
    test "returns cached question when exists in database" do
      # Create question with answers using the Questions context
      question_attrs = %{
        "question_id" => 12345,
        "title" => "Cached Question",
        "body" => "This question is cached"
      }

      answers = [
        %{
          "answer_id" => 1,
          "body" => "Answer 1",
          "score" => 5,
          "is_accepted" => true,
          "llm_score" => 90
        },
        %{
          "answer_id" => 2,
          "body" => "Answer 2",
          "score" => 2,
          "is_accepted" => false,
          "llm_score" => 75
        }
      ]

      {:ok, _question} = Questions.create_question_with_answers(question_attrs, answers)

      # Should return cached question without calling external APIs
      assert {:ok, result} = SearchService.get_question_answers_with_both_orders(12345)
      assert result.stackoverflow_id == 12345
      assert result.title == "Cached Question"
      assert length(result.answers) == 2
    end

    test "fetches and persists new question when not in database" do
      stackoverflow_id = 67890

      # Mock question details response
      expect(
        StackoverflowClone.StackOverflowClientMock,
        :get_question_details,
        fn ^stackoverflow_id ->
          {:ok,
           %{
             "question_id" => stackoverflow_id,
             "title" => "New Question",
             "body" => "This is a new question"
           }}
        end
      )

      # Mock answers response
      expect(StackoverflowClone.StackOverflowClientMock, :get_answers, fn ^stackoverflow_id ->
        {:ok,
         [
           %{
             "answer_id" => 101,
             "body" => "New answer 1",
             "score" => 8,
             "is_accepted" => true
           },
           %{
             "answer_id" => 102,
             "body" => "New answer 2",
             "score" => 3,
             "is_accepted" => false
           }
         ]}
      end)

      # Mock LLM reranking
      expect(StackoverflowClone.AI.LLMManagerMock, :rerank, fn _question, _answers ->
        {:ok,
         [
           %{
             "answer_id" => 101,
             "body" => "New answer 1",
             "score" => 8,
             "is_accepted" => true,
             "llm_score" => 95
           },
           %{
             "answer_id" => 102,
             "body" => "New answer 2",
             "score" => 3,
             "is_accepted" => false,
             "llm_score" => 80
           }
         ]}
      end)

      assert {:ok, result} = SearchService.get_question_answers_with_both_orders(stackoverflow_id)
      assert result.stackoverflow_id == stackoverflow_id
      assert result.title == "New Question"
      assert length(result.answers) == 2

      # Verify question was persisted to database
      cached_question = Questions.get_question_by_stackoverflow_id(stackoverflow_id)
      assert cached_question != nil
      assert cached_question.title == "New Question"
    end

    test "handles question not found error" do
      stackoverflow_id = 99999

      expect(
        StackoverflowClone.StackOverflowClientMock,
        :get_question_details,
        fn ^stackoverflow_id ->
          {:error, "Question not found"}
        end
      )

      assert {:error, "Question not found"} =
               SearchService.get_question_answers_with_both_orders(stackoverflow_id)
    end

    test "handles answers fetch error" do
      stackoverflow_id = 55555

      expect(
        StackoverflowClone.StackOverflowClientMock,
        :get_question_details,
        fn ^stackoverflow_id ->
          {:ok,
           %{
             "question_id" => stackoverflow_id,
             "title" => "Question with no answers API",
             "body" => "This question has API error for answers"
           }}
        end
      )

      expect(StackoverflowClone.StackOverflowClientMock, :get_answers, fn ^stackoverflow_id ->
        {:error, "Answers fetch failed"}
      end)

      assert {:error, "Answers fetch failed"} =
               SearchService.get_question_answers_with_both_orders(stackoverflow_id)
    end
  end
end
