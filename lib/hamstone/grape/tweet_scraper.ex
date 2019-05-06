defmodule Hamstone.Grape.TweetScraper do
  use GenServer, restart: :temporary
  alias Hamstone.Twitter
  import Hamstone.Jaccard

  require Logger

  @search_url "https://twitter.com/search?f=tweets"

  def start_link({term, tweet}) do
    GenServer.start_link(__MODULE__, {term, tweet})
  end

  @doc "Start scraping tweets"
  def scrape(tweet_scraper) do
    GenServer.cast(tweet_scraper, :scrape)
  end

  @impl true
  def init({term, tweet}) do
    {:ok, {term, tweet}}
  end

  @impl true
  def handle_cast(:scrape, {term, nil}) do
    Logger.debug "Handling scrape event"
    scrape_tweets(term, 0, [])
    {:stop, :shutdown, {term, nil}}
  end

  defp scrape_tweets(term, pos, shingles) do
    infos =
      get_query_url(term, pos)
      |> HTTPoison.get!()
      |> Map.get(:body)
      |> Floki.parse()
      |> Floki.find("div[class~=js-stream-tweet]")
      |> Enum.map(&get_tweet_info/1)

    Twitter.insert_tweet_infos(infos)

    scrape_tweets(term, pos + 1, shingles)
  end

  defp get_query_url(term, pos) do
    @search_url <> "&q=#{term}&pos=#{pos}&l=en"
  end

  defp get_tweet_info(html) do
    tweetid = get_tweetid(html)
    username = get_username(html)
    time = get_timestamp(html)
    text = get_text(html)
    %{tweetid: tweetid, username: username, time: time, text: text}
  end

  defp get_tweetid(html) do
    html
    |> Floki.attribute("data-tweet-id")
    |> Enum.reduce("", fn a, b -> a <> b end)
  end

  defp get_username(html) do
    html
    |> Floki.find("a[class~=js-account-group]")
    |> Floki.find("span[class~=username]")
    |> Floki.find("b")
    |> Floki.text()
  end

  defp get_timestamp(html) do
    time_string = 
      html
      |> Floki.find("span[class~=js-relative-timestamp]")
      |> Floki.attribute("data-time")
      |> Enum.reduce("", fn a, b -> a <> b end)

    with {time, _} <- Integer.parse(time_string) do
      time
    else
      :error ->
        0
    end
  end

  defp get_text(html) do
    html
    |> Floki.find("p[class~=js-tweet-text]")
    |> Floki.text()
    |> String.replace(~r/ http\S+/, "")
    |> String.replace(~r/http\S+ /, "")
    |> String.replace(~r/http\S+/, "")
    |> String.replace(~r/ \S+.com\S*/, "")
    |> String.replace(~r/\S+.com\S* /, "")
    |> String.replace(~r/\S+.com\S*/, "")
    |> String.replace(~r/ #\S+/, "")
    |> String.replace(~r/#\S+ /, "")
    |> String.replace(~r/#\S+/, "")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp get_search_term(shingles) when is_list(shingles) do
    shingles
    |> Enum.map(&get_search_term/1)
    |> Enum.join("%20")
  end

  defp get_search_term({word1, word2, word3}) do
    # "%22#{word1}%20#{word2}%20#{word3}%22"
    "%22#{word1}%20#{word2}%20#{word3}%22"
  end
end