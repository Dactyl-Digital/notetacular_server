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
      |> put_status(200)
      |> json(%{message: "Successfully created notebook!"})
    else
      {:error, errors} ->
        conn |> put_status(400) |> json(%{errors: errors})

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

    # IO.puts("list_notebooks returns:")

    # IO.inspect(
    #   Notebooks.list_notebooks(%{limit: limit, offset: offset, owner_id: current_user.user_id})
    # )

    # conn
    # |> put_status(200)
    # |> json(%{message: "Successfully listed notebooks!"})
  end
end
