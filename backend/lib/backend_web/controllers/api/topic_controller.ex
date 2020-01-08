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
             sub_category_id: sub_category_id |> String.to_integer()
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
             topic_id_list: topic_id_list |> Enum.map(&String.to_integer/1),
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

  def delete_topic(
        conn,
        %{"id" => id} = params
      ) do
    %{current_user: current_user} = conn.assigns

    with {:ok, %Topic{} = topic} <-
           Notebooks.delete_topic(%{
             requester_id: current_user.user_id,
             topic_id: id |> String.to_integer()
           }) do
      conn
      |> put_status(200)
      |> json(%{
        message: "Successfully deleted the topic!",
        data: topic
      })
    else
      _ ->
        conn |> put_status(500) |> json(%{message: "Oops... Something went wrong."})
    end
  end

  # TODO: test add_tags and remove_tag
  def add_tags(conn, %{"topic_id" => topic_id, "tags" => tags}) do
    %{current_user: current_user} = conn.assigns

    with {:ok, %Topic{id: id, tags: tags, sub_category_id: sub_category_id} = topic} <-
           Notebooks.add_tags(:topic, %{topic_id: topic_id, tags: tags}) do
      conn
      |> put_status(201)
      |> json(%{
        message: "Successfully added tags!",
        data: %{
          id: id,
          tags: tags,
          sub_category_id: sub_category_id
        }
      })
    else
      {:error, msg} ->
        conn |> put_status(401) |> json(%{message: msg})

      _ ->
        conn |> put_status(500) |> json(%{message: "Oops... Something went wrong."})
    end
  end

  def remove_tag(conn, %{"topic_id" => topic_id, "tag" => tag}) do
    %{current_user: current_user} = conn.assigns

    with {:ok, %Topic{id: id, tags: tags, sub_category_id: sub_category_id} = topic} <-
           Notebooks.remove_tag(:topic, %{topic_id: topic_id, tag: tag}) do
      conn
      |> put_status(200)
      |> json(%{
        message: "Successfully removed tag!",
        data: %{
          id: id,
          tags: tags,
          sub_category_id: sub_category_id
        }
      })
    else
      {:error, "Tag is not in the list of tags."} ->
        conn |> put_status(401) |> json(%{message: "Tag is not in the list of tags."})

      _ ->
        conn |> put_status(500) |> json(%{message: "Oops... Something went wrong."})
    end
  end
end
