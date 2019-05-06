defmodule HamstoneWeb.ShingleController do
  use HamstoneWeb, :controller
  alias Hamstone.Twitter

  def index(conn, _params) do
    shingles = Twitter.get_shingles_for_page(1)
    render conn, "index.html",
      shingles: shingles,
      shingle_count: Twitter.count_shingles(),
      page_index: 1,
      base_index: 1
  end
end