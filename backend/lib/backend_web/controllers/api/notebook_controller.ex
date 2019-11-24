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
end
