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

    # IO.inspect(
    #   Notebooks.create_sub_category(%{
    #     requester_id: current_user.user_id,
    #     title: title,
    #     # TODO: Ask about UUIDs and how to handle potential collisions.
    #     notebook_id: notebook_id
    #   })
    # )

    with {:ok, %SubCategory{} = sub_category} <-
           Notebooks.create_sub_category(%{
             requester_id: current_user.user_id,
             title: title,
             # TODO: Ask about UUIDs and how to handle potential collisions.
             notebook_id: notebook_id
           }) do
      conn
      |> put_status(200)
      |> json(%{message: "Successfully created sub category!"})
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

    with sub_categories <-
           Notebooks.list_sub_categories(%{
             requester_id: current_user.user_id,
             sub_category_id_list: sub_category_id_list,
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
end
