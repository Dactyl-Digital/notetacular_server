import Config

config :dbstore, ecto_repos: [Dbstore.Repo]

import_config "#{Mix.env()}.exs"
