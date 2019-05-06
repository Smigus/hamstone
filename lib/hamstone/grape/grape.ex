defmodule Hamstone.Grape do
  use GenServer
  alias Hamstone.Twitter
  alias __MODULE__.TweetScraper
  alias __MODULE__.TSSupervisor
  import Hamstone.Jaccard

  @stop_words [
    "the", "a", "an", "and", "or", "you", "i", "in", "on", "to", "from", "is",
    "are", "do", "that", "have", "it", "for", "not", "with", "he", "as", "at",
    "this", "but", "his", "by", "they", "we", "say", "her", "she", "or", "will",
    "my", "one", "all", "would", "there", "what", "so", "up", "out", "if",
    "about", "get", "go", "me", "can", "like", "no", "take", "good", "your",
    "them", "then", "now", "look", "also"
    ]

  @doc """
  Starts the loop process.
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Start scraping Tweets.
  """
  def start_shooting do
    GenServer.cast(__MODULE__, :scrape)
  end

  def is_scraping? do
    GenServer.call(__MODULE__, :is_scraping?)
  end

  def stop_scraping do
    GenServer.call(__MODULE__, :stop_scraping)
  end

  @impl true
  def init(:ok) do
    Phoenix.PubSub.subscribe Hamstone.PubSub, "tweet_info:scrape"
    table = :ets.new(:table, [:named_table, read_concurrency: true])
    {:ok, {table, %{}}}
  end

  @impl true
  def handle_call(:is_scraping?, _from, {table, refs}) do
    {:reply, :ets.first(table) != :"$end_of_table", {table, refs}}
  end

  def handle_call(:stop_scraping, _from, {table, refs}) do
    kill_children(table)
    {:reply, :ok, {table, refs}}
  end

  @impl true
  def handle_info(:scrape, {table, refs}) do
    # tweets = Twitter.get_non_similar_tweets(500)
    {table, refs} =
      @stop_words
      |> Enum.map(fn s -> {s, nil} end)
      |> Enum.reduce({table, refs}, &scrape_tweets/2)

    {:noreply, {table, refs}}
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, {table, refs}) do
    {term, refs} = Map.pop(refs, ref)
    :ets.delete(table, term)
    {:noreply, {table, refs}}
  end

  def handle_info(:kill_children, {table, refs}) do
    kill_children(table)
    {:noreply, {table, refs}}
  end

  defp kill_children(table) do
    terminate_fun =
      fn({_term, pid}, _) ->
        DynamicSupervisor.terminate_child(TSSupervisor, pid)
      end
    :ets.foldl(terminate_fun, :ok, table)
  end

  defp scrape_similar_tweets(tweet, {table, refs}) do
    scrape_tweets({tweet.id, tweet}, {table, refs})
  end

  defp scrape_tweets({term, shingles}, {table, refs}) do
    lookup(table, term)
    |> after_lookup({table, refs}, {term, shingles})
  end

  defp lookup(table, term) do
    case :ets.lookup(table, term) do
      [{^term, pid}] -> {:ok, pid}
      [] -> :error
    end
  end

  defp after_lookup({:ok, _pid}, {table, refs}, {_term, _shingles}), do: {table, refs}
  defp after_lookup(:error, {table, refs}, {term, shingles}) do
    {:ok, pid} = DynamicSupervisor.start_child(TSSupervisor, {TweetScraper, {term, shingles}})
    ref = Process.monitor(pid)
    refs = Map.put(refs, ref, term)
    :ets.insert(table, {term, pid})
    TweetScraper.scrape(pid)
    Process.send_after(self(), :kill_children, 60 * 1000)
    {table, refs}
  end
end