defmodule Hamstone.Jaccard.TweetProcessor do
  use GenServer, restart: :temporary
  # alias Hamstone.Twitter

  require Logger

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg)
  end

  def start do
    :todo
  end

  @impl true
  def init(arg) do
    {:ok, arg}
  end

  @impl true
  def handle_cast(:start, tweet) do
    {:noreply, tweet}
  end

  # defp check_similarity(tweet1, tweet2) do
  #   text1 = Twitter.get_tweet_text(tweet1)
  #   text2 = Twitter.get_tweet_text(tweet2)
  #   jaccard = get_jaccard_similarity(text1, text2)
  #   if jaccard > 0.3 do
  #     Twitter.insert_similarity(tweet1, tweet2, jaccard)
  #   end
  # end

  # defp get_jaccard_similarity(_text1, _text2) do
  #   :todo
  # end
end