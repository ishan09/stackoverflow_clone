defmodule StackoverflowClone.ReelsRepo.Migrations.AddCaptionAndProcessedInput do
  use Ecto.Migration

  def change do
    alter table(:reels) do
      add :caption, :text
      add :processed_input, :text
    end
  end
end
