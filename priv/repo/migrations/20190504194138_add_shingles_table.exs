defmodule Hamstone.Repo.Migrations.AddShinglesTable do
  use Ecto.Migration

  def change do
    create table(:shingles) do
      add :word1, :string, null: false
      add :word2, :string, null: false
      add :word3, :string, null: false
    end

    create unique_index :shingles, [:word1, :word2, :word3],
      name: :shingle_index
  end
end
