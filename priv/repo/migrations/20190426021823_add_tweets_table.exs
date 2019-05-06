defmodule Hamstone.Repo.Migrations.AddTweetsTable do
  use Ecto.Migration

  def change do
    create table(:tweets) do
      add :tweetid, :string
      add :username, :string, null: false
      add :time, :integer, null: false
      add :text1, :string, null: false
      add :text2, :string, null: false

      add :inserted_at, :utc_datetime
      add :updated_at, :utc_datetime
    end

    create unique_index(:tweets, [:tweetid])
  end
end
