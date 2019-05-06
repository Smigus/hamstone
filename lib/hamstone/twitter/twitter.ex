defmodule Hamstone.Twitter do
  @moduledoc """
  The Twitter context.
  """

  import Ecto.Query, warn: false
  alias Hamstone.Repo
  alias Ecto.Multi

  alias Hamstone.Twitter.Tweet
  alias Hamstone.Twitter.TweetSimilarity
  alias Hamstone.Twitter.Shingle
  alias Hamstone.Twitter.TweetShingleAssoc
  import Hamstone.Jaccard

  require Logger

  @doc "Lists all tweets"
  def list_tweets do
    Repo.all(Tweet)
  end

  @doc "Gets a single tweet by the tweet's id (not tweetid)"
  def get_tweet!(id), do: Repo.get!(Tweet, id)

  @doc "Get the number of popular shingles in the database"
  def count_shingles do
    Repo.one(from s in Shingle, select: count(s.id))
  end

  @doc "Get the number of tweets in the database"
  def count_tweets do
    Repo.one(from u in Tweet, select: count(u.id))
  end

  # @doc "Get all tweets prior to the given tweets"
  # def get_previous_tweets(id) do
  #   Repo.all(from u in Tweet, where: u.id < ^id, select: u)
  # end

  @doc """
  Gets tweets on the page with given index
  """
  def get_tweets_for_page(index) do
    offset = 100 * (index - 1)
    query =
      from t in Tweet,
        order_by: [desc: t.id],
        offset: ^offset,
        limit: 100,
        select: t

    Repo.all(query)
  end

  def get_shingles(pretty_tweet, ugly_tweet) do
    mem_query =
      from s in Shingle,
        join: assoc1 in TweetShingleAssoc,
        join: assoc2 in TweetShingleAssoc,
        where: assoc1.shingle_id == s.id and
               assoc2.shingle_id == s.id and
               assoc1.tweet_id == ^pretty_tweet.id and
               assoc2.tweet_id == ^ugly_tweet.id,
        select: s

    mem_result = Repo.all(mem_query)
    case mem_result do
      [] ->
        find_shingles(pretty_tweet.text, ugly_tweet.text1 <> ugly_tweet.text2)
        |> MapSet.to_list()
      _ ->
        mem_result
        |> Enum.map(fn %{word1: word1, word2: word2, word3: word3} -> {word1, word2, word3} end)
    end
  end

  def insert_shingles(pretty_tweet, ugly_tweet, shingles) do
    Enum.each(shingles, fn s -> insert_shingle_tweets(pretty_tweet, ugly_tweet, s) end)
  end

  def insert_shingle_tweets(pretty_tweet, ugly_tweet, shingle) do
    insert_shingle_tweet_assoc(shingle, pretty_tweet)
    insert_shingle_tweet_assoc(shingle, ugly_tweet)
  end

  @doc """
  Gets shingles on the page with given index
  """
  def get_shingles_for_page(index) do
    query =
      from s in Shingle,
        limit: 99,
        select: s

    Repo.all(query)
    |> Enum.shuffle()
  end

  def get_non_similar_tweets(n_tweets) do
    query =
      from t in Tweet,
        left_join: assoc in TweetShingleAssoc, on: [tweet_id: t.id],
        where: is_nil(assoc.tweet_id),
        select: t,
        limit: ^n_tweets

    Repo.all(query)
    |> Enum.map(&get_pretty_tweet/1)
  end

  def get_similar_tweets(tweet, _index) do
    tweet_info = get_pretty_tweet(tweet)

    mem_query =
      from t1 in Tweet,
        join: assoc in TweetSimilarity,
        where: (assoc.tweet1_id == t1.id and assoc.tweet2_id == ^tweet.id) or (assoc.tweet1_id == ^tweet.id and assoc.tweet2_id == t1.id),
        select: %{id: t1.id, tweetid: t1.tweetid, username: t1.username, text1: t1.text1, text2: t1.text2, similarity: assoc.similarity}

    mem_result = Repo.all(mem_query)
    if mem_result != [] do
      mem_result
      |> Enum.map(&get_pretty_tweet/1)
      |> Enum.sort_by(fn t -> -t.similarity end)
    else
      query =
      from t in Tweet,
        order_by: [desc: t.id],
        where: t.id != ^tweet.id,
        select: t

      Repo.all(query)
      |> Enum.map(&get_pretty_tweet/1)
      |> Enum.filter(fn t -> jaccard_similarity(t.text, tweet_info.text) > 0 end)
      |> Enum.map(fn t -> Map.put(t, :similarity, jaccard_similarity(t.text, tweet_info.text)) end)
      |> Enum.sort_by(fn t -> -t.similarity end)
    end
  end

  @doc "Inserts a tweet"
  def insert_tweet(tweet, attrs \\ %{}) do
    Logger.debug "Tweet to insert: #{inspect(tweet)}"
    tweet
    |> Tweet.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Gets a single tweet by its tweetid"
  def get_tweet_by_tweetid(tweetid), do: Repo.get_by(Tweet, tweetid: tweetid)

  @doc "Get the URL string of the given tweet"
  def get_tweet_url(%Tweet{} = tweet) do
    "https://twitter.com/" <> tweet.username <> "/status/" <> tweet.tweetid
  end

  def get_pretty_tweet(%{} = tweet) do
    Map.put(tweet, :text, tweet.text1 <> tweet.text2)
  end

  @doc "Get the full text of the given tweet"
  def get_tweet_text(%Tweet{} = tweet) do
    tweet.text1 <> tweet.text2
  end

  @doc "Returns the ids."
  def insert_tweet_infos(infos) do
    attrs = Enum.map(infos, &get_tweet_attrs/1)
    Repo.insert_all Tweet, attrs,
      on_conflict: :nothing
  end

  @doc "Takes in a shingle and a tweet."
  def insert_shingle_tweet_assoc(shingle, tweet) do
    {word1, word2, word3} = shingle
    shingle_id = 
      case Repo.get_by(Shingle, [word1: word1, word2: word2, word3: word3]) do
        %Shingle{id: s_id} ->
          s_id

        nil ->
          changeset = Shingle.changeset(%Shingle{}, %{word1: word1, word2: word2, word3: word3})
          with {:ok, s} <- Repo.insert(changeset), do: s.id
      end

    %TweetShingleAssoc{}
    |> TweetShingleAssoc.changeset(%{tweet_id: tweet.id, shingle_id: shingle_id})
    |> Repo.insert()
  end

  @doc "Takes in a shingle and a bunch of ***tweetids***."
  def insert_shingle_tweet_assocs(shingle, tweetids) do
    {word1, word2, word3} = shingle
    shingle_id = 
      case Repo.get_by(Shingle, [word1: word1, word2: word2, word3: word3]) do
        %Shingle{id: s_id} ->
          s_id

        nil ->
          with {:ok, s} <- Repo.insert(%Shingle{word1: word1, word2: word2, word3: word3}), do: s.id
      end

    tweets =
      tweetids
      |> Enum.map(fn tweetid -> Repo.get_by(Tweet, tweetid: tweetid) end)

    entries =
      tweets
      |> Enum.map(fn t -> %{tweet_id: t.id, shingle_id: shingle_id} end)

    Repo.insert_all TweetShingleAssoc, entries,
      on_conflict: :nothing
  end

  def update_tweet_info(id, info) do
    attrs = get_tweet_attrs(info)

    assoc_query =
      from assoc in TweetShingleAssoc,
        where: assoc.tweet_id == ^id

    sim_query =
      from sim in TweetSimilarity,
        where: sim.tweet1_id == ^id or
               sim.tweet2_id == ^id

    Multi.new()
    |> Multi.update(:tweets, Tweet.changeset(%Tweet{id: id}, attrs))
    |> Multi.delete_all(:tweet_shingle_assocs, assoc_query)
    |> Multi.delete_all(:tweet_similarities, sim_query)
    |> Repo.transaction()
  end

  def delete_tweet!(id) do
    Repo.get!(Tweet, id)
    |> Repo.delete!()
  end

  defp get_tweet_attrs(%{username: username, tweetid: tweetid, text: text}) do
    {text1, text2} = split_tweet_text(text)
    attrs = %{
      tweetid: tweetid,
      username: username,
      text1: text1,
      text2: text2
    }

    attrs
  end

  @doc "Inserts a record indicating similarity between two tweets"
  def insert_similarity(tweet1, tweet2, similarity) do
    sim = %TweetSimilarity{tweet1_id: tweet1.id, tweet2_id: tweet2.id}
    sim
    |> TweetSimilarity.changeset(%{similarity: similarity})
    |> Repo.insert()
  end

  defp split_tweet_text(text) do
    if String.length(text) < 256 do
      {text, ""}
    else
      text1 = String.slice(text, 0..254)
      text2 = String.slice(text, 255..-1)
      {text1, text2}
    end
  end
end