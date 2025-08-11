
import type {  Question } from "./types";
import { QuestionComponentMinified } from "./QuestionComponent";

interface QuestionsListComponentProps {
    questions: Question[];
}

export function QuestionsListComponent({ questions }: QuestionsListComponentProps) {

  return (
    <div className="space-y-4">
    {questions.map((q) => (
      <QuestionComponentMinified key={q.stackoverflow_id} question={q} />
    ))}
  </div>
  );
}
