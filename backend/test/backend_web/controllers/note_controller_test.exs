defmodule BackendWeb.NoteControllerTest do
  use BackendWeb.ConnCase
  alias Dbstore.{Repo, User, Topic, Note}

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

  def setup_topic_id_list(context) do
    {:ok, notebook} = Notebooks.create_notebook(%{title: "notebook1", owner_id: context.user.id})

    {:ok, sub_category} =
      Notebooks.create_sub_category(%{
        requester_id: context.user.id,
        title: "notebook1",
        notebook_id: notebook.id
      })

    {:ok, %{id: id}} =
      Notebooks.create_topic(%{
        requester_id: context.user.id,
        title: "topic1",
        sub_category_id: sub_category.id
      })

    context = Map.put(context, :topic_id_list, [id])
    {:ok, context}
  end

  setup do
    on_exit(fn ->
      Repo.delete_all("notes")
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
      Repo.delete_all("notes")
      Repo.delete_all("topics")
      Repo.delete_all("sub_categories")
      Repo.delete_all("notebooks")
      Repo.delete_all("credentials")
      Repo.delete_all("memberships")
      Repo.delete_all("users")
    end)

    :ok
  end

  describe "/api/note controllers" do
    setup [:setup_user, :setup_topic_id_list]

    test "POST /api/note creates a note with the user's id as the owner_id", %{
      conn: conn,
      user: user,
      topic_id_list: topic_id_list
    } do
      conn = post(conn, "/api/login", %{username: "testuser", password: "testpassword"})

      conn =
        post(conn, "/api/note", %{
          title: "note1",
          order: 1,
          topic_id: Enum.at(topic_id_list, 0)
        })

      assert %{"message" => "Successfully created note!"} === json_response(conn, 200)

      assert [%Topic{notes: notes}] =
               Notebooks.list_topics(%{
                 requester_id: user.id,
                 topic_id_list: topic_id_list,
                 limit: 20,
                 offset: 0
               })

      assert Kernel.length(notes) === 1
    end

    test "GET /api/note lists all of the notes nested in a topics's topic_id_list",
         %{conn: conn, user: user, topic_id_list: topic_id_list} do
      conn = post(conn, "/api/login", %{username: "testuser", password: "testpassword"})

      conn =
        post(conn, "/api/note", %{
          title: "note1",
          order: 1,
          topic_id: Enum.at(topic_id_list, 0)
        })

      conn =
        post(conn, "/api/note", %{
          title: "note2",
          order: 2,
          topic_id: Enum.at(topic_id_list, 0)
        })

      [%Topic{notes: note_id_list}] =
        Notebooks.list_topics(%{
          requester_id: user.id,
          topic_id_list: topic_id_list,
          limit: 20,
          offset: 0
        })

      conn =
        get(conn, "/api/note?limit=10&offset=0", %{
          note_id_list: note_id_list
        })

      assert %{
               "message" => "Successfully listed notes!",
               "data" => %{
                 "notes" => notes
               }
             } = json_response(conn, 200)

      assert Kernel.length(notes) === 2

      # TODO: FIgure out why order_by isn't doing shit... Otherwise this test is finished.
      # assert [%{"title" => "sub_category2"}, %{"title" => "sub_category1"}] = topics
    end

    test "PUT /api/note/content updates a note with the provided note_content", %{
      conn: conn,
      user: user,
      topic_id_list: topic_id_list
    } do
      conn = post(conn, "/api/login", %{username: "testuser", password: "testpassword"})

      conn =
        post(conn, "/api/note", %{
          title: "note1",
          order: 1,
          topic_id: Enum.at(topic_id_list, 0)
        })

      assert %{"message" => "Successfully created note!", "id" => id} = json_response(conn, 201)

      conn =
        put(conn, "/api/note/content", %{
          note_id: id,
          content_markdown: %{text: "Here is some test text."},
          content_text: "Here is some test text."
        })

      assert %{
               "message" => "Successfully updated the note!"
             } = json_response(conn, 200)

      # Retrieving note from DB to verify that updates were persisted.
      [note] =
        Notebooks.list_notes(%{
          requester_id: user.id,
          note_id_list: [id],
          limit: 20,
          offset: 0
        })

      assert id === note.id

      assert %{
               content_markdown: %{"text" => "Here is some test text."},
               content_text: "Here is some test text."
             } = note
    end
  end
end
