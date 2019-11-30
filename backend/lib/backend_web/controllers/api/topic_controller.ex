defmodule BackendWeb.TopicController do
  use BackendWeb, :controller
  import Backend.AuthPlug
  alias Dbstore.{Notebook, Topic}

  plug(:authorize_user)

  @doc """
  A POST to create a topic
  """
  def create_topic(conn, %{"title" => title, "sub_category_id" => sub_category_id} = params) do
    %{current_user: current_user} = conn.assigns

    with {:ok, %Topic{} = topic} <-
           Notebooks.create_topic(%{
             requester_id: current_user.user_id,
             title: title,
             # TODO: Ask about UUIDs and how to handle potential collisions.
             sub_category_id: sub_category_id
           }) do
      conn
      |> put_status(201)
      |> json(%{message: "Successfully created topic!", data: topic})
    else
      {:error, errors} ->
        conn |> put_status(400) |> json(%{errors: errors})

      _ ->
        conn |> put_status(500) |> json(%{message: "Oops... Something went wrong."})
    end
  end

  @doc """
  A GET to list a topics associated within a parent sub category

  Example URL:
  "/api/topic?limit=20&offset=0"
  """
  def list_topics(%{query_params: %{"limit" => limit, "offset" => offset}} = conn, %{
        "topic_id_list" => topic_id_list
      }) do
    %{current_user: current_user} = conn.assigns

    with topics <-
           Notebooks.list_topics(%{
             requester_id: current_user.user_id,
             topic_id_list: topic_id_list,
             limit: limit,
             offset: offset
           }) do
      conn
      |> put_status(200)
      |> json(%{
        message: "Successfully listed topics!",
        data: %{
          topics: topics
        }
      })
    else
      _ ->
        conn |> put_status(500) |> json(%{message: "Oops... Something went wrong."})
    end
  end
end
