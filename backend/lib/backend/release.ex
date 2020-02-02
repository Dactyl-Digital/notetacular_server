defmodule Backend.Release do
  @app :backend
  @dbstore :dbstore
  alias Dbstore.{
    Repo,
    User,
    Role
  }

  # def init_migrate() do
  #   {:ok, _} = Application.ensure_all_started(@app)
  #   IO.puts("all started!")
  #   migrate()
  # end

  def migrate do
    for repo <- repos() do
      # I did still want to see what was up with the oddly configured pool size
      # i.e. running w/ 10 in prod instead of the 20 specified in the config.
      # IO.puts("Running migration...")
      # IO.puts("THE REPO:")
      # IO.inspect(repo)
      # IO.puts("THE REPO.CONFIG:")
      # IO.inspect(repo.config)
      Application.ensure_all_started(@app)
      # THIS DID IT!!!
      # TODO: Ensure that this function is only run if a certain
      # environment variable is set.... So as to avoid the downfalls
      # spoken of in this blog post:
      # https://pythonspeed.com/articles/schema-migrations-server-startup/
      create_db(repo)
      IO.inspect(Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true)))
    end
  end

  def rollback(repo, version) do
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.load(@app)
    Application.fetch_env!(@app, :ecto_repos)
  end

  # copied from...
  # https://github.com/elixir-ecto/ecto/blob/v3.3.0/lib/mix/tasks/ecto.create.ex#L1
  defp create_db(repo) do
    case repo.__adapter__.storage_up(repo.config) do
      :ok ->
        IO.puts("The database for #{inspect(repo)} has been created")

      {:error, :already_up} ->
        IO.puts("The database for #{inspect(repo)} has already been created")

      {:error, term} when is_binary(term) ->
        IO.puts("The database for #{inspect(repo)} couldn't be created: #{term}")

      {:error, term} ->
        IO.puts("The database for #{inspect(repo)} couldn't be created: #{inspect(term)}")
    end
  end

  def create_admin_user() do
    {:ok, _} = Application.ensure_all_started(@dbstore)
    IO.puts("All started :dbstore is true!")

    {:ok, user} =
      %User{}
      |> User.admin_changeset(%{
        username: "notastical-admin",
        account_active: true,
        credentials: %{
          email: "jamesgood@dactyl.digital",
          password: "changeme"
        }
      })
      |> Repo.insert()

    {:ok, role} =
      %Role{}
      |> Role.changeset(%{
        name: "ADMIN",
        description: "You've got the power!"
      })
      |> Repo.insert()

    Repo.insert_all(
      "user_roles",
      [
        [
          user_id: user.id,
          role_id: role.id,
          inserted_at: DateTime.utc_now(),
          updated_at: DateTime.utc_now()
        ]
      ]
    )
  end
end
