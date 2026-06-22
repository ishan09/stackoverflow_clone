defmodule StackoverflowClone.Reels do
  @moduledoc "Context for reel storage and status management."

  import Ecto.Query
  require Logger

  alias StackoverflowClone.ReelsRepo
  alias StackoverflowClone.Reels.Reel

  @spec find_or_create(String.t()) :: {:ok, Reel.t()} | {:error, Ecto.Changeset.t()}
  def find_or_create(url) do
    case ReelsRepo.get_by(Reel, url: url) do
      nil ->
        %Reel{}
        |> Reel.changeset(%{url: url, status: :pending})
        |> ReelsRepo.insert()

      reel ->
        {:ok, reel}
    end
  end

  @spec update_status(Reel.t(), atom()) :: {:ok, Reel.t()} | {:error, Ecto.Changeset.t()}
  def update_status(%Reel{} = reel, status) do
    reel
    |> Reel.changeset(%{status: status})
    |> ReelsRepo.update()
  end

  @spec mark_processed(Reel.t(), String.t(), String.t()) ::
          {:ok, Reel.t()} | {:error, Ecto.Changeset.t()}
  def mark_processed(%Reel{} = reel, transcript, summary) do
    reel
    |> Reel.changeset(%{transcript: transcript, summary: summary, status: :processed})
    |> ReelsRepo.update()
  end

  @spec mark_failed(String.t()) :: :ok
  def mark_failed(url) when is_binary(url) do
    case ReelsRepo.get_by(Reel, url: url) do
      nil ->
        Logger.warning("Attempted to mark unknown reel as failed: #{url}")
        :ok

      reel ->
        reel
        |> Reel.changeset(%{status: :failed})
        |> ReelsRepo.update()

        :ok
    end
  end

  @spec get_by_url(String.t()) :: {:ok, Reel.t()} | {:error, :not_found}
  def get_by_url(url) do
    case ReelsRepo.get_by(Reel, url: url) do
      nil -> {:error, :not_found}
      reel -> {:ok, reel}
    end
  end

  @spec list_reels(Keyword.t()) :: [Reel.t()]
  def list_reels(opts \\ []) do
    query =
      from r in Reel,
        order_by: [desc: r.inserted_at]

    query =
      case Keyword.get(opts, :status) do
        nil -> query
        status -> from r in query, where: r.status == ^status
      end

    limit = Keyword.get(opts, :limit)

    query =
      if limit do
        from r in query, limit: ^limit
      else
        query
      end

    ReelsRepo.all(query)
  end
end
