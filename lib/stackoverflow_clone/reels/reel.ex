defmodule StackoverflowClone.Reels.Reel do
  use Ecto.Schema
  import Ecto.Changeset

  @valid_statuses [:pending, :processing, :processed, :failed]

  @castable_fields [
    :url,
    :caption,
    :transcript,
    :processed_input,
    :summary,
    :status,
    :raw_metadata
  ]

  schema "reels" do
    field :url, :string
    field :caption, :string
    field :transcript, :string
    # The assembled text actually sent to the LLM — stored for audit/debug
    field :processed_input, :string
    field :summary, :string
    field :status, Ecto.Enum, values: @valid_statuses, default: :pending
    field :raw_metadata, :map

    timestamps(type: :utc_datetime)
  end

  def changeset(reel, attrs) do
    reel
    |> cast(attrs, @castable_fields)
    |> validate_required([:url])
    |> validate_inclusion(:status, @valid_statuses)
    |> unique_constraint(:url)
  end
end
