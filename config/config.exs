# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :flipay,
  ecto_repos: [Flipay.Repo]

# Configures the endpoint
config :flipay, FlipayWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "rxkPdcRfbNMSVv97j2sofFHyDm2N95iPLniW0Ya8UT8M2IWE6KN3PLA6RvNtjFWq",
  render_errors: [view: FlipayWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Flipay.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configures Guardian
config :flipay, Flipay.Guardian,
  issuer: "flipay",
  secret_key: "Gl9GGqHm+NI851/DPsZAlusyhuMUeZ25pbv9G+S6qvKN7Yni+ZaV6hGNkRf7fDxS"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
