defmodule BackendWeb.NoteController do
  use BackendWeb, :controller
  import Backend.AuthPlug
  alias Dbstore.{Notebook, Note, NoteTimer}

  plug(:authorize_user)

  @doc """
  A POST to create a note
  """
  def create_note(conn, %{"title" => title, "order" => order, "topic_id" => topic_id} = params) do
    %{current_user: current_user} = conn.assigns

    with {:ok, %Note{} = note} <-
           Notebooks.create_note(%{
             requester_id: current_user.user_id,
             title: title,
             order: order,
             # TODO: Ask about UUIDs and how to handle potential collisions.
             topic_id: topic_id
           }) do
      conn
      |> put_status(201)
      # TODO: Suppose I should just be returning the resource's id for
      # Notebook, SubCategory, and Topic resources as well... to facilitate
      # the update controller actions.
      |> json(%{message: "Successfully created note!", data: note})
    else
      {:error, errors} ->
        conn |> put_status(400) |> json(%{errors: errors})

      _ ->
        conn |> put_status(500) |> json(%{message: "Oops... Something went wrong."})
    end
  end

  @doc """
  A GET to list a notes associated within a parent topic

  Example URL:
  "/api/note?limit=20&offset=0"
  """
  def list_notes(%{query_params: %{"limit" => limit, "offset" => offset}} = conn, %{
        "note_id_list" => note_id_list
      }) do
    %{current_user: current_user} = conn.assigns

    with notes <-
           Notebooks.list_notes(%{
             requester_id: current_user.user_id,
             note_id_list: note_id_list |> Enum.map(&String.to_integer/1),
             limit: limit,
             offset: offset
           }) do
      conn
      |> put_status(200)
      |> json(%{
        message: "Successfully listed notes!",
        data: %{
          notes: notes
        }
      })
    else
      _ ->
        conn |> put_status(500) |> json(%{message: "Oops... Something went wrong."})
    end
  end

  def delete_note(
        conn,
        %{"id" => id} = params
      ) do
    %{current_user: current_user} = conn.assigns

    with {:ok, %Note{} = note} <-
           Notebooks.delete_note(%{
             requester_id: current_user.user_id,
             note_id: id |> String.to_integer()
           }) do
      conn
      |> put_status(200)
      |> json(%{
        message: "Successfully deleted the note!",
        data: note
      })
    else
      _ ->
        conn |> put_status(500) |> json(%{message: "Oops... Something went wrong."})
    end
  end

  def update_note_content(
        conn,
        %{
          "note_id" => note_id,
          "content_markdown" => content_markdown,
          "content_text" => content_text
        } = params
      ) do
    %{current_user: current_user} = conn.assigns

    with {:ok, "Successfully updated the note!"} <-
           Notebooks.update_note_content(%{
             requester_id: current_user.user_id,
             note_id: note_id,
             content_markdown: content_markdown,
             content_text: content_text
           }) do
      conn
      |> put_status(200)
      |> json(%{
        message: "Successfully updated the note!",
        data: params
      })
    else
      {:error, "Unable to retrieve the note."} ->
        conn |> put_status(400) |> json(%{message: "Unable to retrieve the note."})

      _ ->
        conn |> put_status(500) |> json(%{message: "Oops... Something went wrong."})
    end
  end

  # TODO: test add_tags and remove_tag
  def add_tags(conn, %{"note_id" => note_id, "tags" => tags}) do
    %{current_user: current_user} = conn.assigns

    with {:ok, %Note{id: id, tags: tags, topic_id: topic_id} = note} <-
           Notebooks.add_tags(:note, %{note_id: note_id, tags: tags}) do
      conn
      |> put_status(201)
      |> json(%{
        message: "Successfully added tags!",
        data: %{
          id: id,
          tags: tags,
          topic_id: topic_id
        }
      })
    else
      {:error, msg} ->
        # TODO: Set to Bad Request status code
        conn |> put_status(401) |> json(%{message: msg})

      _ ->
        conn |> put_status(500) |> json(%{message: "Oops... Something went wrong."})
    end
  end

  def remove_tag(conn, %{"note_id" => note_id, "tag" => tag}) do
    %{current_user: current_user} = conn.assigns

    with {:ok, %Note{id: id, tags: tags, topic_id: topic_id} = topic} <-
           Notebooks.remove_tag(:note, %{note_id: note_id, tag: tag}) do
      conn
      |> put_status(200)
      |> json(%{
        message: "Successfully removed tag!",
        data: %{
          id: id,
          tags: tags,
          topic_id: topic_id
        }
      })
    else
      {:error, "Tag is not in the list of tags."} ->
        # TODO: Set to Bad Request status code
        conn |> put_status(401) |> json(%{message: "Tag is not in the list of tags."})

      _ ->
        conn |> put_status(500) |> json(%{message: "Oops... Something went wrong."})
    end
  end

  def create_note_timer(conn, %{"timer_count" => timer_count, "note_id" => note_id} = params) do
    %{current_user: current_user} = conn.assigns

    with {:ok, %NoteTimer{} = note_timer} <-
           Notebooks.create_note_timer(%{
             requester_id: current_user.user_id,
             timer_count: timer_count,
             note_id: note_id
           }) do
      conn
      |> put_status(201)
      |> json(%{
        message: "Successfully created note timer!",
        data: note_timer
      })
    else
      {:error, "Unable to retrieve the note timer."} ->
        conn |> put_status(400) |> json(%{message: "Unable to retrieve the note timer."})

      _ ->
        conn |> put_status(500) |> json(%{message: "Oops... Something went wrong."})
    end
  end

  @doc """
  A GET to list note timers associated within a parent note

  Example URL:
  "/api/note-timer?limit=20&offset=0"
  """
  def list_note_timers(%{query_params: %{"limit" => limit, "offset" => offset}} = conn, %{
        "note_timer_id_list" => note_timer_id_list
      }) do
    %{current_user: current_user} = conn.assigns

    with note_timers <-
           Notebooks.list_note_timers(%{
             requester_id: current_user.user_id,
             # NOTE: This is to compensate for the list_notes_query.
             # Wanted to exclude content_text... as loading it at the moment seems to be impossible.
             # In order to exclude that field from the retrieved notes... I can only use a select statement.
             # which doesn't allow me to use a sub_query to fetch an array of the note_timer notes.
             # So the compromise is that I can only retrieve note_timer_ids as [%{id: 1}, %{id: 2}]
             # |> Enum.map(fn %{id: id} -> String.to_integer(id) end),
             note_timer_id_list: note_timer_id_list |> Enum.map(&String.to_integer/1),
             limit: limit,
             offset: offset
           }) do
      conn
      |> put_status(200)
      |> json(%{
        message: "Successfully listed note timers!",
        data: %{
          note_timers: note_timers
        }
      })
    else
      _ ->
        conn |> put_status(500) |> json(%{message: "Oops... Something went wrong."})
    end
  end

  def update_note_timer(
        conn,
        %{
          "note_timer_id" => note_timer_id,
          "updates" => updates
        } = params
      ) do
    %{current_user: current_user} = conn.assigns

    with {:ok, data} <-
           Notebooks.update_note_timer(%{
             requester_id: current_user.user_id,
             note_timer_id: note_timer_id,
             updates: updates
           }) do
      conn
      |> put_status(201)
      |> json(%{
        message: "Successfully updated note timer!",
        data: data
      })
    else
      {:error, "Unable to retrieve the note timer."} ->
        conn |> put_status(400) |> json(%{message: "Unable to retrieve the note timer."})

      _ ->
        conn |> put_status(500) |> json(%{message: "Oops... Something went wrong."})
    end
  end

  def delete_note_timer(
        conn,
        %{"id" => id} = params
      ) do
    %{current_user: current_user} = conn.assigns

    with {:ok, %NoteTimer{} = note_timer} <-
           Notebooks.delete_note_timer(%{
             requester_id: current_user.user_id,
             note_timer_id: id |> String.to_integer()
           }) do
      conn
      |> put_status(201)
      |> json(%{
        message: "Successfully deleted the note timer!",
        data: note_timer
      })
    else
      # {:error, "UNAUTHORIZED_REQUEST"} This is another possible return result
      # But I suppose I didn't want to explicitly return a message along the lines of this?
      _ ->
        conn |> put_status(500) |> json(%{message: "Oops... Something went wrong."})
    end
  end

  def search_notes(conn, %{"search_text" => search_text, "offset" => offset}) do
    %{current_user: current_user} = conn.assigns

    with {:ok, result} <-
           Notebooks.search_note_content(%{
             requester_id: current_user.user_id,
             search_text: search_text,
             offset: offset |> String.to_integer()
           }) do
      conn
      |> put_status(200)
      |> json(%{
        message: "Successfully searched notes!",
        data: result
      })
    else
      _ ->
        conn |> put_status(500) |> json(%{message: "Oops... Something went wrong."})
    end
  end
end
