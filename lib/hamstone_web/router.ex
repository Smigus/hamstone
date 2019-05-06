defmodule HamstoneWeb.Router do
  use HamstoneWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HamstoneWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/page/:index", PageController, :show_page
    post "/page", PageController, :stop_scraping
    put "/page/:id", PageController, :modify_tweet
    delete "/page/:id", PageController, :delete_tweet
  end

  scope "/similar", HamstoneWeb do
    pipe_through :browser

    get "/:id", SimilarTweetController, :show
    get "/:id/:index", SimilarTweetController, :show_for_page
  end

  scope "/shingle", HamstoneWeb do
    pipe_through :browser

    get "/", ShingleController, :index
    get "/page/:index", ShingleController, :show_page
  end

  scope "/api", HamstoneWeb do
    pipe_through :api

    post "/tweet_info/insert", TweetInfoController, :insert_tweet_info
    post "/tweet_info/scrape", TweetInfoController, :scrape
  end
end
