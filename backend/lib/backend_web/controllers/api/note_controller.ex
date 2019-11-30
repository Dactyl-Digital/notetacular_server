defmodule BackendWeb.NoteController do
  use BackendWeb, :controller
  import Backend.AuthPlug
  alias Dbstore.{Notebook, Note}

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
             note_id_list: note_id_list,
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
end
