defmodule StackoverflowClone.Answers.Answer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "answers" do
    field :stackoverflow_id, :integer
    field :body, :string
    field :score, :integer
    field :llm_score, :integer
    field :is_accepted, :boolean, default: false

    belongs_to :question, StackoverflowClone.Questions.Question

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(answer, attrs) do
    answer
    |> cast(attrs, [
      :stackoverflow_id,
      :body,
      :score,
      :is_accepted,
      :llm_score,
      :question_id
    ])
    |> validate_required([:stackoverflow_id, :body, :question_id])
    |> unique_constraint(:stackoverflow_id)
  end
end
