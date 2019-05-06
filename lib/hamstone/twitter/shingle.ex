defmodule Hamstone.Twitter.Shingle do
  use Ecto.Schema
  import Ecto.Changeset

  schema "shingles" do
    field :word1, :string
    field :word2, :string
    field :word3, :string
  end

  def changeset(shingle, attrs) do
    shingle
    |> change(attrs)
    |> unique_constraint(:word1, name: :shingle_index)
  end
end