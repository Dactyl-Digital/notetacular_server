# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#

alias Dbstore.{Repo, User, Credential, Membership, Billing, Role, Permission}

#
# USERS
#

mike =
  %User{}
  |> User.changeset(%{
      username: "mike",
      credentials: %{
        email: "mike@gmail.com",
        password: "password"
      },
      memberships: %{
        # NOTE: The initial sign_up_user controller/resolver will
        # use timex to generate the initial trial period as well.
        subscribed_until: Timex.now() |> Timex.shift(days: 30)
      }
    })
  |> Repo.insert