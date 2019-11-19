use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :backend, BackendWeb.Endpoint,
  http: [port: 4001],
  server: false
  
config :backend, Backend.Mailer,
  adapter: Bamboo.TestAdapter
  
config :dbstore, Dbstore.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "notastical_test",
  username: "jamesgood",
  password: "postgres",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# Print only warnings and errors during test
config :logger, level: :warn
