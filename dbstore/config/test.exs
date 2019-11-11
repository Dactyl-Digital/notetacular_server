import Config

config :dbstore, Dbstore.Repo,
  database: "notastical_test",
  username: "jamesgood",
  password: "postgres",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
