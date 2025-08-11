import { useSearchParams } from "react-router-dom";
import { useEffect } from "react";
import { Alert } from "flowbite-react";
import axios from "axios";
import { LoadingSpinner } from "../components/ui/LoadingSpinner";
import { PageContainer } from "../components/ui/PageContainer";
import { useApiState } from "../hooks/useApiCall";
import type { Question, SearchResponse } from "../components/types";
import { QuestionsListComponent } from "../components/QuestionListComponent";




export function SearchResultsPage() {
  const [params] = useSearchParams();
  const query = params.get("q") || "";
  const { data: results, loading, error, setData, setLoading, setError } = useApiState<Question[]>();

  useEffect(() => {
    if (!query) return;

    const searchQuestions = async (searchQuery: string) => {
      setLoading(true);
      setError(null);

      try {
        const response = await axios.get<SearchResponse>(`/api/search`, {
          params: { q: searchQuery }
        });

        setData(response.data.results || []);
      } catch (err) {
        console.error('Search failed:', err);
        setError('Failed to search questions. Please try again.');
      } finally {
        setLoading(false);
      }
    };

    searchQuestions(query);
  }, [query, setLoading, setError, setData]);

  if (loading) {
    return <LoadingSpinner message="Searching questions..." />;
  }

  return (
    <PageContainer>
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-800">
          Search Results for "{query}"
        </h1>
        <p className="text-gray-600 mt-1">
          {results?.length || 0} question{results?.length !== 1 ? 's' : ''} found
        </p>
      </div>

      {error && (
        <Alert color="failure" className="mb-4">
          {error}
        </Alert>
      )}

      {results?.length === 0 && !loading && !error && (
        <div className="text-center py-8">
          <p className="text-gray-500">No questions found for your search.</p>
          <p className="text-sm text-gray-400 mt-2">Try different keywords or check your spelling.</p>
        </div>
      )}
      
      {results && <QuestionsListComponent questions={results} />}
    </PageContainer>
  );
}
