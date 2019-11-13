# NOTE: Emulated from Designing Elixir Systems - pg 89 of 218
defmodule NotebookBuilders do
  defmacro __using__(_options) do
    quote do
      alias Notebook
      import NotebookBuilders, only: :functions
    end
  end
  
  alias Notebook
  alias Dbstore.{Repo, User, Notebook}
    
  # ************************
  # User Setup Functions
  # ************************
  def create_user(i) do
    %User{}
    |> User.changeset(%{
      username: "user#{i}",
      credentials: %{
        email: "user#{i}@gmail.com",
        password: "password#{i}"
      },
      memberships: %{
        subscribed_until: Timex.now() |> Timex.shift(days: 30)
      }
    })
  end
  
  def create_n_users(n), do: Enum.map((1..n), fn i -> create_user(i) end)
  
  # ************************
  # Notebook Setup Functions
  # ************************
  def create_notebook(i, owner_id) do
    %Notebook{}
    |> Notebook.changeset(%{
      title: "notebook#{i}",
      owner_id: owner_id
    })
  end
  
  def create_n_notebooks(n, owner_id), do: Enum.map((1..n), fn i -> create_notebook(i, owner_id) end)
end