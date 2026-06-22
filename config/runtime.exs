import Config

if System.get_env("PHX_SERVER") do
  config :stackoverflow_clone, StackoverflowCloneWeb.Endpoint, server: true
end

# Resolve provider atoms from environment at runtime
transcription_provider =
  case System.get_env("TRANSCRIPTION_PROVIDER", "local") do
    "openai" -> :openai
    _ -> :local
  end

llm_provider =
  case System.get_env("LLM_PROVIDER", "ollama") do
    "openai" -> :openai
    _ -> :ollama
  end

config :stackoverflow_clone,
  transcription_provider: transcription_provider,
  llm_provider: llm_provider,
  openai_api_key: System.get_env("OPENAI_API_KEY", ""),
  ollama_base_url: System.get_env("OLLAMA_BASE_URL", "http://localhost:11434"),
  slack_bot_token: System.get_env("SLACK_BOT_TOKEN", ""),
  slack_signing_secret: System.get_env("SLACK_SIGNING_SECRET", ""),
  transcript_max_length: String.to_integer(System.get_env("TRANSCRIPT_MAX_LENGTH", "500"))

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise "environment variable DATABASE_URL is missing."

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :stackoverflow_clone, StackoverflowClone.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  config :stackoverflow_clone, StackoverflowClone.ReelsRepo,
    database: System.get_env("REELS_DB_PATH") || raise("REELS_DB_PATH is missing.")

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise "environment variable SECRET_KEY_BASE is missing."

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :stackoverflow_clone, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :stackoverflow_clone, StackoverflowCloneWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base
end
