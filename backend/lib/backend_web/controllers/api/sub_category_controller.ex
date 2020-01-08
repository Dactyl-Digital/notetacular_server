defmodule BackendWeb.SubCategoryController do
  use BackendWeb, :controller
  import Backend.AuthPlug
  alias Dbstore.{Notebook, SubCategory}

  plug(:authorize_user)

  @doc """
  A POST to create a sub_category
  """
  def create_sub_category(conn, %{"title" => title, "notebook_id" => notebook_id} = params) do
    %{current_user: current_user} = conn.assigns

    with {:ok, %SubCategory{} = sub_category} <-
           Notebooks.create_sub_category(%{
             requester_id: current_user.user_id,
             title: title,
             notebook_id: notebook_id |> String.to_integer()
           }) do
      conn
      |> put_status(201)
      |> json(%{message: "Successfully created sub category!", data: sub_category})
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
  "/api/sub_category?limit=20&offset=0"
  """
  def list_sub_categories(%{query_params: %{"limit" => limit, "offset" => offset}} = conn, %{
        "sub_category_id_list" => sub_category_id_list
      }) do
    %{current_user: current_user} = conn.assigns
    # TODO: Implement a pattern match on this...
    # Because when this case is reached
    # -> {:error, "You must provide a requester_id"}
    # it ends up as the value of sub_categories, and
    # is attempted to be sent back as JSON... and
    # this error would crash the server process.
    # NOTE:
    # However.... I don't know how that state was reached,
    # asif the session is invalid then the backend responds
    # to the client immediately w/ a failure response.
    with sub_categories <-
           Notebooks.list_sub_categories(%{
             requester_id: current_user.user_id,
             # NOTE: sub_category_id_list is converted from integer list to string list
             #       when sent from client to server.
             sub_category_id_list: sub_category_id_list |> Enum.map(&String.to_integer/1),
             limit: limit,
             offset: offset
           }) do
      conn
      |> put_status(200)
      |> json(%{
        message: "Successfully listed sub_categories!",
        data: %{
          sub_categories: sub_categories
        }
      })
    else
      _ ->
        conn |> put_status(500) |> json(%{message: "Oops... Something went wrong."})
    end
  end

  def retrieve_sub_category_with_topics(conn, %{
        "sub_category_id" => sub_category_id,
        "limit" => limit,
        "offset" => offset
      }) do
    %{current_user: current_user} = conn.assigns

    with {:ok, data} <-
           Notebooks.retrieve_sub_category_with_topics(%{
             owner_id: current_user.user_id,
             sub_category_id: sub_category_id,
             limit: limit,
             offset: offset
           }) do
      conn
      |> put_status(200)
      |> json(%{
        message: "Successfully listed sub_category's topics!",
        data: data
      })
    else
      _ ->
        conn |> put_status(500) |> json(%{message: "Oops... Something went wrong."})
    end
  end

  def delete_sub_category(
        conn,
        %{"id" => id} = params
      ) do
    %{current_user: current_user} = conn.assigns

    with {:ok, %SubCategory{} = sub_category} <-
           Notebooks.delete_sub_category(%{
             requester_id: current_user.user_id,
             sub_category_id: id |> String.to_integer()
           }) do
      conn
      |> put_status(200)
      |> json(%{
        message: "Successfully deleted the sub category!",
        data: sub_category
      })
    else
      _ ->
        conn |> put_status(500) |> json(%{message: "Oops... Something went wrong."})
    end
  end
end
