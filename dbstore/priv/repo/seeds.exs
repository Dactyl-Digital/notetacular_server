# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#

alias Dbstore.{Repo, User, Credential, Membership, Billing, Role, Permission, Notebook, SubCategory, Topic, Note, NoteTimer}

Repo.delete_all(Credential)
Repo.delete_all(Membership)
Repo.delete_all(Billing)
Repo.delete_all("user_roles")
Repo.delete_all(User)
Repo.delete_all("role_permissions")
Repo.delete_all(Role)
Repo.delete_all(Permission)

#
# USERS
#

{:ok, user1} =
  %User{}
  |> User.changeset(%{
      username: "user1",
      credentials: %{
        email: "user1@gmail.com",
        password: "password"
      },
      memberships: %{
        # NOTE: The initial sign_up_user controller/resolver will
        # use timex to generate the initial trial period as well.
        subscribed_until: Timex.now() |> Timex.shift(days: 30)
      }
    })
  |> Repo.insert
  
{:ok, role} = 
  %Role{} 
  |> Role.changeset(%{
    name: "ADMIN",
    description: "God of this domain."
  })
  |> Repo.insert

{:ok, permission} =
  %Permission{}
  |> Permission.changeset(%{
    name: "ALL"
  })
  |> Repo.insert

Repo.insert_all(
  "user_roles",
  [
    [
      user_id: user1.id,
      role_id: role.id,
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    ]
  ]
)

Repo.insert_all(
  "role_permissions",
  [
    [
      role_id: role.id,
      permission_id: permission.id,
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    ]
  ]
)