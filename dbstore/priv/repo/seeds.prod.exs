alias Dbstore.{
  Repo,
  User,
  Role
}

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
