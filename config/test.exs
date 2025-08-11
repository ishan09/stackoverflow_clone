import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :stackoverflow_clone, StackoverflowClone.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "stackoverflow_clone_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :stackoverflow_clone, StackoverflowCloneWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "D/6yOoJvACl9ExDg6ZMbniePaAnJ8HPN6bQGclSAKPu8BdH+MFrJoVx10A3VXT7d",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Configure mocks for testing
config :stackoverflow_clone,
  stackoverflow_client: StackoverflowClone.StackOverflowClientMock,
  llm_manager: StackoverflowClone.AI.LLMManagerMock
