defmodule Hamstone.Repo.Migrations.AddTweetSimilaritiesTable do
  use Ecto.Migration

  def change do
    create table(:tweet_similarities) do
      add :similarity, :float, null: false
      add :tweet1_id, references(:tweets), on_delete: :delete_all
      add :tweet2_id, references(:tweets), on_delete: :delete_all
    end

    create unique_index :tweet_similarities, [:tweet1_id, :tweet2_id],
      name: :similarity_index
  end
end
