defmodule Notebooks.Impl do
  @moduledoc """
  Documentation for Notebooks.Impl
  """
  import Ecto.Query
  alias Ecto.Changeset
  alias Dbstore.{Repo, Helpers, Notebook, SubCategory, Topic, Note, NoteTimer, NotebookShareuser}

  @valid_title_regex ~r/[A-Za-z0-9_-]+/
  @valid_tag_regex ~r/[A-Za-z0-9_-]+/

  # Status Codes
  @created_code 201
  @bad_request_code 400
  @forbidden_code 403

  # Response Messages
  @signup_success_message "You've successfully signed up!"
  @login_success_message "You've successfully logged in!"
  @something_went_wrong_message "Oops... Something went wrong. Please try again."
  @permission_not_found_message "Permission not found"

  @invalid_title_error_msg "title is invalid."
  @title_length_error_msg "must be between 4 and 40 characters."
  @title_length_min_error_msg "must be greater than 4 characters."
  @title_length_max_error_msg "must be less than 40 characters."
  @tag_length_min_error_msg "must be greater than 3 characters."
  @tag_length_max_error_msg "must be less than 20 characters."
  #  (After the core feature set has completely
  # been implemented, then I can add the notebook_shareuser
  # functionality.
  # Otherwise, it's not an ideal time to implement this feature
  # until the above is taken care of.):
  # Implement creating updated_resources table in the DB
  # Every time a notebook_shareuser makes an update, create
  # an updated_resource resource to enable potential rollback.
  # The updated_resource will have a row which
  # contains the old content, and a row for the new changes.
  # Perhaps easiest to implement these as just a JSONB.

  #########################
  # Validation Functions
  #########################
  def validate_length_between(str, min, max, msgFn) do
    satisfies_min? = String.length(str) >= min
    satisfies_max? = String.length(str) <= max

    case satisfies_min? && satisfies_max? do
      true ->
        true

      false ->
        msgFn.(satisfies_min?, satisfies_max?)
    end
  end

  def validate_user_input(field, value) do
    with trimmed_str <- String.trim(value),
         true <-
           validate_length_between(trimmed_str, 4, 40, fn min?, max? ->
            title_length_error_message(min?, max?)
           end),
         true <- String.match?(trimmed_str, @valid_title_regex) do
      true
    else
      @title_length_min_error_msg ->
        %{field: String.downcase(field), message: "#{field} #{@title_length_min_error_msg}"}

      @title_length_max_error_msg ->
        %{field: String.downcase(field), message: "#{field} #{@title_length_max_error_msg}"}

      false ->
        %{field: String.downcase(field), message: "#{field} #{@invalid_error_msg}"}
    end
  end

  def validate_user_input(field, value, position) do
    with trimmed_str <- String.trim(value),
         true <-
           validate_length_between(trimmed_str, 3, 20, fn min?, max? ->
            tag_length_error_message(min?, max?)
           end),
         true <- String.match?(trimmed_str, @valid_tag_regex) do
      true
    else
      @title_length_min_error_msg ->
        %{field: String.downcase(field), message: "#{field} #{@tag_length_min_error_msg}", position: position}

      @title_length_max_error_msg ->
        %{field: String.downcase(field), message: "#{field} #{@tag_length_max_error_msg}", position: position}

      false ->
        %{field: String.downcase(field), message: "#{field} #{@invalid_error_msg}", position: position}
    end
  end

  defp title_length_error_message(false, true), do: @title_length_min_error_msg

  defp title_length_error_message(true, false),
    do: @title_length_max_error_msg

    defp tag_length_error_message(false, true), do: @tag_length_min_error_msg

  defp tag_length_error_message(true, false),
    do: @tag_length_max_error_msg

  ##########################
  # DOMAIN FUNCTIONS
  ##########################

  @doc """
  If the list received is empty.
  Then all validations were performed successfully.
  """
  defp create_or_fail([], handle_create_fn), do: handle_create_fn.()
  defp create_or_fail(errors, _), do: {:error, errors}

  # *************************
  # Notebook Resource Actions
  # *************************
  def create_notebook(%{owner_id: owner_id, title: title} = params) do
    handle_create_fn = (fn ->
      %Notebook{}
      |> Notebook.changeset(params)
      |> Repo.insert()
      |> Helpers.handle_creation_result()
    end)

    [["Title", title]]
    |> Enum.map(fn [key, value] -> validate_user_input(key, value) end)
    |> Enum.filter(fn result -> result !== true end)
    |> create_or_fail(handle_create_fn)
  end

  @doc """
  Had to set up this function to facilitate a user navigating directly to the sub categories page of a particular notebook...
  Also, need to account for the listOffset here, as the entirety of some Sub Categories are being retrieved.

  Example of a successful result:
  {:ok,
 %{
   noteboook: %Dbstore.Notebook{
     __meta__: #Ecto.Schema.Metadata<:loaded, "notebooks">,
     id: 2,
     inserted_at: ~N[2019-12-21 16:40:01],
     owner_id: 2,
     sub_categories: [2, 3],
     title: "Data Structures And Algorithms",
     updated_at: ~N[2019-12-21 16:40:01],
     users: #Ecto.Association.NotLoaded<association :users is not loaded>
   },
   sub_categories: %{
     sub_categories: [
       %Dbstore.SubCategory{
         __meta__: #Ecto.Schema.Metadata<:loaded, "sub_categories">,
         id: 3,
         inserted_at: ~N[2019-12-22 03:12:01],
         notebook_id: 2,
         notebooks: #Ecto.Association.NotLoaded<association :notebooks is not loaded>,
         title: "Functional DS&Algs in Scala",
         topics: [],
         updated_at: ~N[2019-12-22 03:12:01]
       },
       %Dbstore.SubCategory{
         __meta__: #Ecto.Schema.Metadata<:loaded, "sub_categories">,
         id: 2,
         inserted_at: ~N[2019-12-21 16:40:08],
         notebook_id: 2,
         notebooks: #Ecto.Association.NotLoaded<association :notebooks is not loaded>,
         title: "Leetcode",
         topics: [3],
         updated_at: ~N[2019-12-21 16:40:08]
       }
     ]
   }
 }}
  """
  def retrieve_notebook_with_sub_categories(%{owner_id: owner_id, notebook_id: notebook_id, limit: limit, offset: offset}) do
    sub_categories_query = from s in SubCategory, select: s.id, order_by: s.updated_at
    notebook_query = from(n in Notebook,
      preload: [sub_categories: ^sub_categories_query],
      where: n.owner_id == ^owner_id and n.id == ^notebook_id,
    )

    with [%Notebook{sub_categories: sub_categories} = notebook] <- notebook_query |> Repo.all,
          {:ok, sub_categories} <- retrieve_notebooks_associated_sub_categories(%{sub_categories: sub_categories, limit: limit, offset: offset})
      do
        {:ok, %{notebook: notebook, sub_categories: sub_categories}}
      else
      _ ->
        {:error, "Oops... Something went wrong."}
    end
  end

  defp retrieve_notebooks_associated_sub_categories(%{sub_categories: sub_categories, limit: limit, offset: offset}) do
    # Email yourself this so you remember.
    # %{sub_category_ids: sub_category_ids, list_offset: list_offset}
    #   = Enum.reduce_while(sub_categories, %{sub_category_ids: [], list_offset: 0}, fn x, acc ->
    #       if x !== sub_category_id,
    #       do: {:cont, %{sub_category_ids: [x | acc.sub_category_ids], list_offset: acc.list_offset + 1}},
    #       else: {:halt, %{sub_category_ids: [x | acc.sub_category_ids], list_offset: acc.list_offset + 1}}
    #     end)
    case list_sub_categories_query(%{sub_category_id_list: sub_categories, limit: limit, offset: offset}) do
      [%SubCategory{} | _xs] = sub_categories ->
        {:ok, sub_categories}

      _ ->
        {:error, "Oops... Something went wrong."}
    end
  end

  # TODO: Need to create a test that ensures a list of sub_category_ids is on
  #       the returned resource.
  @doc """
    Just returns a list of notebooks, i.e.:
    [%Notebook{}, %Notebook{}]
  """
  def list_notebooks(%{owner_id: owner_id, limit: limit, offset: offset} = params) do
    sub_categories_query = from s in SubCategory, select: s.id, order_by: s.updated_at
    # NOTE: This order_by: n.updated_at does indeed return older notebooks towards the bottom of the list.
    # But is that the case for the sub_category_id_list that is returned? I think that's where I had the problem.
    from(n in Notebook,
      preload: [sub_categories: ^sub_categories_query],
      where: n.owner_id == ^owner_id,
      order_by: n.updated_at,
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
    sub_categories_query = from s in SubCategory, select: s.id, order_by: [desc: s.updated_at]
    from(n in Notebook,
      preload: [sub_categories: ^sub_categories_query],
      join: nsu in "notebook_shareusers",
      on: nsu.user_id == ^user_id,
      where: n.id == nsu.notebook_id,
      order_by: [desc: n.updated_at],
      limit: ^limit,
      offset: ^offset,
    ) |> Repo.all
  end

  def update_notebook_title(%{requester_id: requester_id, notebook_id: notebook_id} = params) do
    ""
    # TODO
    # notebook_id
    # |> retrieve_notebook_by_id

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
  def delete_notebook(%{
    requester_id: requester_id,
    notebook_id: notebook_id
  } = params) do
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
  def share_notebook_with_user(%{
    user_id: user_id,
    notebook_id: notebook_id,
    read_only: read_only
  } = params) do
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
        {:ok, "You've successfully deleted the notebook."}

      # This notebook hasn't been shared w/ any other users
      # so we just delete it.
      nil ->
        Repo.delete(notebook)
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
    handle_create_fn = (fn ->
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
    end)

    [["Title", title]]
    |> Enum.map(fn [key, value] -> validate_user_input(key, value) end)
    |> Enum.filter(fn result -> result !== true end)
    |> create_or_fail(handle_create_fn)
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

  # NOTE: Wpould need to pattern match on all the possible unprovided values in order to supply an appropriate response...
  # More of a consideration if I want a really robust program/creating a opensource library.
  def list_sub_categories(%{sub_category_id_list: _, limit: _, offset: _}), do: {:error, "You must provide a requester_id"}
  def list_sub_categories(_), do: {:error, "sub_category_id_list must be greater than 0"}

  defp list_sub_categories_query(%{sub_category_id_list: sub_category_id_list, limit: limit, offset: offset} = params) do
    topics_query = from t in Topic, select: t.id, order_by: [desc: t.updated_at]
    from(
      s in SubCategory,
      preload: [topics: ^topics_query],
      where: s.id in ^sub_category_id_list,
      order_by: [desc: s.updated_at],
      limit: ^limit,
      offset: ^offset,
    ) |> Repo.all
  end

  @doc """
  Had to set up this function to facilitate a user navigating directly to the topics page of a particular notebook...
  Also, need to account for the listOffset here, as the entirety of some Topics are being retrieved.

  Example of a successful result:
  {:ok,
  %{
    sub_category: %Dbstore.SubCategory{
      __meta__: #Ecto.Schema.Metadata<:loaded, "sub_categories">,
      id: 2,
      inserted_at: ~N[2019-12-21 16:40:08],
      notebook_id: 2,
      notebooks: #Ecto.Association.NotLoaded<association :notebooks is not loaded>,
      title: "Leetcode",
      topics: [3],
      updated_at: ~N[2019-12-21 16:40:08]
    },
    topics: [
      %Dbstore.Topic{
        __meta__: #Ecto.Schema.Metadata<:loaded, "topics">,
        id: 3,
        inserted_at: ~N[2019-12-21 16:40:18],
        notes: [5],
        sub_categories: #Ecto.Association.NotLoaded<association :sub_categories is not loaded>,
        sub_category_id: 2,
        tags: [],
        title: "Easy Problems",
        updated_at: ~N[2019-12-21 16:40:18]
      }
    ]
  }}
  """
  def retrieve_sub_category_with_topics(%{owner_id: owner_id, sub_category_id: sub_category_id, limit: limit, offset: offset}) do
    topics_query = from t in Topic, select: t.id, order_by: t.updated_at
    sub_category_query = from(s in SubCategory,
      preload: [topics: ^topics_query],
      # NOTE: Needs to be notebook.owner_id
      # I could swap this out on the clientside so that
      # it sends the parent notebookId of the subCategory
      # and then rewrite the query to ensure it's truly authorized for the user...
      # But I'll skip that for now as it isn't pertinent.
      # s.owner_id == ^owner_id and
      where: s.id == ^sub_category_id,
    )

    with [%SubCategory{topics: topics} = sub_category] <- sub_category_query |> Repo.all,
          {:ok, topics} <- retrieve_sub_category_associated_topics(%{topics: topics, limit: limit, offset: offset})
      do
        {:ok, %{sub_category: sub_category, topics: topics}}
      else
      _ ->
        {:error, "Oops... Something went wrong."}
    end
  end

  defp retrieve_sub_category_associated_topics(%{topics: topics, limit: limit, offset: offset}) do
    case list_topics_query(%{topic_id_list: topics, limit: limit, offset: offset}) do
      [%Topic{} | _xs] = topics ->
        {:ok, topics}

      _ ->
        {:error, "Oops... Something went wrong."}
    end
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
    handle_create_fn = (fn ->
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
    end)

    [["Title", title]]
    |> Enum.map(fn [key, value] -> validate_user_input(key, value) end)
    |> Enum.filter(fn result -> result !== true end)
    |> create_or_fail(handle_create_fn)
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

  def list_topics(_), do: {:error, "topic_id_list must be greater than 0"}

  defp list_topics_query(%{topic_id_list: topic_id_list, limit: limit, offset: offset} = params) do
    notes_query = from n in Note, select: n.id, order_by: [desc: n.updated_at]
    from(
      t in Topic,
      preload: [notes: ^notes_query],
      where: t.id in ^topic_id_list,
      order_by: [desc: t.updated_at],
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
    handle_create_fn = (fn ->
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
    end)

    [["Title", title]]
    |> Enum.map(fn [key, value] -> validate_user_input(key, value) end)
    |> Enum.filter(fn result -> result !== true end)
    |> create_or_fail(handle_create_fn)
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

  def list_notes(_params), do: {:error, "note_id_list must be greater than 0"}

  defp list_notes_query(%{note_id_list: note_id_list, limit: limit, offset: offset} = params) do
    from(
      n in Note,
      where: n.id in ^note_id_list,
      preload: :note_timers,
      limit: ^limit,
      offset: ^offset,
      # select: %Note{
      #   id: n.id,
      #   topic_id: n.topic_id,
      #   title: n.title,
      #   order: n.order,
      #   tags: n.tags,
      #   content_markdown: n.content_markdown,
      #   inserted_at: n.inserted_at,
      #   updated_at: n.updated_at,
      # },
      select: map(n,[:id, :topic_id, :title, :order, :tags, :content_markdown, :inserted_at, :updated_at, note_timers: [:id]]),
      order_by: [desc: n.updated_at],
    ) |> IO.inspect |> Repo.all |> IO.inspect
  end

  def update_note_title(%{requester_id: requester_id, note_id: note_id} = params) do
    # TODO
  end

  def update_note_content(%{
      requester_id: requester_id,
      note_id: note_id,
      content_markdown: content_markdown,
      content_text: content_text
    } = params) do
      # IMMEDIATE TODO: What regex will help prevent XSS vuln..
      # handle_create_fn = (fn ->
      #   success_fn = (fn -> retrieve_and_update_note_content(params) end)
      #   fail_fn = (fn notebook_id -> verify_shareduser_of_resource(%{
      #               operation: :write,
      #               notebook_id: notebook_id,
      #               requester_id: requester_id,
      #               success_fn: success_fn
      #             }) end)
      #   check_notebook_access_authorization(%{
      #     requester_id: requester_id,
      #     resource_id: note_id,
      #     resource_type: :note,
      #   }, success_fn, fail_fn)
      # end)

      # [["content_text", content_text]]
      # |> Enum.map(fn [key, value] -> validate_user_input(key, value) end)
      # |> Enum.filter(fn result -> result !== true end)
      # |> create_or_fail(handle_create_fn)

      # TODO: Ensure str is somewhere between 0 min and 40k/50k max in length...?
      # Perhaps 20k/30k could be more reasonable...
      # 20k seems like it would be a reasonable amount.
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
  solution arrived at thanks to this post from the elixir forum:
  https://elixirforum.com/t/how-to-merge-list-pares-into-a-single-map/3468/2

  input:
  %Postgres.Result{
    columns: ["note_id", "topic_id", "sub_category_id", "notebook_id", "title",
      "content_text"],
    command: :select,
    connection_id: 12613,
    messages: [],
    num_rows: 1,
    rows: [
      [5, 3, 2, 2, "Best Time to Buy/Sell a Stock", "content_text string...."]
    ]
  }


  output:
  [
    %{
      content_text: "content_text string....",
      note_id: 5,
      notebook_id: 2,
      sub_category_id: 2,
      title: "Best Time to Buy/Sell a Stock",
      topic_id: 3
    }
  ]
  """
  defp format_search_results(search_results) do
    search_results.rows
    |> Enum.map(fn row ->
      for {column, row_value} <- Enum.zip(search_results.columns, row), into: %{}, do: { String.to_atom(column), row_value }
    end)
  end

  @doc """
  Notebooks.search_note_content("Fuck")

  SELECT id, topic_id, title, content_text FROM notes WHERE notes.content_text @@ to_tsquery($1) ["Fuck"]
  {:ok,
  %Postgrex.Result{
    columns: ["id", "topic_id", "title", "content_text"],
    command: :select,
    connection_id: 28610,
    messages: [],
    num_rows: 2,
    rows: [
      [1, 4, "Ichi", "This has been some fucking shitttt mannnn"],
      [3, 4, "ThirdOne", "Need another fuck to search for"]
    ]
  }}

  Recently updated to accomodate searching only a user's owned notes:
  Notebooks.Impl.search_note_content(%{requester_id: 1, search_text: "fuck", offset: 0})
  Offset will be maintained in client side state in order to facilitate pagination through the
  search results. Will be reset whenever the client changes the search_text on the client side.
  {:ok,
  %Postgrex.Result{
    columns: ["note_id", "topic_id", "sub_category_id", "notebook_id", "title",
      "content_text"],
    command: :select,
    connection_id: 12613,
    messages: [],
    num_rows: 1,
    rows: [
      [5, 3, 2, 2, "Best Time to Buy/Sell a Stock", "content_text string...."]
    ]
    }}

  Returned to the controller function to be sent back to the clientside:
  %{
      # As a result of calling format_search_results
      search_results: [
        %{
          content_text: "content_text string....",
          note_id: 5,
          notebook_id: 2,
          sub_category_id: 2,
          title: "Best Time to Buy/Sell a Stock",
          topic_id: 3
        }
      ]
      num_rows: postgres_result.num_rows
    }
  """
  def search_note_content(%{requester_id: requester_id, search_text: search_text, offset: offset}) do
    # SO Post also implemented it like so:
    # defp filter_by(query, :search_string, %{search_string: search_string} = args) do
    #   tsquery_string = StringHelpers.to_tsquery_string(search_string)

    #   from d in query,
    #     where: fragment("? @@ to_tsquery('english', ?)", d.search_tsvector, ^tsquery_string)
    # end


    # NOTE:
    # Old query.. Didn't query for only notes which the user owns.
    # Ecto.Adapters.SQL.query(
    #   Dbstore.Repo, "SELECT id, topic_id, title, content_text FROM notes WHERE notes.content_text @@ plainto_tsquery($1)", [search_text]
    # )

    query_result = Ecto.Adapters.SQL.query(
      Dbstore.Repo, "SELECT notes.id as note_id, notes.topic_id, sub_categories.id as sub_category_id,
      notebooks.id as notebook_id, notes.title, notes.content_text FROM notebooks, sub_categories,
      topics, notes WHERE notebooks.owner_id = $1 and sub_categories.notebook_id = notebooks.id and
      topics.sub_category_id = sub_categories.id and notes.topic_id = topics.id
      and notes.content_text@@ plainto_tsquery($2) LIMIT 10 OFFSET $3", [requester_id, search_text, offset]
    )

    case query_result do
      {:ok, postgres_result} ->
        {:ok, %{
          search_results: format_search_results(postgres_result),
          num_rows: postgres_result.num_rows
        }}

        _ ->
          {:err, "Oops... Something went wrong."}
    end
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
    update_query = from(n in Note, where: n.id == ^note_id, update: [set: [content_markdown: ^content_markdown, content_text: ^content_text, content_text_vector: ^content_text]])
    case update_query |> Repo.update_all([]) do
      {1, nil} ->
        {:ok, "Successfully updated the note!"}

      {_, nil} ->
        {:error, "Unable to retrieve the note."}

      _ ->
        {:error, "Oops, something went wrong."}
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
  NOTE: The tags array will be in alphabetical order. Suppose
        this has to do w/ the implementation of the MapSet.

  Success case:
  {:ok, struct}

  PRIORITY TODO: Need to see how I'll handle the error case when the
  returned changeset is retrieved in the controller... as of right
  now it'll blow up.
  Error case:
  {:error, changeset} // W/ validation/contraint errors.
  """
  def add_tags(:topic, %{topic_id: topic_id, tags: tags} = params) do
    # PRIORITY TODO (DO THIS FIRST): Check to see if searching by tags for Topics from the UI will even
    # be feasible...
    # ALSO TODO: Forgot that I was also checking for length at least >= 3 on the client
    # side as well... So the client should never really receive this error response..
    # but still test this behavior.
    handle_create_fn = (fn ->
      topic = Repo.get(Topic, topic_id)
      set = create_tag_mapset(Enum.concat(topic.tags, tags))
      Topic.add_tags_changeset(topic, %{tags: MapSet.to_list(set)}) |> Repo.update
    end)

    tags
    |> Enum.with_index
    |> Enum.map(fn ({tag, idx}) -> ["Tag", tag, idx] end)
    |> Enum.map(fn [key, value, position] -> validate_user_input(key, value, position) end)
    |> Enum.filter(fn result -> result !== true end)
    |> IO.inspect
    |> create_or_fail(handle_create_fn)
  end

  def add_tags(:note, %{note_id: note_id, tags: tags}) do
    handle_create_fn = (fn ->
      note = Repo.get(Note, note_id)
      set = create_tag_mapset(Enum.concat(note.tags, tags))
      Note.add_tags_changeset(note, %{tags: MapSet.to_list(set)}) |> Repo.update
    end)


    tags
    |> Enum.with_index
    |> Enum.map(fn ({tag, idx}) -> ["Tag", tag, idx] end)
    |> Enum.map(fn [key, value, position] -> validate_user_input(key, value, position) end)
    |> Enum.filter(fn result -> result !== true end)
    |> IO.inspect()
    |> create_or_fail(handle_create_fn)
  end

  def remove_tag(:topic, %{topic_id: topic_id, tag: tag}) do
    topic = Repo.get(Topic, topic_id)
    set = MapSet.new(topic.tags)
    case MapSet.member?(set, tag) do
      true ->
        set = MapSet.delete(set, tag)
        Topic.add_tags_changeset(topic, %{tags: MapSet.to_list(set)}) |> Repo.update
      false ->
        {:error, "Tag is not in the list of tags."}
    end
  end

  def remove_tag(:note, %{note_id: note_id, tag: tag}) do
    note = Repo.get(Note, note_id)
    set = MapSet.new(note.tags)
    case MapSet.member?(set, tag) do
      true ->
        set = MapSet.delete(set, tag)
        Note.add_tags_changeset(note, %{tags: MapSet.to_list(set)}) |> Repo.update
      false ->
        {:error, "Tag is not in the list of tags."}
    end
  end

  defp create_tag_mapset(tags) do
    set = Enum.reduce(tags, MapSet.new(), fn tag, acc ->
      acc = MapSet.put(acc, tag)
    end)
  end

  # **************************
  # NoteTimer Resource Actions
  # **************************
  def create_note_timer(%{
    requester_id: requester_id,
    timer_count: timer_count,
    note_id: note_id
  } = params) do
      success_fn = (fn ->
        %NoteTimer{} |> NoteTimer.changeset(Map.put(params, :elapsed_seconds, 0)) |> Repo.insert
      end)
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

  # TODO: write a test for this
  def list_note_timers(%{
    requester_id: requester_id,
    note_timer_id_list: note_timer_id_list,
    limit: limit,
    offset: offset
  } = params) when length(note_timer_id_list) > 0 do
    success_fn = (fn -> list_note_timers_query(params) end)
    fail_fn = (fn notebook_id -> verify_shareduser_of_resource(%{
                operation: :read,
                notebook_id: notebook_id,
                requester_id: requester_id,
                success_fn: success_fn
              }) end)
    check_notebook_access_authorization(%{
      requester_id: requester_id,
      resource_id: Enum.at(note_timer_id_list, 0),
      resource_type: :note_timer,
    }, success_fn, fail_fn)
  end

  def list_note_timers(_params), do: {:error, "note_timer_id_list must be greater than 0"}

  defp list_note_timers_query(%{note_timer_id_list: note_timer_id_list, limit: limit, offset: offset} = params) do
    from(
      nt in NoteTimer,
      where: nt.id in ^note_timer_id_list,
      order_by: [desc: nt.updated_at],
      limit: ^limit,
      offset: ^offset
    ) |> Repo.all
  end

  @doc """
  updates may be a map which contains either:
  %{
    elapsed_seconds: elapsed_seconds,
    description: description
  }
  """
  def update_note_timer(%{
    requester_id: nil
  }), do: {:error, "You must provide requester_id."}

  def update_note_timer(%{
    note_timer_id: nil
  }), do: {:error, "You must provide note_timer_id."}

  def update_note_timer(%{
    updates: %{elapsed_seconds: nil, description: nil}
  }), do: {:error, "You must provide either elapsed_seconds or description as updates."}

  def update_note_timer(%{
    requester_id: requester_id,
    note_timer_id: note_timer_id,
    updates: updates
  } = params) do
      success_fn = (fn ->
        {non_nil_updates, update_query} = generate_update_query(:note_timer, %{note_timer_id: note_timer_id}, updates)
        case update_query |> Repo.update_all([]) do
          {1, nil} ->
            {:ok, %{message: "Successfully updated the note timer!", data: non_nil_updates}}

          {_, nil} ->
            {:error, "Unable to retrieve the note timer."}

          _ ->
            {:error, "Oops, something went wrong."}
        end
      end)
      fail_fn = (fn notebook_id -> verify_shareduser_of_resource(%{
                  operation: :write,
                  notebook_id: notebook_id,
                  requester_id: requester_id,
                  success_fn: success_fn
                }) end)
      check_notebook_access_authorization(%{
        requester_id: requester_id,
        resource_id: note_timer_id,
        resource_type: :note_timer,
      }, success_fn, fail_fn)
  end

  defp generate_update_query(:note_timer, %{note_timer_id: note_timer_id}, %{"elapsed_seconds" => elapsed_seconds}) do
    query = from(nt in NoteTimer, where: nt.id == ^note_timer_id, update: [set: [elapsed_seconds: ^elapsed_seconds]])
    {%{elapsed_seconds: elapsed_seconds, id: note_timer_id}, query}
  end

  defp generate_update_query(:note_timer, %{note_timer_id: note_timer_id}, %{"description" => description}) do
    query = from(nt in NoteTimer, where: nt.id == ^note_timer_id, update: [set: [description: ^description]])
    {%{description: description, id: note_timer_id}, query}
  end

  defp generate_update_query(:note_timer, %{note_timer_id: note_timer_id}, %{"elapsed_seconds" => elapsed_seconds, "description" => description} = updates) do
    query = from(nt in NoteTimer, where: nt.id == ^note_timer_id, update: [set: [elapsed_seconds: ^elapsed_seconds, description: ^description]])
    {Map.put(updates, :id, note_timer_id), query}
  end

  def delete_note_timer(%{requester_id: requester_id, note_timer_id: note_timer_id}) do
    success_fn = (fn ->
      NoteTimer |> Repo.get(note_timer_id) |> Repo.delete
    end)
    fail_fn = (fn notebook_id -> verify_shareduser_of_resource(%{
                operation: :write,
                notebook_id: notebook_id,
                requester_id: requester_id,
                success_fn: success_fn
              }) end)
    check_notebook_access_authorization(%{
      requester_id: requester_id,
      resource_id: note_timer_id,
      resource_type: :note_timer,
    }, success_fn, fail_fn)
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
      ) |> Repo.all
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
        {:error, "UNAUTHORIZED_REQUEST"}
      nil ->
        {:error, "UNAUTHORIZED_REQUEST"}
      _ ->
        {:error, "Oops... Something went wrong."}
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
        {:error, "UNAUTHORIZED_REQUEST"}
      _ ->
        {:error, "Oops... Something went wrong."}
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
        # This is the case where the Notebook doesn't exist.
        {:error, "UNAUTHORIZED_REQUEST"}
    end
  end

  defp delegate_notebook_resource_retrieval(:sub_category, resource_id) do
    retrieve_sub_categories_associated_notebook(%{sub_category_id: resource_id})
  end

  defp delegate_notebook_resource_retrieval(:topic, resource_id) do
    retrieve_topics_associated_notebook(%{topic_id: resource_id})
  end

  defp delegate_notebook_resource_retrieval(:note, resource_id) do
    retrieve_notes_associated_notebook(%{note_id: resource_id})
  end

  defp delegate_notebook_resource_retrieval(:note_timer, resource_id) do
    retrieve_note_timers_associated_notebook(%{note_timer_id: resource_id})
  end

  defp delegate_notebook_resource_retrieval(:notebook, resource_id) do
    retrieve_associated_notebook(%{notebook_id: resource_id})
  end

  #################################
  # Accessor Functions to Retrieve
  # a Resource's Associated Notebook
  #################################
  def retrieve_note_timers_associated_notebook(%{note_timer_id: note_timer_id}) do
    from(
      nt in "note_timers",
      where: nt.id == ^note_timer_id,
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
