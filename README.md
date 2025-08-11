# Stack Overflow Clone with AI-Powered Answer Ranking

A full-stack application that replicates Stack Overflow's functionality with intelligent answer ranking using Large Language Models (LLMs). The system fetches real questions and answers from the StackExchange API, stores them locally, and uses AI to score and rerank answers based on quality and relevance.


### Prerequisites
- Docker and Docker Compose installed
- (Optional) Ollama running locally for local LLM support


### Start the Application
```bash
# Start all services (PostgreSQL, Phoenix API, React Frontend)
docker-compose up
```

###  Access the Application
- **Frontend**: http://localhost:3000
- **API**: http://localhost:4000/api


## 🤖 LLM Configuration

The application supports two LLM providers:

### Option 1: Ollama (Local, Free)
1. Install Ollama: https://ollama.ai
2. Pull the model: `ollama pull llama3.2` (can configure different model in `config/config.exs`)
3. Start Ollama: `ollama serve`
4. Configuration is already set for Ollama in `config/config.exs`
5. Set `OLLAMA_BASE_URL`: Ollama service URL (default: `host.docker.internal:11434`)

### Option 2: OpenAI (Cloud, Paid)
1. Get API key from https://platform.openai.com
2. Set in environment: `OPENAI_API_KEY=your_key_here`
3. Update `config/config.exs`:
```elixir
config :stackoverflow_clone,
  llm_provider: :openai,  # Change from :ollama
```

## 📚 API Endpoints

### Search Endpoints
```
GET /api/search?query=javascript          # Search questions
GET /api/questions/:stackoverflow_id      # Get question with AI-ranked answers
```

### Response Format
```json
{
  "query": "javascript promises",
  "results": [
    {
      "stackoverflow_id": 14220321,
      "title": "How do JavaScript closures work?",
      "body": "Question content...",
      "answers": [
        {
          "stackoverflow_id": 14220322,
          "body": "Answer content...",
          "score": 1543,
          "is_accepted": true,
          "llm_score": 95
        }
      ]
    }
  ],
  "total": 1
}
```

### Area of Improvements

Currently, LLM call is synchronous. We can make it asynchronous  by using Oban and through websocket update the LLM score on UI. 
