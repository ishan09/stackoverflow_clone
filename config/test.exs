import Config

config :stackoverflow_clone, StackoverflowClone.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "stackoverflow_clone_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# SQLite: use a temp file per test partition so parallel runs don't collide.
# No sandbox pool — ReelsRepo tests rely on explicit setup/cleanup or truncation.
config :stackoverflow_clone, StackoverflowClone.ReelsRepo,
  database: "/tmp/reels_test#{System.get_env("MIX_TEST_PARTITION")}.db"

config :stackoverflow_clone, StackoverflowCloneWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "D/6yOoJvACl9ExDg6ZMbniePaAnJ8HPN6bQGclSAKPu8BdH+MFrJoVx10A3VXT7d",
  server: false

config :logger, level: :warning

config :phoenix, :plug_init_mode, :runtime

# Oban: run jobs inline during tests so no background processes needed
config :stackoverflow_clone, Oban, testing: :inline

config :stackoverflow_clone,
  stackoverflow_client: StackoverflowClone.StackOverflowClientMock,
  llm_manager: StackoverflowClone.AI.LLMManagerMock,
  transcription_provider: :local,
  llm_provider: :ollama,
  slack_bot_token: "test-token",
  slack_signing_secret: "test-secret",
  # Skip HMAC verification in tests so controllers can be called directly
  skip_slack_verification: true,
  # Injectable mock modules for unit tests
  downloader_module: StackoverflowClone.Media.DownloaderMock,
  audio_extractor_module: StackoverflowClone.Media.AudioExtractorMock,
  metadata_extractor_module: StackoverflowClone.Media.MetadataExtractorMock,
  slack_client_module: StackoverflowClone.Slack.ClientMock,
  transcription_module: StackoverflowClone.Transcription.ProviderMock,
  llm_module: StackoverflowClone.LLM.ProviderMock
