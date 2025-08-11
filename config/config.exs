# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :stackoverflow_clone,
  ecto_repos: [StackoverflowClone.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :stackoverflow_clone, StackoverflowCloneWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: StackoverflowCloneWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: StackoverflowClone.PubSub,
  live_view: [signing_salt: "Pf6N5/S7"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :stackoverflow_clone,
  openai_api_key: System.get_env("OPENAI_API_KEY", ""),
  ollama_base_url: System.get_env("OLLAMA_BASE_URL", "http://localhost:11434"),
  llm_provider: :ollama,
  # llm_provider: :openai,
  llm_models: %{
    ollama: "llama3.2",
    openai: "gpt-4o-mini-2024-07-18"
  }

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
