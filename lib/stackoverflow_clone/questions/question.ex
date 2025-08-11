defmodule StackoverflowClone.Questions.Question do
  use Ecto.Schema
  import Ecto.Changeset

  schema "questions" do
    field :stackoverflow_id, :integer
    field :title, :string
    field :body, :string

    has_many :answers, StackoverflowClone.Answers.Answer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(question, attrs) do
    question
    |> cast(attrs, [:stackoverflow_id, :title, :body])
    |> validate_required([:stackoverflow_id, :title])
    |> unique_constraint(:stackoverflow_id)
  end
end
