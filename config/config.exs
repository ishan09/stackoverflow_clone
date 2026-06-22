import Config

config :stackoverflow_clone,
  ecto_repos: [StackoverflowClone.Repo],
  generators: [timestamp_type: :utc_datetime]

config :stackoverflow_clone, StackoverflowCloneWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: StackoverflowCloneWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: StackoverflowClone.PubSub,
  live_view: [signing_salt: "Pf6N5/S7"]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :oban_job_id, :oban_queue, :oban_worker]

config :phoenix, :json_library, Jason

# Oban background job processing (uses the main Postgres repo)
config :stackoverflow_clone, Oban,
  repo: StackoverflowClone.Repo,
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},
    {Oban.Plugins.Stager, interval: 1_000}
  ],
  queues: [
    default: 10,
    reels: 5
  ]

# Provider defaults — overridden per environment in runtime.exs
config :stackoverflow_clone,
  openai_api_key: System.get_env("OPENAI_API_KEY", ""),
  ollama_base_url: System.get_env("OLLAMA_BASE_URL", "http://localhost:11434"),
  slack_bot_token: System.get_env("SLACK_BOT_TOKEN", ""),
  slack_signing_secret: System.get_env("SLACK_SIGNING_SECRET", ""),
  transcription_provider: :local,
  llm_provider: :ollama,
  llm_models: %{
    ollama: "llama3.2",
    openai: "gpt-4o-mini-2024-07-18"
  },
  transcript_max_length: 500

import_config "#{config_env()}.exs"
