defmodule NotebooksTest do
  use ExUnit.Case
  use NotebookBuilders
  doctest Notebooks
  alias Notebooks
  alias Dbstore.{Repo, User, Notebook, NotebookUsershare}
  
  defp setup_users(context) do
    [{:ok, user1}, {:ok, user2}, {:ok, user3}] = Enum.map(create_n_users(3), (fn user -> Repo.insert(user) end))
    context = Map.put(context, :user1_id, user1.id)
    context = Map.put(context, :user2_id, user2.id)
    {:ok, Map.put(context, :user3_id, user3.id)}
  end
  
  defp setup_notebooks(context) do
    [{:ok, notebook1}, {:ok, notebook2}] = Enum.map(create_n_notebooks(2, context.user1_id), (fn user -> Repo.insert(user) end))
    context = Map.put(context, :notebook1_id, notebook1.id)
    IO.puts("notebook1")
    IO.inspect(notebook1)
    {:ok, Map.put(context, :notebook2_id, notebook2.id)}
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

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Dbstore.Repo)
  end
  
  describe "notebook context functions allow a user to" do
    setup [:setup_users, :setup_notebooks]
    
    test "create a notebook", %{user1_id: user1_id, notebook1_id: notebook1_id} do
      assert {:ok, %Notebook{title: title, owner_id: owner_id}} = Notebooks.create_notebook(%{ title: "notebook3", owner_id: user1_id})
    end
    
    test "share a notebook with another user", %{user1_id: user2_id, notebook1_id: notebook1_id} do
      assert {
        :ok,
        %NotebookUsershare{user_id: user_id, notebook_id: notebook_id, read_only: true}
      } = Notebooks.share_notebook_with_user(%{user_id: user2_id, notebook_id: notebook1_id, read_only: true})
    end
  end
end
