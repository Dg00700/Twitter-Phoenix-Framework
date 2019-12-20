use Mix.Config

# Configure your database
config :twitter5, Twitter5.Repo,
  username: "postgres",
  password: "postgres",
  database: "twitter5_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :twitter5, Twitter5Web.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
