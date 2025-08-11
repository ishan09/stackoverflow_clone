
export interface Answer {
  id: number;
  stackoverflow_id: number;
  body: string;
  score: number;
  is_accepted: boolean;
  llm_score: number;
}

export interface Question {
  id?: number;
  stackoverflow_id: number;
  title: string;
  body: string;
  answers?: Answer[];
}

export interface QuestionResponse {
  question: Question;
}

export interface SearchResponse {
  query: string;
  results: Question[];
  total: number;
}
