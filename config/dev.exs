import Config

config :stackoverflow_clone, StackoverflowClone.Repo,
  username: System.get_env("POSTGRES_USER") || "postgres",
  password: System.get_env("POSTGRES_PASSWORD") || "postgres",
  hostname: System.get_env("POSTGRES_HOST") || "localhost",
  database: System.get_env("POSTGRES_DB") || "stackoverflow_clone_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :stackoverflow_clone, StackoverflowClone.ReelsRepo,
  database: Path.expand("../priv/reels_dev.db", __DIR__)

config :stackoverflow_clone, StackoverflowCloneWeb.Endpoint,
  http: [
    ip: if(System.get_env("PHX_IP") == "0.0.0.0", do: {0, 0, 0, 0}, else: {127, 0, 0, 1}),
    port: 4000
  ],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "T2QjpKl89+XgwkpFvfe+B6lTt17s3oN4vFYtx+ylABYxT5j5rYd0medHLnPaJxon",
  watchers: []

config :stackoverflow_clone, dev_routes: true

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime

config :mix_test_watch, clear: true
