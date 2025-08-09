defmodule StackoverflowClone.Repo do
  use Ecto.Repo,
    otp_app: :stackoverflow_clone,
    adapter: Ecto.Adapters.Postgres
end
