defmodule StackoverflowClone.ReelsRepo do
  use Ecto.Repo,
    otp_app: :stackoverflow_clone,
    adapter: Ecto.Adapters.SQLite3
end
