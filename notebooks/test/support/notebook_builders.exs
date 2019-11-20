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
  def create_notebook_data(i, owner_id) do
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
    do: Enum.map(1..n, fn i -> create_notebook_data(i, owner_id) end)

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
  
  def create_sub_category_data(i, notebook_id) do
    [
      title: "sub_category#{i}",
      notebook_id: notebook_id,
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now(),
    ]
  end

  def create_n_sub_categories(n, notebook_id),
    do: Enum.map(1..n, fn i -> create_sub_category_data(i, notebook_id) end)

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
  
  def create_topic_data(i, sub_category_id) do
    [
      title: "topic#{i}",
      sub_category_id: sub_category_id,
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now(),
    ]
  end
  
  def create_n_topics(n, sub_category_id),
    do: Enum.map(1..n, fn i -> create_topic_data(i, sub_category_id) end)

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
  
  def create_note_data(i, topic_id) do
    [
      title: "note#{i}",
      order: i,
      topic_id: topic_id,
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now(),
    ]
  end
   
  def create_n_notes(n, topic_id),
    do: Enum.map(1..n, fn i -> create_note_data(i, topic_id) end)
    
  # ********************
  # NoteTimer Setup Functions
  # ********************
  # def create_note_timer_data(i, note_id) do
  #   [
  #     timer: :timer.minutes(1),
  #     timer_count: 1,
  #     inserted_at: DateTime.utc_now(),
  #     updated_at: DateTime.utc_now(),
  #   ]
  # end
    
  # def create_n_note_timers(1, note_id),
  #   do: Enum.map(1..n, fn i -> create_note_data(i, note_id) end)
end
