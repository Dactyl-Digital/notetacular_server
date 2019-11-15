defmodule Notebooks.Impl do
  @moduledoc """
  Documentation for Notebooks.Impl
  """
  import Ecto.Query
  alias Ecto.Changeset
  alias Dbstore.{Repo, Notebook, SubCategory, Topic, Note, NoteTimer, NotebookShareuser}

  # Status Codes
  @created_code 201
  @bad_request_code 400
  @forbidden_code 403

  # Response Messages
  @signup_success_message "You've successfully signed up!"
  @login_success_message "You've successfully logged in!"
  @something_went_wrong_message "Oops... Something went wrong. Please try again."
  @permission_not_found_message "Permission not found"

  # *************************
  # Notebook Resource Actions
  # *************************
  # TODO: Implement regex check on title
  def create_notebook(%{title: _title} = params) do
    %Notebook{}
    |> Notebook.changeset(params)
    |> Repo.insert()
  end

  # TODO: Need to create a test that ensures a list of sub_category_ids is on
  #       the returned resource.
  def list_notebooks(%{owner_id: owner_id, limit: limit, offset: offset} = params) do
    sub_categories_query = from s in SubCategory, select: s.id
    query =
      from(n in Notebook,
        preload: [sub_categories: ^sub_categories_query],
        where: n.owner_id == ^owner_id,
        order_by: :inserted_at,
        limit: ^limit,
        offset: ^offset,
      )

    # NOTE: This is fucked.
    #       When joining a table and using where
    #       I receive the same resource from the DB
    #       twice in the result array.
    # SOLUTION: Just going to include a tab in the UI
    #           to switch between the user's notebooks
    #           and shared notebooks. And create a separate
    #           function to handle listing the shared notebooks.
    # query =
    #   from(n in Notebook,
    #     join: nsu in "notebook_shareusers",
    #     on: nsu.user_id == ^owner_id,
    #     where: n.owner_id == ^owner_id,
    #   )
    Repo.all(query)
  end
  
  @doc """
   Returns an array of:
  [
    %Dbstore.Notebook{
      __meta__: #Ecto.Schema.Metadata<:loaded, "notebooks">,
      id: 561,
      inserted_at: ~N[2019-11-15 00:20:06],
      owner_id: 491,
      sub_categories: [277],
      title: "notebook1",
      updated_at: ~N[2019-11-15 00:20:06],
      users: #Ecto.Association.NotLoaded<association :users is not loaded>
    },
    %Dbstore.Notebook{
      __meta__: #Ecto.Schema.Metadata<:loaded, "notebooks">,
      id: 562,
      inserted_at: ~N[2019-11-15 00:20:06],
      owner_id: 491,
      sub_categories: [278],
      title: "notebook2",
      updated_at: ~N[2019-11-15 00:20:06],
      users: #Ecto.Association.NotLoaded<association :users is not loaded>
    }
  ]
  
  sub_categories contains a list of sub category ids to facilitate retrieval
  upon clicking on a Notebook in the UI.
  """
  def list_shared_notebooks(%{user_id: user_id, limit: limit, offset: offset} = params) do
    sub_categories_query = from s in SubCategory, select: s.id
    query =
      from(n in Notebook,
        preload: [sub_categories: ^sub_categories_query],
        join: nsu in "notebook_shareusers",
        on: nsu.user_id == ^user_id,
        where: n.id == nsu.notebook_id,
        order_by: [desc: n.inserted_at],
        limit: ^limit,
        offset: ^offset,
      )
      Repo.all(query)
  end

  def update_notebook_title(%{notebook_id: notebook_id} = params) do
    IO.puts("notebook_id in update_notebook_title")
    IO.inspect(notebook_id)

    notebook_id
    |> retrieve_notebook_by_id
    # TODO: Handle update |>
  end

  def delete_notebook(
        %{requesting_user_id: requesting_user_id, notebook_id: notebook_id} = params
      ) do
    case Repo.get(Notebook, notebook_id) do
      %Notebook{owner_id: owner_id} = notebook ->
        verify_owner_of_resource(%{
          requesting_user_id: requesting_user_id,
          owner_id: owner_id,
          success_fn: (fn -> delete_or_transfer_ownership(notebook))
        })

      nil ->
        # TODO: Most ideal error to return?
        # This is the case where the Notebook doesn't exist.
        {:error, "Unauthorized request"}
    end
  end

  def share_notebook_with_user(
        %{user_id: user_id, notebook_id: notebook_id, read_only: read_only} = params
      ) do
    %NotebookShareuser{}
    |> NotebookShareuser.changeset(params)
    |> Repo.insert()
  end

  defp retrieve_notebook_by_id(id), do: Repo.get(Notebook, id)

  defp delete_or_transfer_ownership(notebook) do
    query =
      from(ns in "notebook_shareusers",
        where: ns.notebook_id == ^notebook.id,
        order_by: [desc: ns.inserted_at],
        limit: 1,
      )

    case Repo.all(query) do
      [%NotebookShareuser{user_id: user_id}] = notebook_shareuser ->
        # Update the owner to the first created notebook_shareuser
        notebook
        |> Notebook.changeset(%{owner_id: user_id})
        |> Repo.insert()
        Repo.delete(notebook_shareuser)
        # TODO: see if this is ideal to return
        {:ok, "You've successfully deleted the notebook."}

      # This notebook hasn't been shared w/ any other users
      # so we just delete it.
      nil ->
        Repo.delete(notebook)
        # TODO: see if this is ideal to return
        {:ok, "You've successfully deleted the notebook."}
    end
  end

  # ****************************
  # SubCategory Resource Actions
  # ****************************
  def create_sub_category(params) do
    %SubCategory{}
    |> SubCategory.changeset(params)
    |> Repo.insert()
  end

  @doc """
  Input: [281]  
  
  Output:
  [
    %Dbstore.SubCategory{
      __meta__: #Ecto.Schema.Metadata<:loaded, "sub_categories">,
      id: 281,
      inserted_at: ~N[2019-11-15 00:31:17],
      notebook_id: 576,
      notebooks: #Ecto.Association.NotLoaded<association :notebooks is not loaded>,
      title: "sub_category1",
      topics: [287],
      updated_at: ~N[2019-11-15 00:31:17]
    }
  ]
  
  List of topic ids to facilitate listing a particular sub categories' topics in the UI.
  """
  def list_sub_categories(%{sub_category_id_list: sub_category_id_list, limit: limit, offset: offset} = params) do
    topics_query = from t in Topic, select: t.id
    query = 
      from(
        s in SubCategory,
        preload: [topics: ^topics_query],
        where: s.id in ^sub_category_id_list,
        order_by: [desc: s.inserted_at],
        limit: ^limit,
        offset: ^offset,
      )

    Repo.all(query)
  end

  def update_sub_category_title(sub_category_id) do
    IO.puts("sub_category_id in update_sub_category_title")
    IO.inspect(sub_category_id)
  end

  def delete_sub_category(sub_category_id) do
    IO.puts("sub_category_id in delete_sub_category")
    IO.inspect(sub_category_id)

    Repo.get(SubCategory, sub_category_id)
    |> Repo.delete()
  end

  # **********************
  # Topic Resource Actions
  # **********************
  def create_topic(params) do
    IO.puts("params in create_topic")
    IO.inspect(params)

    %Topic{}
    |> Topic.changeset(params)
    |> Repo.insert()
  end

  def list_topics(%{topic_id_list: topic_id_list, limit: limit, offset: offset} = params) do
    note_query = from n in Note, select: t.id
    query = 
      from(
        t in Topic,
        preload: [notes: ^notes_query],
        where: t.id in ^topic_id_list,
        order_by: [desc: s.inserted_at],
        limit: ^limit,
        offset: ^offset,
      )

    Repo.all(query)
  end
  
  def update_topic_title(topic_id) do
    IO.puts("topic_id in update_topic_title")
    IO.inspect(topic_id)
  end

  def delete_topic(topic_id) do
    IO.puts("topic_id in delete_topic")
    IO.inspect(topic_id)

    Repo.get(Topic, topic_id)
    |> Repo.delete()
  end

  # *********************
  # Note Resource Actions
  # *********************
  def create_note(params) do
    %Note{}
    |> Note.changeset(params)
    |> Repo.insert()
  end

  
  def list_notes(%{note_id_list: note_id_list, limit: limit, offset: offset} = params) do
    query = 
      from(
        n in Note,
        where: n.id in ^note_id_list,
        order_by: [desc: s.inserted_at],
        limit: ^limit,
        offset: ^offset,
      )

    Repo.all(query)
  end

  def update_note_title(note_id) do
    IO.puts("note_id in update_note_title")
    IO.inspect(note_id)
  end

  @doc """
    NOTE: On the client side... The user will have a button
    which will enable a mass update, instead of updating
    the note order every time a note is dragged and dropped.

    [
     %{id: 1, order: 1},
     %{id: 2, order: 3},
     %{id: 3, order: 2}
    ] = note_id_and_order_list
  """
  def update_note_order(note_id_and_order_list) do
    # TODO
  end

  def delete_note(note_id) do
    Repo.get(Note, note_id)
    |> Repo.delete()
  end

  # *****************************
  # Topic & Note Resource Actions
  # *****************************
  def add_tags(:topic, %{topic_id: topic_id, tags: tags}) do
    # TODO: Concatenate tags onto the JSONB array in the DB.
  end

  def add_tags(:note, %{note_id: note_id, tags: tags}) do
    # TODO: Concatenate tags onto the JSONB array in the DB.
  end

  def remove_tags(:topic, %{topic_id: topic_id, tag: tag}) do
    # TODO: Remove single tag from resource's JSONB array in the DB.
  end

  def remove_tags(:note, %{topic_id: topic_id, tag: tag}) do
    # TODO: Remove single tag from resource's JSONB array in the DB.
  end
  
  defp verify_owner_of_resource(%{requesting_user_id: requesting_user_id, owner_id: owner_id, success_fn: success_fn}) do
    if requesting_user_id === owner_id do
      success_fn.()
    else
      {:error, "UNAUTHORIZED_REQUEST"}
    end
  end
end
