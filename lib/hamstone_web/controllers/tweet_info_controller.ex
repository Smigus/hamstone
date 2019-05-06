defmodule HamstoneWeb.TweetInfoController do
  use HamstoneWeb, :controller

  require Logger

  def scrape(conn, %{"scrape" => %{"redirect_to" => request_path}}) do
    Phoenix.PubSub.broadcast Hamstone.PubSub, "tweet_info:scrape", :scrape
    conn
    |> redirect(to: request_path)
  end
end
