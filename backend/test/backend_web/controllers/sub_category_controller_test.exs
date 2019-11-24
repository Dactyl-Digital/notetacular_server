defmodule BackendWeb.SubCategoryControllerTest do
  use BackendWeb.ConnCase
  alias Dbstore.{Repo, User, Notebook}

  # TODO: This has now become redundant... Should be moved
  #       to the macro helper file. (like the one setup in the Notebooks project)
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

  def setup_notebook(context) do
    {:ok, notebook} = Notebooks.create_notebook(%{title: "notebook1", owner_id: context.user.id})
    context = Map.put(context, :notebook, notebook)
    {:ok, context}
  end

  setup do
    on_exit(fn ->
      Repo.delete_all("sub_categories")
      Repo.delete_all("notebooks")
      Repo.delete_all("credentials")
      Repo.delete_all("memberships")
      Repo.delete_all("users")
    end)
  end

  setup_all do
    # handles clean up after all tests have run
    on_exit(fn ->
      Repo.delete_all("sub_categories")
      Repo.delete_all("notebooks")
      Repo.delete_all("credentials")
      Repo.delete_all("memberships")
      Repo.delete_all("users")
    end)

    :ok
  end

  describe "/api/sub_category controllers" do
    setup [:setup_user, :setup_notebook]

    test "POST /api/sub_category creates a sub_category with the user's id as the owner_id", %{
      conn: conn,
      user: user,
      notebook: notebook
    } do
      conn = post(conn, "/api/login", %{username: "testuser", password: "testpassword"})
      conn = post(conn, "/api/sub_category", %{title: "sub_category1", notebook_id: notebook.id})

      assert %{"message" => "Successfully created sub category!"} === json_response(conn, 200)

      assert [%Notebook{sub_categories: sub_categories}] =
               Notebooks.list_notebooks(%{owner_id: user.id, limit: 20, offset: 0})

      assert Kernel.length(sub_categories) === 1
    end

    test "GET /api/sub_category lists all of the sub_categories nested in a notebook's sub_categories_id_list",
         %{conn: conn, user: user, notebook: notebook} do
      conn = post(conn, "/api/login", %{username: "testuser", password: "testpassword"})
      conn = post(conn, "/api/sub_category", %{title: "sub_category1", notebook_id: notebook.id})
      conn = post(conn, "/api/sub_category", %{title: "sub_category2", notebook_id: notebook.id})

      [%Notebook{sub_categories: sub_categories_id_list}] =
        Notebooks.list_notebooks(%{owner_id: user.id, limit: 20, offset: 0})

      IO.puts("The sub category id list")
      IO.inspect(sub_categories_id_list)

      conn =
        get(conn, "/api/sub_category?limit=10&offset=0", %{
          sub_category_id_list: sub_categories_id_list
        })

      assert %{
               "message" => "Successfully listed sub_categories!",
               "data" => %{
                 "sub_categories" => sub_categories
               }
             } = json_response(conn, 200)

      # TODO: FIgure out why order_by isn't doing shit... Otherwise this test is finished.
      # assert [%{"title" => "sub_category2"}, %{"title" => "sub_category1"}] = sub_categories
    end
  end
end
