import { useParams } from "react-router-dom";
import { useState, useEffect } from "react";
import { Button, Alert } from "flowbite-react";
import axios from "axios";
import { LoadingSpinner } from "../components/ui/LoadingSpinner";
import { PageContainer } from "../components/ui/PageContainer";
import { useApiState } from "../hooks/useApiCall";
import { AnswerComponent } from "../components/AnswerComponent";
import type { Question, QuestionResponse } from "../components/types";
import { QuestionComponent } from "../components/QuestionComponent";


export function QuestionPage() {
  const { id } = useParams<{ id: string }>();
  const { data: question, loading, error, setData, setLoading, setError } = useApiState<Question>();
  const [order, setOrder] = useState<"stackoverflow" | "llm_score">("stackoverflow");

  useEffect(() => {
    if (!id) return;

    const fetchQuestion = async (questionId: string) => {
      setLoading(true);
      setError(null);

      try {
        const response = await axios.get<QuestionResponse>(`/api/questions/${questionId}/answers`);
        setData(response.data.question);
      } catch (err) {
        console.error('Failed to fetch question:', err);
        setError('Failed to load question. Please try again.');
      } finally {
        setLoading(false);
      }
    };

    fetchQuestion(id);
  }, [id, setLoading, setError, setData]);

  if (loading) {
    return <LoadingSpinner message="Loading question..." />;
  }

  if (error) {
    return (
      <PageContainer>
        <Alert color="failure">{error}</Alert>
      </PageContainer>
    );
  }

  if (!question) {
    return (
      <PageContainer>
        <p className="text-gray-500">Question not found.</p>
      </PageContainer>
    );
  }

  // Sort answers based on selected order
  if (!question.answers || question.answers.length == 0) {
    return (
      <p className="text-gray-500 text-center py-8">No answers available.</p>
    )
  } else {

    const sortedAnswers = [...question.answers].sort((a, b) => {
      if (order === "stackoverflow") {
        return b.score - a.score;
      } else {
        return b.llm_score - a.llm_score;
      }
    });

    return (
      <PageContainer>
        <div className="space-y-6">
          <QuestionComponent question={question} />

          <div className="flex gap-2 justify-center">
            <Button
              color={order === "stackoverflow" ? "blue" : "gray"}
              onClick={() => setOrder("stackoverflow")}
            >
              StackOverflow Order
            </Button>
            <Button
              color={order === "llm_score" ? "blue" : "gray"}
              onClick={() => setOrder("llm_score")}
            >
              LLM Score Order
            </Button>
          </div>

          {/* Answers Section */}
          <div className="space-y-4">
            <h2 className="text-xl font-semibold text-gray-800">
              Answers ({question.answers.length})
            </h2>

            {
              sortedAnswers.map((answer, idx) => (
                <AnswerComponent key={answer.id} answer={answer} idx={idx} />
              ))
            }
          </div>
        </div>
      </PageContainer>
    );
  }
}
