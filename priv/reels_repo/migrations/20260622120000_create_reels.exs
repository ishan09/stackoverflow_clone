defmodule StackoverflowClone.ReelsRepo.Migrations.CreateReels do
  use Ecto.Migration

  def change do
    create table(:reels) do
      add :url, :string, null: false
      add :transcript, :text
      add :summary, :text
      add :status, :string, null: false, default: "pending"
      add :raw_metadata, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:reels, [:url])
    create index(:reels, [:status])
  end
end
