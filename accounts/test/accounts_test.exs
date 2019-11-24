defmodule AccountsTest do
  use ExUnit.Case
  use AccountBuilders
  doctest Accounts
  alias Accounts
  alias Dbstore.{Repo, User, Credential, Membership, Billing}

  defp setup_user_data(context) do
    user1_data = create_user_data(1)
    context = Map.put(context, :user1_data, user1_data)
    {:ok, context}
  end

  setup_all do
    # handles clean up after all tests have run
    on_exit(fn ->
      Repo.delete_all("credentials")
      Repo.delete_all("memberships")
      Repo.delete_all("users")
    end)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Dbstore.Repo)
  end

  describe "accounts context functions properly allow/prevent a user to" do
    setup [:setup_user_data]

    test "create_user/1 creates a user w/ associated credential and membership resources", %{
      user1_data: user1_data
    } do
      {:ok, user} = Accounts.Impl.create_user(user1_data)

      assert %User{
               credentials: %Credential{},
               memberships: %Membership{}
             } = user
    end

    test "create_user/1 will not create a user with a duplicate username or email", %{
      user1_data: user1_data
    } do
      assert {:ok, _user} = Accounts.Impl.create_user(user1_data)
      {:error, errors} = Accounts.Impl.create_user(user1_data)

      assert %{
               credentials: %{email: ["That email is already taken"]},
               username: ["That username is already taken"]
             } = errors
    end
  end
end
