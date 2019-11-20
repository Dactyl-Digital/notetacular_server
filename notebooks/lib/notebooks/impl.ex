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

  # TODO:
  # Implement creating updated_resources table in the DB
  # Every time a notebook_shareuser makes an update, create
  # an updated_resource resource to enable potential rollback.
  # The updated_resource will have a row which
  # contains the old content, and a row for the new changes.
  # Perhaps easiest to implement these as just a JSONB. 
  
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
    from(n in Notebook,
      preload: [sub_categories: ^sub_categories_query],
      where: n.owner_id == ^owner_id,
      order_by: :inserted_at,
      limit: ^limit,
      offset: ^offset,
    ) |> Repo.all

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
    from(n in Notebook,
      preload: [sub_categories: ^sub_categories_query],
      join: nsu in "notebook_shareusers",
      on: nsu.user_id == ^user_id,
      where: n.id == nsu.notebook_id,
      order_by: [desc: n.inserted_at],
      limit: ^limit,
      offset: ^offset,
    ) |> Repo.all
  end

  def update_notebook_title(%{requester_id: requester_id, notebook_id: notebook_id} = params) do
    # TODO
    # notebook_id
    # |> retrieve_notebook_by_id
    # TODO: Handle update |>
    
    # defp check_notebook_access_authorization(%{
    #   requester_id: requester_id,
    #   resource_type: resource_type,
    #   resource_id: resource_id
    # } = params, success_fn, fail_fn) do

    # end
  end

  # THIS: create a fetch_notebook_and_verify_ownership function for everything
  # that happens in the case?
  # Passing in as args:
  # notebook_id
  # verify_owner_of_resource wrapped in a lambda
  def delete_notebook(
        %{requester_id: requester_id, notebook_id: notebook_id} = params
      ) do
    case Repo.get(Notebook, notebook_id) do
      %Notebook{owner_id: owner_id} = notebook ->
        verify_owner_of_resource(%{
          requester_id: requester_id,
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
  # Need to update this to also take requester_id
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
  def create_sub_category(%{
    requester_id: requester_id,
    title: title,
    notebook_id: notebook_id
  } = params) do
    success_fn = (fn -> %SubCategory{} |> SubCategory.changeset(params) |> Repo.insert end)
    fail_fn = (fn notebook_id -> verify_shareduser_of_resource(%{
                operation: :write,
                notebook_id: notebook_id,
                requester_id: requester_id,
                success_fn: success_fn
              }) end)
    check_notebook_access_authorization(%{
      requester_id: requester_id,
      resource_id: notebook_id,
      resource_type: :notebook,
    }, success_fn, fail_fn)
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
  def list_sub_categories(%{
    requester_id: requester_id,
    sub_category_id_list: sub_category_id_list,
    limit: limit,
    offset: offset
  } = params) when length(sub_category_id_list) > 0 do
    success_fn = (fn -> list_sub_categories_query(params) end)
    fail_fn = (fn notebook_id -> verify_shareduser_of_resource(%{
                operation: :read,
                notebook_id: notebook_id,
                requester_id: requester_id,
                success_fn: success_fn
              }) end)
    check_notebook_access_authorization(%{
      requester_id: requester_id,
      resource_id: Enum.at(sub_category_id_list, 0),
      resource_type: :sub_category,
    }, success_fn, fail_fn)
  end
  
  def list_sub_categories(_), do: {:err, "sub_category_id_list must be greater than 0"}
  
  defp list_sub_categories_query(%{sub_category_id_list: sub_category_id_list, limit: limit, offset: offset} = params) do
    topics_query = from t in Topic, select: t.id
    from(
      s in SubCategory,
      preload: [topics: ^topics_query],
      where: s.id in ^sub_category_id_list,
      order_by: [desc: s.inserted_at],
      limit: ^limit,
      offset: ^offset,
    ) |> Repo.all
  end

  def update_sub_category_title(sub_category_id) do
    # TODO:
    # requester_id
  end

  def delete_sub_category(%{
    requester_id: requester_id,
    sub_category_id: sub_category_id,
  } = params) do
    success_fn = (fn -> Repo.get(SubCategory, sub_category_id) |> Repo.delete end)
    fail_fn = (fn notebook_id -> verify_shareduser_of_resource(%{
                operation: :write,
                notebook_id: notebook_id,
                requester_id: requester_id,
                success_fn: success_fn
              }) end)
    check_notebook_access_authorization(%{
      requester_id: requester_id,
      resource_id: sub_category_id,
      resource_type: :sub_category,
    }, success_fn, fail_fn)
  end

  # **********************
  # Topic Resource Actions
  # **********************
  def create_topic(%{
    requester_id: requester_id,
    sub_category_id: sub_category_id,
    title: title
  } = params) do
    success_fn = (fn -> %Topic{} |> Topic.changeset(params) |> Repo.insert end)
    fail_fn = (fn notebook_id -> verify_shareduser_of_resource(%{
                operation: :read,
                notebook_id: notebook_id,
                requester_id: requester_id,
                success_fn: success_fn
              }) end)
    check_notebook_access_authorization(%{
      requester_id: requester_id,
      resource_id: sub_category_id,
      resource_type: :sub_category,
    }, success_fn, fail_fn)
  end

  def list_topics(%{
    requester_id: requester_id,
    topic_id_list: topic_id_list,
    limit: limit,
    offset: offset
  } = params) when length(topic_id_list) > 0 do
    success_fn = (fn -> list_topics_query(params) end)
    fail_fn = (fn notebook_id -> verify_shareduser_of_resource(%{
                operation: :read,
                notebook_id: notebook_id,
                requester_id: requester_id,
                success_fn: success_fn
              }) end)
    check_notebook_access_authorization(%{
      requester_id: requester_id,
      resource_id: Enum.at(topic_id_list, 0),
      resource_type: :topic,
    }, success_fn, fail_fn)
  end
  
  def list_topics(_), do: {:err, "topic_id_list must be greater than 0"}
  
  defp list_topics_query(%{topic_id_list: topic_id_list, limit: limit, offset: offset} = params) do
    notes_query = from n in Note, select: n.id
    from(
      t in Topic,
      preload: [notes: ^notes_query],
      where: t.id in ^topic_id_list,
      order_by: [desc: t.inserted_at],
      limit: ^limit,
      offset: ^offset,
    ) |> Repo.all
  end
  
  # TODO: Still on the fence of how I want to handle these update functions...
  def update_topic_title(%{requester_id: requester_id, title: title} = params) do
    # TODO:
  end
  
  def delete_topic(%{
    requester_id: requester_id,
    topic_id: topic_id,
  } = params) do
    success_fn = (fn -> Repo.get(Topic, topic_id) |> Repo.delete end)
    fail_fn = (fn notebook_id -> verify_shareduser_of_resource(%{
                operation: :write,
                notebook_id: notebook_id,
                requester_id: requester_id,
                success_fn: success_fn
              }) end)
    check_notebook_access_authorization(%{
      requester_id: requester_id,
      resource_id: topic_id,
      resource_type: :topic,
    }, success_fn, fail_fn)
  end

  # *********************
  # Note Resource Actions
  # *********************
  def create_note(%{
    requester_id: requester_id,
    title: title,
    order: order,
    topic_id: topic_id
  } = params) do
    success_fn = (fn -> %Note{} |> Note.changeset(params) |> Repo.insert end)
    fail_fn = (fn notebook_id -> verify_shareduser_of_resource(%{
                operation: :write,
                notebook_id: notebook_id,
                requester_id: requester_id,
                success_fn: success_fn
              }) end)
    check_notebook_access_authorization(%{
      requester_id: requester_id,
      resource_id: topic_id,
      resource_type: :topic,
    }, success_fn, fail_fn)
  end
  
  def retrieve_note(%{requester_id: requester_id, note_id: note_id} = params) do
    success_fn = (fn -> Repo.get(Note, note_id) end)
    fail_fn = (fn notebook_id -> verify_shareduser_of_resource(%{
                operation: :read,
                notebook_id: notebook_id,
                requester_id: requester_id,
                success_fn: success_fn
              }) end)
    check_notebook_access_authorization(%{
      requester_id: requester_id,
      resource_id: note_id,
      resource_type: :note,
    }, success_fn, fail_fn)
  end
  
  def list_notes(%{
    requester_id: requester_id,
    note_id_list: note_id_list,
    limit: limit,
    offset: offset
  } = params) when length(note_id_list) > 0 do
    success_fn = (fn -> list_notes_query(params) end)
    fail_fn = (fn notebook_id -> verify_shareduser_of_resource(%{
                operation: :read,
                notebook_id: notebook_id,
                requester_id: requester_id,
                success_fn: success_fn
              }) end)
    check_notebook_access_authorization(%{
      requester_id: requester_id,
      resource_id: Enum.at(note_id_list, 0),
      resource_type: :note,
    }, success_fn, fail_fn)
  end
  
  def list_notes(_params), do: {:err, "note_id_list must be greater than 0"}
  
  defp list_notes_query(%{note_id_list: note_id_list, limit: limit, offset: offset} = params) do
    from(
      n in Note,
      where: n.id in ^note_id_list,
      order_by: [desc: n.inserted_at],
      limit: ^limit,
      offset: ^offset,
    ) |> Repo.all
  end

  def update_note_title(%{requester_id: requester_id, note_id: note_id} = params) do
    # TODO
  end
  
  def update_note_content(
    %{requester_id: requester_id,
      note_id: note_id,
      content_markdown: content_markdown,
      content_text: content_text
    } = params) do
      success_fn = (fn -> retrieve_and_update_note_content(params) end)
      fail_fn = (fn notebook_id -> verify_shareduser_of_resource(%{
                  operation: :write,
                  notebook_id: notebook_id,
                  requester_id: requester_id,
                  success_fn: success_fn
                }) end)
      check_notebook_access_authorization(%{
        requester_id: requester_id,
        resource_id: note_id,
        resource_type: :note,
      }, success_fn, fail_fn)
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
  
  def delete_note(%{
    requester_id: requester_id,
    note_id: note_id,
  } = params) do
    success_fn = (fn -> Repo.get(Note, note_id) |> Repo.delete end)
    fail_fn = (fn notebook_id -> verify_shareduser_of_resource(%{
                operation: :write,
                notebook_id: notebook_id,
                requester_id: requester_id,
                success_fn: success_fn
              }) end)
    check_notebook_access_authorization(%{
      requester_id: requester_id,
      resource_id: note_id,
      resource_type: :note,
    }, success_fn, fail_fn)
  end
  
  defp retrieve_and_update_note_content(%{note_id: note_id, content_markdown: content_markdown, content_text: content_text} = params) do
    # TODO: Add updated_at: DateTime.utc_now() // Need to require DateTime in this module
    update_query = from(n in Note, where: n.id == ^note_id, update: [set: [content_markdown: ^content_markdown, content_text: ^content_text]])
    case Repo.update_all(update_query, []) do
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
  # TODO: Will I lowercase the user inputted tag strings
  #       before saving them to the DB... and then Capitalize
  #       the first letter of every word when displaying them?
  # Or perhaps this is a non concern....
  @doc """
    Success case:
    {:ok, struct}
    
    Error case:
    {:error, changeset} // W/ validation/contraint errors.
  """
  def add_tags(:topic, %{topic_id: topic_id, tags: tags} = params) do
    topic = Repo.get(Topic, topic_id)
    set = create_tag_mapset(Enum.concat(topic.tags, tags))
    Topic.add_tags_changeset(topic, %{tags: MapSet.to_list(set)}) |> Repo.update
  end

  def add_tags(:note, %{note_id: note_id, tags: tags}) do
    note = Repo.get(Note, note_id)
    set = create_tag_mapset(Enum.concat(note.tags, tags))
    Note.add_tags_changeset(note, %{tags: MapSet.to_list(set)}) |> Repo.update
  end

  def remove_tags(:topic, %{topic_id: topic_id, tag: tag}) do
    topic = Repo.get(Topic, topic_id)
    set = MapSet.new(topic.tags)
    case MapSet.member?(set, tag) do
      true ->
        set = MapSet.delete(set, tag)
        Topic.add_tags_changeset(topic, %{tags: MapSet.to_list(set)}) |> Repo.update
      false ->
        {:err, "Tag is not in the list of tags."}
    end 
  end

  def remove_tags(:note, %{note_id: note_id, tag: tag}) do
    note = Repo.get(Note, note_id)
    set = MapSet.new(note.tags)
    case MapSet.member?(set, tag) do
      true ->
        set = MapSet.delete(set, tag)
        Note.add_tags_changeset(note, %{tags: MapSet.to_list(set)}) |> Repo.update
      false ->
        {:err, "Tag is not in the list of tags."}
    end 
  end
  
  defp create_tag_mapset(tags) do
    set = Enum.reduce(tags, MapSet.new(), fn tag, acc ->
      acc = MapSet.put(acc, tag)
    end)
  end
  
  # ****************************************************
  # Authorization Checks to Perform Actions on Resources
  # ****************************************************
  defp verify_owner_of_resource(%{requester_id: requester_id, owner_id: owner_id, success_fn: success_fn, fail_fn: fail_fn}) do
    if requester_id === owner_id do
      success_fn.()
    else
      fail_fn.()
    end
  end
  
  defp retrieve_notebook_shareuser(%{notebook_id: notebook_id, requester_id: requester_id}) do
      from(ns in NotebookShareuser,
        where: ns.notebook_id == ^notebook_id and ns.user_id == ^requester_id
      )
      |> Repo.all
  end
  
  defp verify_shareduser_of_resource(%{
      operation: :write,
      notebook_id: notebook_id, 
      requester_id: requester_id,
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
      requester_id: requester_id,
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
  
  defp check_notebook_access_authorization(%{
    requester_id: requester_id,
    resource_type: resource_type,
    resource_id: resource_id
  } = params, success_fn, fail_fn) do
    case delegate_notebook_resource_retrieval(resource_type, resource_id) do
      [%{notebook_id: notebook_id, owner_id: owner_id}] ->
        verify_owner_of_resource(%{
          requester_id: requester_id,
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
  
  defp delegate_notebook_resource_retrieval(:sub_category, resource_id) do
    retrieve_sub_categories_associated_notebook(%{note_id: resource_id})
  end
  
  defp delegate_notebook_resource_retrieval(:topic, resource_id) do
    retrieve_topics_associated_notebook(%{topic_id: resource_id})
  end
  
  defp delegate_notebook_resource_retrieval(:note, resource_id) do
    retrieve_notes_associated_notebook(%{note_id: resource_id})
  end
  
  defp delegate_notebook_resource_retrieval(:note_timer, resource_id) do
    retrieve_note_timers_associated_notebook(%{note_id: resource_id})
  end
  
  defp delegate_notebook_resource_retrieval(:notebook, resource_id) do
    retrieve_associated_notebook(%{notebook_id: resource_id})
  end
  
  #################################
  # Accessor Functions to Retrieve
  # a Resource's Associated Notebook
  #################################
  def retrieve_note_timers_associated_notebook(%{note_timers_id: note_timers_id}) do
    from(
      nt in "note_timerss",
      where: nt.id == ^note_timers_id,
      join: n in "notes",
      on: nt.note_id == n.id,
      join: t in "topics",
      on: n.topic_id == t.id,
      join: sc in "sub_categories",
      on: t.sub_category_id == sc.id,
      join: nb in "notebooks",
      on: sc.notebook_id == nb.id,
      select: %{notebook_id: nb.id, owner_id: nb.owner_id}
    ) |> Repo.all
  end
  
  def retrieve_notes_associated_notebook(%{note_id: note_id}) do
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
    ) |> Repo.all
  end
  
  def retrieve_topics_associated_notebook(%{topic_id: topic_id}) do
    from(
      t in "topics",
      where: t.id == ^topic_id,
      join: sc in "sub_categories",
      on: t.sub_category_id == sc.id,
      join: nb in "notebooks",
      on: sc.notebook_id == nb.id,
      select: %{notebook_id: nb.id, owner_id: nb.owner_id}
    ) |> Repo.all
  end
  
  def retrieve_sub_categories_associated_notebook(%{sub_category_id: sub_category_id}) do
    from(
      sc in "sub_categories",
      where: sc.id == ^sub_category_id,
      join: nb in "notebooks",
      on: sc.notebook_id == nb.id,
      select: %{notebook_id: nb.id, owner_id: nb.owner_id}
    ) |> Repo.all
  end
  
  def retrieve_associated_notebook(%{notebook_id: notebook_id}) do
    from(
      nb in "notebooks",
      where: nb.id == ^notebook_id,
      select: %{notebook_id: nb.id, owner_id: nb.owner_id}
    ) |> Repo.all
  end
end
