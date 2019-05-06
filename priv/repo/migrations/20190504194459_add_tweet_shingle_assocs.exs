defmodule Hamstone.Repo.Migrations.AddTweetShingleAssocs do
  use Ecto.Migration

  def change do
    create table(:tweet_shingle_assocs) do
      add :tweet_id, references(:tweets), on_delete: :delete_all
      add :shingle_id, references(:shingles), on_delete: :delete_all
    end

    create unique_index :tweet_shingle_assocs, [:tweet_id, :shingle_id],
      name: :tweet_shingle_assoc_index
  end
end
