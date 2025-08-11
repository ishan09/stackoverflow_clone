import { useState } from 'react';

export function useApiState<T>() {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  return {
    data,
    loading,
    error,
    setData,
    setLoading,
    setError
  };
}