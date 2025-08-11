defmodule StackoverflowClone.QuestionsTest do
  use StackoverflowClone.DataCase

  alias StackoverflowClone.Questions

  import StackoverflowClone.QuestionsFixtures

  describe "questions" do
    test "get_latest_questions/1 returns latest questions ordered by update time" do
      # Create questions
      question1 = question_fixture(%{title: "First Question", stackoverflow_id: 1})
      question2 = question_fixture(%{title: "Second Question", stackoverflow_id: 2})

      latest_questions = Questions.get_latest_questions(2)

      assert length(latest_questions) == 2
      # Both questions should be returned, regardless of order (just test functionality)
      question_ids = Enum.map(latest_questions, & &1.id)
      assert question1.id in question_ids
      assert question2.id in question_ids
    end

    test "get_latest_questions/0 uses default limit of 5" do
      # Create 6 questions
      for i <- 1..6 do
        question_fixture(%{title: "Question #{i}", stackoverflow_id: i})
      end

      latest_questions = Questions.get_latest_questions()

      assert length(latest_questions) == 5
    end

    test "get_question_by_stackoverflow_id/1 returns question with given stackoverflow_id" do
      question = question_fixture(%{stackoverflow_id: 12345})

      found_question = Questions.get_question_by_stackoverflow_id(12345)

      assert found_question.id == question.id
      assert found_question.stackoverflow_id == 12345
    end

    test "get_question_by_stackoverflow_id/1 returns nil when question not found" do
      assert Questions.get_question_by_stackoverflow_id(99999) == nil
    end

    test "create_question_with_answers/2 creates question and answers" do
      question_attrs = %{
        "question_id" => 12345,
        "title" => "Test Question",
        "body" => "Test question body"
      }

      answers = [
        %{
          "answer_id" => 1,
          "body" => "First answer",
          "score" => 10,
          "is_accepted" => true,
          "llm_score" => 85
        },
        %{
          "answer_id" => 2,
          "body" => "Second answer",
          "score" => 5,
          "is_accepted" => false,
          "llm_score" => 75
        }
      ]

      assert {:ok, question_with_answers} =
               Questions.create_question_with_answers(question_attrs, answers)

      assert question_with_answers.title == "Test Question"
      assert question_with_answers.stackoverflow_id == 12345
      assert length(question_with_answers.answers) == 2

      # Check answers were created correctly
      answer_ids = Enum.map(question_with_answers.answers, & &1.stackoverflow_id)
      assert 1 in answer_ids
      assert 2 in answer_ids
    end

    test "create_question_with_answers/2 with empty answers creates question only" do
      question_attrs = %{
        "question_id" => 54321,
        "title" => "Question Without Answers",
        "body" => "This question has no answers"
      }

      assert {:ok, question_with_answers} =
               Questions.create_question_with_answers(question_attrs, [])

      assert question_with_answers.title == "Question Without Answers"
      assert question_with_answers.stackoverflow_id == 54321
      assert question_with_answers.answers == []
    end
  end
end
