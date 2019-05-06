defmodule HamstoneWeb.PageController do
  use HamstoneWeb, :controller
  alias Hamstone.Twitter
  alias Hamstone.Grape

  def index(conn, _params) do
    tweets = Twitter.get_tweets_for_page(1)
    render_tweets(conn, tweets, 1)
  end

  def show_page(conn, %{"index" => index}) do
    {index, _} = Integer.parse(index)
    tweets = Twitter.get_tweets_for_page(index)
    render_tweets(conn, tweets, index)
  end

  def modify_tweet(conn, %{"id" => id, "tweet_info" => info}) do
    %{"tweetid" => tweetid, "username" => username, "text" => text} = info
    %{"redirect_to" => request_path} = info
    {id, _} = Integer.parse(id)
    Twitter.update_tweet_info(id, %{tweetid: tweetid, username: username, text: text})
    redirect conn, to: request_path
  end

  def delete_tweet(conn, %{"id" => id, "delete_form" => %{"redirect_to" => request_path}}) do
    {id, _} = Integer.parse(id)
    Twitter.delete_tweet!(id)
    redirect conn, to: request_path
  end

  def stop_scraping(conn, %{"stop_scraping" => %{"redirect_to" => request_path}}) do
    Grape.stop_scraping()
    redirect conn, to: request_path
  end

  defp render_tweets(conn, tweets, index) do
    busy = Grape.is_scraping?()
    pretty_tweets = Enum.map(tweets, fn tw ->
      %{id: tw.id, tweetid: tw.tweetid, username: tw.username, text: tw.text1 <> tw.text2}
    end)
    base_index = div(index - 1, 5) * 5 + 1
    render conn, "index.html",
      tweets: pretty_tweets,
      tweet_count: Twitter.count_tweets(),
      page_index: index,
      base_index: base_index,
      busy: busy
  end
end
