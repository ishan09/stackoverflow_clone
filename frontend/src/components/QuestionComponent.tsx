import { Badge } from "flowbite-react";
import DOMPurify from 'dompurify';

import type {  Question } from "./types";
import { useNavigate } from "react-router-dom";

interface QuestionComponentProps {
    question: Question;
}

export function QuestionComponentMinified({ question }: QuestionComponentProps) {
  const navigate = useNavigate();

  return (
    <div
    className="p-6 bg-white border rounded-lg hover:shadow-md cursor-pointer transition-shadow"
    onClick={() => navigate(`/question/${question.stackoverflow_id}`)}
  >
    <h3 className="text-lg font-semibold text-gray-800 hover:text-blue-600">
      {question.title}
    </h3>
    {question.body && (
          <p className="text-gray-600 text-sm mt-1 line-clamp-2">
            {question.body.length > 100 
              ? `${question.body.substring(0, 100)}...` 
              : question.body
            }
          </p>
        )}
    <div className="flex gap-2 mt-3">
      <Badge color="info">View Details</Badge>
    </div>
  </div>
  );
}

export function QuestionComponent({ question }: QuestionComponentProps) {
    const sanitizedBody = DOMPurify.sanitize(question.body);

    return (
        <div className="bg-white p-6 rounded-lg border">
        <h1 className="text-2xl font-bold text-gray-800 mb-4">{question.title}</h1>
        
        <div className="flex gap-2 mb-4">
          <Badge color="gray">SO ID: {question.stackoverflow_id}</Badge>
        </div>
        
        <div className="w-full overflow-x-auto">
                <div
                    className="prose prose-sm max-w-none text-gray-700 
                            prose-pre:overflow-x-auto 
                            prose-pre:whitespace-pre-wrap 
                            prose-pre:break-words 
                            prose-pre:max-w-full
                            prose-pre:bg-gray-50 
                            prose-pre:p-4 
                            prose-pre:rounded 
                            prose-pre:border"
                    dangerouslySetInnerHTML={{ __html: sanitizedBody }}
                />
            </div>

      </div>
    );
}
