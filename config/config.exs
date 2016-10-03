# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :road_disruptions, RoadDisruptions.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "qIEWYDRkb1IALxiPOZzP20N2B9UygWOPXj7N09LcBQInQjNbnPJh716ulMH/n64x",
  render_errors: [view: RoadDisruptions.ErrorView, accepts: ~w(html json)],
  pubsub: [name: RoadDisruptions.PubSub,
           adapter: Phoenix.PubSub.PG2],
  tims_app_id: System.get_env("TIMS_APP_ID"),
  tims_app_key: System.get_env("TIMS_APP_KEY")

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
