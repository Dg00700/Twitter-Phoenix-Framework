# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :twitter5,
  ecto_repos: [Twitter5.Repo]

# Configures the endpoint
config :twitter5, Twitter5Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "1mJiXZTZFV67eeyRBe/3OVs3n7F3GuUH0JB8/VWqCOay1a9foZ0+YDFwXWG+AgDw",
  render_errors: [view: Twitter5Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Twitter5.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
