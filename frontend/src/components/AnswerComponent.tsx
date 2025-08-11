import { Badge } from "flowbite-react";
import type { Answer } from "./types";

import DOMPurify from 'dompurify';


interface AnswerComponentProps {
    answer: Answer;
    idx: number;
}


export function AnswerComponent({ answer, idx }: AnswerComponentProps) {
    const sanitizedBody = DOMPurify.sanitize(answer.body);

    return (
        <div className="bg-white p-6 rounded-lg border">
            <div className="flex justify-between items-start mb-4">
                <div className="flex gap-2">
                    <Badge color="success">#{idx + 1}</Badge>
                    <Badge color="info">Score: {answer.score}</Badge>
                    {answer.is_accepted && <Badge color="green">✓ Accepted</Badge>}
                    <Badge color="gray">LLM Score: {answer.llm_score}/100</Badge>
                </div>
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
