defmodule BackendWeb.TopicControllerTest do
  use BackendWeb.ConnCase
  alias Dbstore.{Repo, User, SubCategory, Topic}

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

  def setup_sub_category_id_list(context) do
    {:ok, notebook} = Notebooks.create_notebook(%{title: "notebook1", owner_id: context.user.id})

    {:ok, %{id: id}} =
      Notebooks.create_sub_category(%{
        requester_id: context.user.id,
        title: "sub_category1",
        notebook_id: notebook.id
      })

    context = Map.put(context, :sub_category_id_list, [id])
    {:ok, context}
  end

  setup do
    on_exit(fn ->
      Repo.delete_all("topics")
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
      Repo.delete_all("topics")
      Repo.delete_all("sub_categories")
      Repo.delete_all("notebooks")
      Repo.delete_all("credentials")
      Repo.delete_all("memberships")
      Repo.delete_all("users")
    end)

    :ok
  end

  describe "/api/topic controllers" do
    setup [:setup_user, :setup_sub_category_id_list]

    test "POST /api/topic creates a topic with the user's id as the owner_id", %{
      conn: conn,
      user: user,
      sub_category_id_list: sub_category_id_list
    } do
      conn = post(conn, "/api/login", %{username: "testuser", password: "testpassword"})

      conn =
        post(conn, "/api/topic", %{
          title: "topic1",
          sub_category_id: Enum.at(sub_category_id_list, 0)
        })

      assert %{"message" => "Successfully created topic!", "data" => data} =
               json_response(conn, 201)

      assert [%SubCategory{topics: topics}] =
               Notebooks.list_sub_categories(%{
                 requester_id: user.id,
                 sub_category_id_list: sub_category_id_list,
                 limit: 20,
                 offset: 0
               })

      assert Kernel.length(topics) === 1
    end

    test "GET /api/topic lists all of the topics nested in a sub_category's topic_id_list",
         %{conn: conn, user: user, sub_category_id_list: sub_category_id_list} do
      conn = post(conn, "/api/login", %{username: "testuser", password: "testpassword"})

      conn =
        post(conn, "/api/topic", %{
          title: "topic1",
          sub_category_id: Enum.at(sub_category_id_list, 0)
        })

      conn =
        post(conn, "/api/topic", %{
          title: "topic2",
          sub_category_id: Enum.at(sub_category_id_list, 0)
        })

      [%SubCategory{topics: topics_id_list}] =
        Notebooks.list_sub_categories(%{
          requester_id: user.id,
          sub_category_id_list: sub_category_id_list,
          limit: 20,
          offset: 0
        })

      conn =
        get(conn, "/api/topic?limit=10&offset=0", %{
          topic_id_list: topics_id_list
        })

      assert %{
               "message" => "Successfully listed topics!",
               "data" => %{
                 "topics" => topics
               }
             } = json_response(conn, 200)

      assert Kernel.length(topics) === 2
      # TODO: FIgure out why order_by isn't doing shit... Otherwise this test is finished.
      # assert [%{"title" => "sub_category2"}, %{"title" => "sub_category1"}] = topics
    end
  end
end
