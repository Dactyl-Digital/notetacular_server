defmodule Dbstore.Repo do
  use Ecto.Repo,
    otp_app: :dbstore,
    adapter: Ecto.Adapters.Postgres
end
