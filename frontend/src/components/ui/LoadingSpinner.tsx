import { Spinner } from "flowbite-react";

interface LoadingSpinnerProps {
  message: string;
}

export function LoadingSpinner({ message }: LoadingSpinnerProps) {
  return (
    <div className="flex justify-center items-center p-8">
      <div className="text-center">
        <Spinner size="lg" />
        <p className="mt-2 text-gray-600">{message}</p>
      </div>
    </div>
  );
}