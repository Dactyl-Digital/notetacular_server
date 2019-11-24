defmodule BackendWeb.NotebookControllerTest do
  use BackendWeb.ConnCase
  alias Dbstore.{Repo, User, Notebook}

  setup do
    on_exit(fn ->
      Repo.delete_all("notebooks")
      Repo.delete_all("credentials")
      Repo.delete_all("memberships")
      Repo.delete_all("users")
    end)
  end

  def setup_user(context) do
    {:ok, user} =
      %User{}
      |> User.changeset(%{
        username: "testuser",
        account_active: true,
        credentials: %{
          email: "test@test.com",
          password: "testpassword"
        },
        memberships: %{
          subscribed_until: Timex.now() |> Timex.shift(days: 30)
        }
      })
      |> Repo.insert()

    {:ok, user} =
      user
      |> User.activate_account_changeset(%{
        account_active: true,
        credentials: %{
          id: user.credentials.id,
          email_verification_token_expiry: nil,
          hashed_email_verification_token: nil
        }
      })
      |> Repo.update()

    context = Map.put(context, :user, user)
    {:ok, context}
  end

  setup_all do
    # handles clean up after all tests have run
    on_exit(fn ->
      Repo.delete_all("notebooks")
      Repo.delete_all("credentials")
      Repo.delete_all("memberships")
      Repo.delete_all("users")
    end)

    :ok
  end

  # NOTE: Not going to run these kind of tests on any other controllers,
  #      but guess it would be recommended if wanting to be thorough.
  test "POST /api/notebook fails to create a notebook if user isn't logged in", %{conn: conn} do
    conn = post(conn, "/api/notebook", %{title: "notebook1"})

    assert %{"message" => "Invalid session"} === json_response(conn, 400)
  end

  describe "/api/notebook controllers" do
    setup [:setup_user]

    test "POST /api/notebook creates a notebook with the user's id as the owner_id", %{conn: conn} do
      conn = post(conn, "/api/login", %{username: "testuser", password: "testpassword"})
      conn = post(conn, "/api/notebook", %{title: "notebook1"})

      assert %{"message" => "Successfully created notebook!"} === json_response(conn, 200)
    end

    test "GET /api/notebooks lists a user's own notebooks", %{conn: conn, user: user} do
      conn = post(conn, "/api/login", %{username: "testuser", password: "testpassword"})
      conn = post(conn, "/api/notebook", %{title: "notebook1"})
      conn = post(conn, "/api/notebook", %{title: "notebook2"})
      conn = get(conn, "/api/notebook?limit=2&offset=0", %{})

      assert %{
               "message" => "Successfully listed notebooks!",
               "data" => %{
                 "notebooks" => notebooks
               }
             } = json_response(conn, 200)

      assert Kernel.length(notebooks) === 2
    end
  end
end
