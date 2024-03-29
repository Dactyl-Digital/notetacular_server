defmodule BackendWeb.NotebookController do
  use BackendWeb, :controller
  import Backend.AuthPlug
  alias Dbstore.{Notebook}

  plug(:authorize_user)

  @doc """
  A POST to create a notebook
  """
  def create_notebook(conn, %{"title" => title} = params) do
    %{current_user: current_user} = conn.assigns

    with {:ok, %Notebook{} = notebook} <-
           Notebooks.create_notebook(%{title: title, owner_id: current_user.user_id}) do
      conn
      |> put_status(201)
      |> json(%{message: "Successfully created notebook!", data: notebook})
    else
      {:error, errors} ->
        conn |> put_status(400) |> json(%{errors: errors})

      _ ->
        conn |> put_status(500) |> json(%{message: "Oops... Something went wrong."})
    end
  end

  @doc """
    A GET to list the sub_categories of a given notebook.

    URL:
    "/api/notebook/sub-categories"
  """
  def retrieve_notebook_with_sub_categories(conn, %{
        "notebook_id" => notebook_id,
        "limit" => limit,
        "offset" => offset
      }) do
    %{current_user: current_user} = conn.assigns

    with {:ok, data} <-
           Notebooks.retrieve_notebook_with_sub_categories(%{
             owner_id: current_user.user_id,
             notebook_id: notebook_id,
             limit: limit,
             offset: offset
           }) do
      conn
      |> put_status(200)
      |> json(%{
        message: "Successfully listed notebook's sub categories!",
        data: data
      })
    else
      _ ->
        conn |> put_status(500) |> json(%{message: "Oops... Something went wrong."})
    end
  end

  @doc """
  A GET to list a user's own notebooks

  Example URL:
  "/api/notebook?limit=20&offset=0"
  """
  def list_notebooks(%{query_params: %{"limit" => limit, "offset" => offset}} = conn, _) do
    %{current_user: current_user} = conn.assigns

    with notebooks <-
           Notebooks.list_notebooks(%{
             limit: limit,
             offset: offset,
             owner_id: current_user.user_id
           }) do
      conn
      |> put_status(200)
      |> json(%{
        message: "Successfully listed notebooks!",
        data: %{
          notebooks: notebooks
        }
      })
    else
      _ ->
        conn |> put_status(500) |> json(%{message: "Oops... Something went wrong."})
    end
  end

  def delete_notebook(
        conn,
        %{"id" => id} = params
      ) do
    %{current_user: current_user} = conn.assigns

    with {:ok, %Notebook{} = notebook} <-
           Notebooks.delete_notebook(%{
             requester_id: current_user.user_id,
             notebook_id: id |> String.to_integer()
           }) do
      conn
      |> put_status(200)
      |> json(%{
        message: "Successfully deleted the notebook!",
        data: notebook
      })
    else
      _ ->
        conn |> put_status(500) |> json(%{message: "Oops... Something went wrong."})
    end
  end
end
