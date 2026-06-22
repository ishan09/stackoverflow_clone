defmodule StackoverflowClone.Application do
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      StackoverflowCloneWeb.Telemetry,
      StackoverflowClone.Repo,
      StackoverflowClone.ReelsRepo,
      StackoverflowClone.RateLimiter,
      StackoverflowClone.Slack.EventDeduplicator,
      {Oban, Application.fetch_env!(:stackoverflow_clone, Oban)},
      StackoverflowCloneWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: StackoverflowClone.Supervisor]
    {:ok, sup} = Supervisor.start_link(children, opts)

    StackoverflowClone.CircuitBreaker.install_all()
    run_reels_migrations()

    {:ok, sup}
  end

  @impl true
  def config_change(changed, _new, removed) do
    StackoverflowCloneWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp run_reels_migrations do
    migrations_path =
      :code.priv_dir(:stackoverflow_clone)
      |> to_string()
      |> Path.join("reels_repo/migrations")

    case Ecto.Migrator.run(StackoverflowClone.ReelsRepo, migrations_path, :up, all: true) do
      [] ->
        :ok

      migrated ->
        Logger.info("ReelsRepo: migrated #{length(migrated)} migration(s)")
    end
  end
end
