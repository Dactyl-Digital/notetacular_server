use Mix.Config

config :dbstore, Dbstore.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "notastical_dev",
  username: "jamesgood",
  password: "postgres",
  hostname: "localhost",
  pool_size: 10
