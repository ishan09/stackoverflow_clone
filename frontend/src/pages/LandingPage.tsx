import { useEffect } from "react";
import { QuestionsListComponent } from "../components/QuestionListComponent";
import { LoadingSpinner } from "../components/ui/LoadingSpinner";
import { PageContainer } from "../components/ui/PageContainer";
import { useApiState } from "../hooks/useApiCall";
import type { Question } from "../components/types";

export function LandingPage() {
  const { data: latestQuestions, loading, error, setData, setLoading, setError } = useApiState<Question[]>();

  useEffect(() => {
    fetchLatestQuestions();
  }, []);

  async function fetchLatestQuestions() {
    setLoading(true);
    setError(null);

    try {
      const response = await fetch('/api/questions/latest');
      if (!response.ok) {
        throw new Error('Failed to fetch latest questions');
      }
      const data = await response.json();
      setData(data.questions);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred');
    } finally {
      setLoading(false);
    }
  }


  if (loading) {
    return <LoadingSpinner message="Loading latest questions..." />;
  }

  if (error) {
    return (
      <div className="flex-1 flex items-center justify-center p-6">
        <div className="text-center">
          <h1 className="text-4xl font-bold text-gray-800 mb-4">
            Having issues? Let's find a solution.
          </h1>
          <p className="text-gray-600 text-lg mb-4">
            Search for programming questions and get AI-powered answer rankings
          </p>
          <p className="text-red-600 text-sm">
            Unable to load recent questions: {error}
          </p>
        </div>
      </div>
    );
  } else {

    return (
      <PageContainer>
        {latestQuestions?.length === 0 ? (
          <div className="text-center">
            <h1 className="text-4xl font-bold text-gray-800 mb-4">
              Having issues? Let's find a solution.
            </h1>
            <p className="text-gray-600 text-lg">
              Search for programming questions and get AI-powered answer rankings
            </p>
          </div>
        ) : (
          <div>
            <div className="mb-6">
              <h1 className="text-2xl font-bold text-gray-800">
                Recent Searches
              </h1>

            </div>
            <QuestionsListComponent questions={latestQuestions ?? []} />
          </div>
        )}
      </PageContainer>
    );
  }
}
