defmodule Hamstone.Twitter.TweetSimilarity do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tweet_similarities" do
    field :similarity, :float
    belongs_to :tweet1, Hamstone.Twitter.Tweet
    belongs_to :tweet2, Hamstone.Twitter.Tweet
  end

  def changeset(tweet_similarity, attrs) do
    tweet_similarity
    |> change(attrs)
    |> unique_constraint(:tweet1, name: :similarity_index)
  end
end