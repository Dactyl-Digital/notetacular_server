# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#

alias Dbstore.{
  Repo,
  User,
  Credential,
  Membership,
  Billing,
  Role,
  Permission,
  NotebookShareuser,
  Notebook,
  SubCategory,
  Topic,
  Note,
  NoteTimer
}

Repo.delete_all(Note)
Repo.delete_all(Topic)
Repo.delete_all(SubCategory)
Repo.delete_all(Notebook)
Repo.delete_all(Credential)
Repo.delete_all(Membership)
Repo.delete_all(Billing)
Repo.delete_all("user_roles")
Repo.delete_all(User)
Repo.delete_all("role_permissions")
Repo.delete_all(Role)
Repo.delete_all(Permission)

#######
# USERS
#######
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
  
  {:ok, user2} =
    %User{}
    |> User.changeset(%{
        username: "user2",
        credentials: %{
          email: "user2@gmail.com",
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

# Repo.insert_all(
#   "user_roles",
#   [
#     [
#       user_id: user1.id,
#       role_id: role.id,
#       inserted_at: DateTime.utc_now(),
#       updated_at: DateTime.utc_now()
#     ]
#   ]
# )

# Repo.insert_all(
#   "role_permissions",
#   [
#     [
#       role_id: role.id,
#       permission_id: permission.id,
      # inserted_at: DateTime.utc_now(),
      # updated_at: DateTime.utc_now()
#     ]
#   ]
# )

{1, [%{id: notebook_id}]} = Repo.insert_all("notebooks", [[
    title: "notebook1",
    owner_id: user1.id,
    inserted_at: DateTime.utc_now(),
    updated_at: DateTime.utc_now()
  ]],
  returning: [:id]
)

%NotebookShareuser{}
|> NotebookShareuser.changeset(%{user_id: user2.id, notebook_id: notebook_id, read_only: false})
|> Repo.insert

{1, [%{id: sub_category_id}]} = Repo.insert_all("sub_categories", [[
    title: "sub_category1",
    notebook_id: notebook_id,
    inserted_at: DateTime.utc_now(),
    updated_at: DateTime.utc_now()
  ]],
  returning: [:id]
)

{1, [%{id: topic_id}]} = Repo.insert_all("topics", [[
    title: "topic1",
    sub_category_id: sub_category_id,
    inserted_at: DateTime.utc_now(),
    updated_at: DateTime.utc_now()
  ]],
  returning: [:id]
)

{1, [%{id: note_id}]} = Repo.insert_all("notes", [[
    title: "note1",
    topic_id: topic_id,
    order: 1,
    inserted_at: DateTime.utc_now(),
    updated_at: DateTime.utc_now()
  ]],
  returning: [:id]
)