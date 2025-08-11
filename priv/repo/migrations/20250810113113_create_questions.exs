defmodule StackoverflowClone.Repo.Migrations.CreateQuestions do
  use Ecto.Migration

  def change do
    create table(:questions) do
      add :stackoverflow_id, :integer, null: false
      add :title, :string, null: false
      add :body, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:questions, [:stackoverflow_id])
  end
end
