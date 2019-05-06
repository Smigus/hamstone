defmodule Hamstone.Twitter.TweetShingleAssoc do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tweet_shingle_assocs" do
    belongs_to :tweet, Hamstone.Twitter.Tweet
    belongs_to :shingle, Hamstone.Twitter.Shingle
  end

  def changeset(assoc, attrs) do
    assoc
    |> change(attrs)
    |> unique_constraint(:tweet, name: :tweet_shingle_assoc_index)
  end
end