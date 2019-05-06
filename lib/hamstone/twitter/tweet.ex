defmodule Hamstone.Twitter.Tweet do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tweets" do
    field :tweetid, :string
    field :username, :string
    field :time, :integer
    field :text1, :string
    field :text2, :string

    timestamps()
  end

  def changeset(tweet, attrs) do
    tweet
    |> cast(attrs, [:tweetid, :username, :time, :text1, :text2])
    |> validate_required([:tweetid, :username, :text1])
    |> unique_constraint(:tweetid)
  end
end