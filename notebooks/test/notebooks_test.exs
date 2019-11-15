defmodule NotebooksTest do
  use ExUnit.Case
  use NotebookBuilders
  doctest Notebooks
  alias Notebooks
  alias Dbstore.{Repo, User, Notebook, SubCategory, Topic, Note, NotebookShareuser}

  defp setup_users(context) do
    [{:ok, user1}, {:ok, user2}, {:ok, user3}] =
      Enum.map(create_n_users(3), fn user -> Repo.insert(user) end)

    context = Map.put(context, :user1_id, user1.id)
    context = Map.put(context, :user2_id, user2.id)
    context = Map.put(context, :user3_id, user3.id)
    {:ok, context}
  end

  defp setup_notebooks(context) do
    [{:ok, notebook1}, {:ok, notebook2}, {:ok, private_notebook}] =
      Enum.map(create_n_notebooks(3, context.user1_id), fn user -> Repo.insert(user) end)

    context = Map.put(context, :notebook1_id, notebook1.id)
    context = Map.put(context, :notebook2_id, notebook2.id)
    context = Map.put(context, :private_notebook_id, private_notebook.id)
    {:ok, context}
  end

  defp setup_sub_categories(context) do
    {:ok, %SubCategory{id: sub_cat1_id}} =
      create_sub_category(1, context.notebook1_id) |> Repo.insert()

    {:ok, %SubCategory{id: sub_cat2_id}} =
      create_sub_category(2, context.notebook2_id) |> Repo.insert()

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
    {:ok, %Note{id: note1_id}} = create_note(1, context.topic1_id) |> Repo.insert()
    {:ok, %Note{id: note2_id}} = create_note(2, context.topic2_id) |> Repo.insert()
    context = Map.put(context, :note1_id, note1_id)
    context = Map.put(context, :note2_id, note2_id)
    {:ok, context}
  end

  defp setup_notebook_shareuser(context) do
    {
      :ok,
      read_only_notebook_shareuser
    } =
      Notebooks.share_notebook_with_user(%{
        user_id: context.user2_id,
        notebook_id: context.notebook1_id,
        read_only: true
      })

    {
      :ok,
      write_enabled_notebook_shareuser
    } =
      Notebooks.share_notebook_with_user(%{
        user_id: context.user2_id,
        notebook_id: context.notebook2_id,
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
  # describe "notebook context CRUD functions properly allow a user to" do
    # test "list notebooks", %{
    #   user1_id: user1_id,
    # } do
    #   notebook_list = Notebooks.list_notebooks(%{owner_id: user1_id, limit: 10, offset: 0})
    #   IO.puts("notebook_list")
    #   IO.inspect(notebook_list)
    #   assert [%Notebook{id: id}] = notebook_list
    # end
    
  # end

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

    # test "create a notebook", %{user1_id: user1_id, notebook1_id: notebook1_id} do
    #   assert {:ok, %Notebook{title: title, owner_id: owner_id}} =
    #            Notebooks.create_notebook(%{title: "notebook3", owner_id: user1_id})
    # end

    test "unshared notebooks remain private when listing the user's own notebooks", %{
      user2_id: user2_id,
      private_notebook_id: private_notebook_id
    } do
      {:ok, %Notebook{id: user2_notebook_id}} = create_notebook(10, user2_id) |> Repo.insert()
      notebook_list = Notebooks.list_notebooks(%{owner_id: user2_id, limit: 10, offset: 0})
      assert [%Notebook{id: id}] = notebook_list
      assert id === user2_notebook_id
      assert id !== private_notebook_id
    end
    
    test "unshared notebooks remain private when listing shared notebooks and user's own notebooks don't appear in the output", %{
      user2_id: user2_id,
      private_notebook_id: private_notebook_id
    } do
      {:ok, %Notebook{id: user2_notebook_id}} = create_notebook(10, user2_id) |> Repo.insert()
      shared_notebook_list = Notebooks.list_shared_notebooks(%{user_id: user2_id, limit: 10, offset: 0})
      assert [
        %Notebook{id: notebook1_id, owner_id: owner1_id},
        %Notebook{id: notebook2_id, owner_id: owner2_id}
      ] = shared_notebook_list
      assert owner1_id !== user2_id
      assert owner2_id !== user2_id
      assert notebook1_id !== private_notebook_id and notebook1_id !== user2_notebook_id
      assert notebook2_id !== private_notebook_id and notebook2_id !== user2_notebook_id
    end
    
    test "ensure that a read_only notebook_shareuser can read, but not edit notes in the notebook.",
         %{read_only_notebook_shareuser: read_only_notebook_shareuser, notebook1_id: notebook1_id} do
          IO.puts("read_only_notebook_shareuser")
          IO.inspect(read_only_notebook_shareuser)
      shared_notebook_list = Notebooks.list_shared_notebooks(%{user_id: read_only_notebook_shareuser.user_id, limit: 10, offset: 0})
      assert [
        %Notebook{id: notebook1_id, owner_id: owner1_id, sub_categories: sub_category_id_list},
        %Notebook{id: notebook2_id, owner_id: owner2_id}
      ] = shared_notebook_list
      assert [%SubCategory{id: sub_category_id}] = Notebooks.list_sub_categories(%{sub_category_id_list: sub_category_id_list, limit: 10, offset: 0})
      assert sub_category_id === Enum.at(sub_category_id_list, 0)
    end
  end
end
