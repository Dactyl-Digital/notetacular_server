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
  def create_notebook(%{owner_id: owner_id, title: _title} = params) do
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

  def update_notebook_title(%{requesting_user_id: requesting_user_id, notebook_id: notebook_id} = params) do
    # TODO
    # notebook_id
    # |> retrieve_notebook_by_id
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
          success_fn: (fn -> delete_or_transfer_ownership(notebook) end),
          fail_fn: (fn -> {:error, "UNAUTHORIZED_REQUEST"} end)
        })

      nil ->
        # TODO: Most ideal error to return?
        # This is the case where the Notebook doesn't exist.
        {:error, "UNAUTHORIZED_REQUEST"}
    end
  end

  # TODO:
  # Need to update this to also take requesting_user_id
  # and change user_id to be shareuser_id
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
  # TODO:
  # add requesrting_user_id authorization check
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
    # TODO:
    # requesting_user_id
  end

  def delete_sub_category(sub_category_id) do
    # TODO:
    # requesting_user_id
    Repo.get(SubCategory, sub_category_id)
    |> Repo.delete()
  end

  # **********************
  # Topic Resource Actions
  # **********************
  def create_topic(params) do
    # TODO:
    # requesting_user_id
    %Topic{}
    |> Topic.changeset(params)
    |> Repo.insert()
  end

  def list_topics(%{topic_id_list: topic_id_list, limit: limit, offset: offset} = params) do
    notes_query = from n in Note, select: n.id
    query = 
      from(
        t in Topic,
        preload: [notes: ^notes_query],
        where: t.id in ^topic_id_list,
        order_by: [desc: t.inserted_at],
        limit: ^limit,
        offset: ^offset,
      )

    Repo.all(query)
  end
  
  def update_topic_title(%{requesting_user_id: requesting_user_id, title: title} = params) do
    # TODO:
  end

  def delete_topic(%{requesting_user_id: requesting_user_id, topic_id: topic_id} = params) do
    # TODO: 
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
  
  def retrieve_note(%{requesting_user_id: requesting_user_id, note_id: note_id} = params) do
    success_fn = (fn -> Repo.get(Note, note_id) end)
    fail_fn = (fn notebook_id -> verify_shareduser_of_resource(%{
                operation: :read,
                notebook_id: notebook_id,
                requesting_user_id: requesting_user_id,
                success_fn: success_fn
              }) end)
    check_notebook_access_authorization(params, success_fn, fail_fn)
  end
  
  def list_notes(%{note_id_list: note_id_list, limit: limit, offset: offset} = params) do
    query = 
      from(
        n in Note,
        where: n.id in ^note_id_list,
        order_by: [desc: n.inserted_at],
        limit: ^limit,
        offset: ^offset,
      )

    Repo.all(query)
  end

  def update_note_title(%{requesting_user_id: requesting_user_id, note_id: note_id} = params) do
    # TODO
  end
  
  defp check_notebook_access_authorization(%{
      requesting_user_id: requesting_user_id,
      note_id: note_id
    } = params, success_fn, fail_fn) do
    case retrieve_notes_associated_notebook(%{note_id: note_id}) do
      [%{notebook_id: notebook_id, owner_id: owner_id}] ->
        verify_owner_of_resource(%{
          requesting_user_id: requesting_user_id,
          owner_id: owner_id,
          success_fn: success_fn,
          fail_fn: (fn -> fail_fn.(notebook_id) end)
        })

      nil ->
        # TODO: Most ideal error to return?
        # This is the case where the Notebook doesn't exist.
        {:error, "UNAUTHORIZED_REQUEST"}
    end
  end
  
  def update_note_content(
    %{requesting_user_id: requesting_user_id,
      note_id: note_id,
      content_markdown: content_markdown,
      content_text: content_text
    } = params) do
      success_fn = (fn -> retrieve_and_update_note_content(params) end)
      fail_fn = (fn notebook_id -> verify_shareduser_of_resource(
                %{
                  operation: :write,
                  notebook_id: notebook_id,
                  requesting_user_id: requesting_user_id,
                  success_fn: success_fn
                }) end)
      check_notebook_access_authorization(params, success_fn, fail_fn)
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

  def delete_note(%{requesting_user_id: requesting_user_id, note_id: note_id} = params) do
    # TODO
    Repo.get(Note, note_id)
    |> Repo.delete()
  end
  
  def retrieve_notes_associated_notebook(%{note_id: note_id}) do
    query =
      from(
        n in "notes",
        where: n.id == ^note_id,
        join: t in "topics",
        on: n.topic_id == t.id,
        join: sc in "sub_categories",
        on: t.sub_category_id == sc.id,
        join: nb in "notebooks",
        on: sc.notebook_id == nb.id,
        select: %{notebook_id: nb.id, owner_id: nb.owner_id}
      )
      
    Repo.all(query)
  end
  
  defp retrieve_and_update_note_content(%{note_id: note_id, content_markdown: content_markdown, content_text: content_text} = params) do
    # TODO: Add updated_at: DateTime.utc_now() // Need to require DateTime in this module
    update_query = from(n in Note, where: n.id == ^note_id, update: [set: [content_markdown: ^content_markdown, content_text: ^content_text]])
    case Repo.update_all(update_query, []) do
      # This is the success case...
      {1, nil} ->
        {:ok, "Successfully updated the note!"}
        
      {_, nil} ->
        {:err, "Unable to fetch note."}
        
      _ ->
        {:err, "Oops, something went wrong."}
    end
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
  
  # ****************************************************
  # Authorization Checks to Perform Actions on Resources
  # ****************************************************
  defp verify_owner_of_resource(%{requesting_user_id: requesting_user_id, owner_id: owner_id, success_fn: success_fn, fail_fn: fail_fn}) do
    if requesting_user_id === owner_id do
      success_fn.()
    else
      fail_fn.()
    end
  end
  
  defp retrieve_notebook_shareuser(%{notebook_id: notebook_id, requesting_user_id: requesting_user_id}) do
      from(ns in NotebookShareuser,
        where: ns.notebook_id == ^notebook_id and ns.user_id == ^requesting_user_id
      )
      |> Repo.all
  end
  
  defp verify_shareduser_of_resource(%{
      operation: :write,
      notebook_id: notebook_id, 
      requesting_user_id: requesting_user_id,
      success_fn: success_fn
    } = params) do
    case retrieve_notebook_shareuser(params) do
      [%NotebookShareuser{user_id: user_id, read_only: false}] = notebook_shareuser ->
        success_fn.()
      [%NotebookShareuser{user_id: user_id, read_only: true}] = notebook_shareuser ->
        {:err, "UNAUTHORIZED_REQUEST"}
      nil ->
        {:err, "UNAUTHORIZED_REQUEST"}
      _ ->
        {:err, "Oops... Something went wrong."}
    end
  end
  
  defp verify_shareduser_of_resource(%{
      operation: :read,
      notebook_id: notebook_id,
      requesting_user_id: requesting_user_id,
      success_fn: success_fn
    } = params) do
    case retrieve_notebook_shareuser(params) do
      [%NotebookShareuser{}] = notebook_shareuser ->
        success_fn.()
      nil ->
        {:err, "UNAUTHORIZED_REQUEST"}
      _ ->
        {:err, "Oops... Something went wrong."}
    end
  end
end
