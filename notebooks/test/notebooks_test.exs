defmodule NotebooksTest do
  use ExUnit.Case
  use NotebookBuilders
  doctest Notebooks
  alias Notebooks
  alias Dbstore.{Repo, User, NotebookShareuser, Notebook, SubCategory, Topic, Note, NoteTimer}

  defp setup_users(context) do
    {3, [%{id: user1_id}, %{id: user2_id}, %{id: user3_id}]} =
      Repo.insert_all("users", create_n_users(3), returning: [:id])

    context = Map.put(context, :user1_id, user1_id)
    context = Map.put(context, :user2_id, user2_id)
    context = Map.put(context, :user3_id, user3_id)
    {:ok, context}
  end

  defp setup_notebooks(context) do
    {3,
     [
       %{id: read_only_shared_notebook_id},
       %{id: write_enabled_shared_notebook_id},
       %{id: private_notebook_id}
     ]} = Repo.insert_all("notebooks", create_n_notebooks(3, context.user1_id), returning: [:id])

    {:ok, %Notebook{id: user2_notebook_id}} =
      %Notebook{}
      |> Notebook.changeset(%{title: "user2_notebook", owner_id: context.user2_id})
      |> Repo.insert()

    context = Map.put(context, :read_only_shared_notebook_id, read_only_shared_notebook_id)

    context =
      Map.put(context, :write_enabled_shared_notebook_id, write_enabled_shared_notebook_id)

    context = Map.put(context, :private_notebook_id, private_notebook_id)
    context = Map.put(context, :user2_notebook_id, user2_notebook_id)
    {:ok, context}
  end

  defp setup_sub_categories(context) do
    {:ok, %SubCategory{id: sub_cat1_id}} =
      create_sub_category(1, context.read_only_shared_notebook_id) |> Repo.insert()

    {:ok, %SubCategory{id: sub_cat2_id}} =
      create_sub_category(2, context.write_enabled_shared_notebook_id) |> Repo.insert()

    context = Map.put(context, :sub_cat1_id, sub_cat1_id)
    context = Map.put(context, :sub_cat2_id, sub_cat2_id)
    {:ok, context}
  end

  defp setup_topics(context) do
    {:ok, %Topic{id: topic1_id}} = create_topic(1, context.sub_cat1_id) |> Repo.insert()
    {:ok, %Topic{id: topic2_id}} = create_topic(2, context.sub_cat2_id) |> Repo.insert()
    context = Map.put(context, :topic1_id, topic1_id)
    context = Map.put(context, :topic2_id, topic2_id)
    {:ok, context}
  end

  defp setup_notes(context) do
    {:ok, %Note{id: read_only_shared_note_id}} =
      create_note(2, context.topic1_id) |> Repo.insert()

    {:ok, %Note{id: write_enabled_shared_note_id}} =
      create_note(3, context.topic2_id) |> Repo.insert()

    context = Map.put(context, :read_only_shared_note_id, read_only_shared_note_id)
    context = Map.put(context, :write_enabled_shared_note_id, write_enabled_shared_note_id)
    {:ok, context}
  end

  defp setup_notebook_shareuser(context) do
    {:ok, read_only_notebook_shareuser} =
      Notebooks.share_notebook_with_user(%{
        user_id: context.user2_id,
        notebook_id: context.read_only_shared_notebook_id,
        read_only: true
      })

    {:ok, write_enabled_notebook_shareuser} =
      Notebooks.share_notebook_with_user(%{
        user_id: context.user2_id,
        notebook_id: context.write_enabled_shared_notebook_id,
        read_only: false
      })

    context = Map.put(context, :read_only_notebook_shareuser, read_only_notebook_shareuser)

    context =
      Map.put(context, :write_enabled_notebook_shareuser, write_enabled_notebook_shareuser)

    {:ok, context}
  end

  setup_all do
    # handles clean up after all tests have run
    on_exit(fn ->
      Repo.delete_all("notebook_shareusers")
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

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Dbstore.Repo)
  end

  # TODO: Add testing for this stuff
  # describe "notebook context functions allow a user to CRUD resources in the database" do
  #   test "list notebooks", %{
  #     user1_id: user1_id,
  #   } do
  #     notebook_list = Notebooks.list_notebooks(%{owner_id: user1_id, limit: 10, offset: 0})
  #     IO.puts("notebook_list")
  #     IO.inspect(notebook_list)
  #     assert [%Notebook{id: id}] = notebook_list
  #   end

  # end

  # TODO: Notebooks.retrieve_notes_associated_notebook does retrieve the associated notebook (in order to facilitate
  #       authorization checks for modifying resources) but need to write a test specifically for this.
  # IO.inspect("The read_only_notebook_id")
  # IO.inspect(read_only_shared_notebook_id)
  # assert [%{notebook_id: read_only_shared_notebook_id}] = Notebooks.retrieve_notes_associated_notebook(%{note_id: read_only_shared_note_id})

  # TODO: This should be the second describe block, which handles
  #       the tests which rely on these resources having already been created.
  # But it should still be necessary to test the functions in a preceding
  # describe block, which ensures that the resources are being created and retrieved
  # from the DB successfully, in order to ensure that the public API functions accordingly.
  describe "notebook context functions properly allow/prevent a user to" do
    setup [
      :setup_users,
      :setup_notebooks,
      :setup_sub_categories,
      :setup_topics,
      :setup_notes,
      :setup_notebook_shareuser
    ]

    test "create_notebook/1 inserts a notebook into the DB", %{user1_id: user1_id} do
      assert {:ok, %Notebook{title: title, owner_id: user1_id}} =
               Notebooks.create_notebook(%{title: "notebookTitle", owner_id: user1_id})
    end

    test "create_sub_category/1 inserts a sub_category into the DB", %{
      user1_id: user1_id,
      private_notebook_id: private_notebook_id
    } do
      assert {:ok, %SubCategory{title: title, notebook_id: private_notebook_id}} =
               Notebooks.create_sub_category(%{
                 requester_id: user1_id,
                 title: "subcategoryTitle",
                 notebook_id: private_notebook_id
               })
    end

    test "create_topic/1 inserts a topic into the DB", %{
      user1_id: user1_id,
      sub_cat1_id: sub_cat1_id
    } do
      assert {:ok, %Topic{title: title, sub_category_id: sub_cat1_id}} =
               Notebooks.create_topic(%{
                 requester_id: user1_id,
                 title: "topicTitle",
                 sub_category_id: sub_cat1_id
               })
    end

    test "create_note/1 inserts a note into the DB", %{user1_id: user1_id, topic1_id: topic1_id} do
      assert {:ok, %Note{title: title, topic_id: topic1_id}} =
               Notebooks.create_note(%{
                 requester_id: user1_id,
                 title: "noteTitle",
                 order: 1,
                 topic_id: topic1_id
               })
    end

    test "create_note_timer/1 inserts a note_timer into the DB", %{
      user1_id: user1_id,
      read_only_shared_note_id: read_only_shared_note_id
    } do
      note_timer =
        Notebooks.create_note_timer(%{
          requester_id: user1_id,
          note_id: read_only_shared_note_id,
          timer_count: 1
        })

      IO.puts("note_timer")
      IO.inspect(note_timer)
      assert {:ok, %NoteTimer{note_id: read_only_shared_note_id}} = note_timer
    end

    test "unshared notebooks remain private when listing the user's own notebooks", %{
      user2_id: user2_id,
      user2_notebook_id: user2_notebook_id,
      private_notebook_id: private_notebook_id
    } do
      notebook_list = Notebooks.list_notebooks(%{owner_id: user2_id, limit: 10, offset: 0})
      assert [%Notebook{id: id}] = notebook_list
      assert id === user2_notebook_id
      assert id !== private_notebook_id
    end

    test "unshared notebooks remain private when listing shared notebooks and user's own notebooks don't appear in the output",
         %{
           user2_id: user2_id,
           user2_notebook_id: user2_notebook_id,
           private_notebook_id: private_notebook_id
         } do
      shared_notebook_list =
        Notebooks.list_shared_notebooks(%{user_id: user2_id, limit: 10, offset: 0})

      assert [
               %Notebook{id: read_only_shared_notebook_id, owner_id: owner1_id},
               %Notebook{id: write_enabled_shared_notebook_id, owner_id: owner2_id}
             ] = shared_notebook_list

      assert owner1_id !== user2_id
      assert owner2_id !== user2_id

      assert read_only_shared_notebook_id !== private_notebook_id and
               read_only_shared_notebook_id !== user2_notebook_id

      assert write_enabled_shared_notebook_id !== private_notebook_id and
               write_enabled_shared_notebook_id !== user2_notebook_id
    end

    test "ensure that a read_only notebook_shareuser can read, but not edit notes in the notebook.",
         %{
           read_only_notebook_shareuser: read_only_notebook_shareuser,
           read_only_shared_note_id: read_only_shared_note_id,
           read_only_shared_notebook_id: read_only_shared_notebook_id
         } do
      assert %Note{id: note_id} =
               Notebooks.retrieve_note(%{
                 requester_id: read_only_notebook_shareuser.user_id,
                 note_id: read_only_shared_note_id
               })

      assert note_id === read_only_shared_note_id

      assert {:error, "UNAUTHORIZED_REQUEST"} =
               Notebooks.update_note_content(%{
                 requester_id: read_only_notebook_shareuser.user_id,
                 note_id: read_only_shared_note_id,
                 content_markdown: %{content: "this is it"},
                 content_text: "this is it"
               })
    end

    # TODO: Need to test the listing stuffs.
    # NOTE: listing sub_cats
    # shared_notebook_list = Notebooks.list_shared_notebooks(%{user_id: read_only_notebook_shareuser.user_id, limit: 10, offset: 0})
    # assert [
    #   %Notebook{id: read_only_shared_notebook_id, owner_id: owner1_id},
    #   %Notebook{id: write_enabled_shared_notebook_id, owner_id: owner2_id}

    # assert [%SubCategory{id: sub_category_id}] = Notebooks.list_sub_categories(%{sub_category_id_list: sub_category_id_list, limit: 10, offset: 0})
    # assert sub_category_id === Enum.at(sub_category_id_list, 0)
  end
end
