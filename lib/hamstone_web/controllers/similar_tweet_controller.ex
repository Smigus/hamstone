defmodule HamstoneWeb.SimilarTweetController do
  use HamstoneWeb, :controller
  alias Hamstone.Twitter
  import Hamstone.Jaccard

  def show(conn, %{"id" => id}) do
    {id, _} = Integer.parse(id)
    tweet = Twitter.get_tweet!(id)
    similar_tweets = Twitter.get_similar_tweets(tweet, 1)
    Enum.each(similar_tweets, fn t -> Twitter.insert_similarity(t, tweet, t.similarity) end)

    shingless = Enum.map(similar_tweets, fn st -> Twitter.get_shingles(st, tweet) end)

    sstt = Enum.zip(similar_tweets, shingless)

    Enum.each(sstt, fn {st, shingles} -> Twitter.insert_shingles(st, tweet, shingles) end)

    shingle_count = Twitter.count_shingles()

    render conn, "index.html",
      shingle_count: shingle_count,
      shingless: shingless,
      current_text: tweet.text1 <> tweet.text2,
      tweets: similar_tweets,
      tweet_count: Twitter.count_tweets(),
      page_index: 1,
      base_index: 1
  end
end