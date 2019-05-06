# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :hamstone,
  ecto_repos: [Hamstone.Repo]

# Configures the endpoint
config :hamstone, HamstoneWeb.Endpoint,
  url: [host: "sp19-cs411-33.cs.illinois.edu"],
  secret_key_base: "XzA8Zt4udNJIo4fNsWldLzHe4+xH+bNdq2Kg4lqgEgBrgC5nfunKKFWnG3K7/pxK",
  render_errors: [view: HamstoneWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Hamstone.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
