defmodule Hamstone.Repo do
  use Ecto.Repo,
    otp_app: :hamstone,
    adapter: Ecto.Adapters.MySQL
end
