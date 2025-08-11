defmodule StackoverflowClone.Repo.Migrations.CreateAnswers do
  use Ecto.Migration

  def change do
    create table(:answers) do
      add :stackoverflow_id, :integer, null: false
      add :body, :text, null: false
      add :score, :integer, default: 0
      add :is_accepted, :boolean, default: false, null: false
      add :llm_score, :integer
      add :question_id, references(:questions, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:answers, [:question_id])
    create index(:answers, [:id])
    create unique_index(:answers, [:stackoverflow_id])
  end
end
