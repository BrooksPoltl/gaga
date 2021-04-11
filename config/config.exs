# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :gaga,
  ecto_repos: [Gaga.Repo]

# Configures the endpoint
config :gaga, GagaWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "jVCA5PMwUDrhxl2vYtyJH+DgTYxKIdiytpiXI2AlzYvwAC1JJpqHxLhY8+aDJv2K",
  render_errors: [view: GagaWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Gaga.PubSub,
  live_view: [signing_salt: "eJ4AfKQ4"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
