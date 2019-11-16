# NOTE: Emulated from Designing Elixir Systems - pg 89 of 218
defmodule NotebookBuilders do
  defmacro __using__(_options) do
    quote do
      alias Notebook
      import NotebookBuilders, only: :functions
    end
  end

  alias Notebook
  alias Dbstore.{Repo, User, Notebook, SubCategory, Topic, Note}

  # ********************
  # User Setup Functions
  # ********************
  def create_user(i) do
    # %User{}
    # |> User.changeset(%{
    #   username: "user#{i}",
    #   credentials: %{
    #     email: "user#{i}@gmail.com",
    #     password: "password#{i}"
    #   },
    #   memberships: %{
    #     subscribed_until: Timex.now() |> Timex.shift(days: 30)
    #   }
    # })
    [
      username: "user#{i}",
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now(),
    ]
  end

  def create_n_users(n), do: Enum.map(1..n, fn i -> create_user(i) end)

  # ************************
  # Notebook Setup Functions
  # ************************
  def create_notebook(i, owner_id) do
    # %Notebook{}
    # |> Notebook.changeset(%{
    #   title: "notebook#{i}",
    #   owner_id: owner_id
    # })
    [
      title: "notebook#{i}",
      owner_id: owner_id,
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now(),
    ]
  end

  def create_n_notebooks(n, owner_id),
    do: Enum.map(1..n, fn i -> create_notebook(i, owner_id) end)

  # ****************************
  # Sub Category Setup Functions
  # ****************************
  def create_sub_category(i, notebook_id) do
    %SubCategory{}
    |> SubCategory.changeset(%{
      title: "sub_category#{i}",
      notebook_id: notebook_id
    })
  end

  def create_n_sub_categories(n, notebook_id),
    do: Enum.map(1..n, fn i -> create_sub_category(i, notebook_id) end)

  def extract_sub_category_ids(list), do: Enum.map(list, fn {:ok, %SubCategory{id: id}} -> id end)

  # *********************
  # Topic Setup Functions
  # *********************
  def create_topic(i, sub_category_id) do
    %Topic{}
    |> Topic.changeset(%{
      title: "topic#{i}",
      sub_category_id: sub_category_id
    })
  end

  # ********************
  # Note Setup Functions
  # ********************
  def create_note(i, topic_id) do
    %Note{}
    |> Note.changeset(%{
      title: "note#{i}",
      topic_id: topic_id,
      order: i,
      content_text: "Random text to test search functionality."
    })
  end
end
