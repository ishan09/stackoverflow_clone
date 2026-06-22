defmodule StackoverflowClone.Reels.Reel do
  use Ecto.Schema
  import Ecto.Changeset

  @valid_statuses [:pending, :processing, :processed, :failed]

  schema "reels" do
    field :url, :string
    field :transcript, :string
    field :summary, :string
    field :status, Ecto.Enum, values: @valid_statuses, default: :pending
    field :raw_metadata, :map

    timestamps(type: :utc_datetime)
  end

  def changeset(reel, attrs) do
    reel
    |> cast(attrs, [:url, :transcript, :summary, :status, :raw_metadata])
    |> validate_required([:url])
    |> validate_inclusion(:status, @valid_statuses)
    |> unique_constraint(:url)
  end
end
