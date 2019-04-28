use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :flipay, FlipayWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :flipay, Flipay.Repo,
  username: "admin",
  password: "123456",
  database: "flipay_test",
  hostname: "127.0.0.1",
  pool: Ecto.Adapters.SQL.Sandbox
