defmodule Notebooks.Impl do
  @moduledoc """
  Documentation for Notebooks.Impl
  """
  import Ecto.Query
  alias Ecto.Changeset
  alias Dbstore.{Repo, Notebook, SubCategory, Topic, Note, NoteTimer}

  # Status Codes
  @created_code 201
  @bad_request_code 400
  @forbidden_code 403

  # Response Messages
  @signup_success_message "You've successfully signed up!"
  @login_success_message "You've successfully logged in!"
  @something_went_wrong_message "Oops... Something went wrong. Please try again."
  @permission_not_found_message "Permission not found"

  # *************************
  # Notebook Resource Actions
  # *************************
  def create_notebook(params) do
    IO.puts("params in create_notebook")
    IO.inspect(params)
  end
  
  def list_notebooks(owner_id) do
    IO.puts("owner_id in list_notebooks")
    IO.inspect(owner_id)
  end
  
  def update_notebook_title(notebook_id) do
    IO.puts("notebook_id in update_notebook_title")
    IO.inspect(notebook_id)
  end
  
  def delete_notebook(notebook_id) do
    IO.puts("notebook_id in delete_notebook")
    IO.inspect(notebook_id)
  end
  
  # ****************************
  # SubCategory Resource Actions
  # ****************************
  def create_sub_category(params) do
    IO.puts("params in create_sub_category")
    IO.inspect(params)
  end
  
  def list_sub_categories(notebook_id) do
    IO.puts("notebook_id in list_sub_categories")
    IO.inspect(notebook_id)
  end
  
  def update_sub_category_title(sub_category_id) do
    IO.puts("sub_category_id in update_sub_category_title")
    IO.inspect(sub_category_id)
  end
  
  def delete_sub_category(sub_category_id) do
    IO.puts("sub_category_id in delete_sub_category")
    IO.inspect(sub_category_id)
  end
  
  # **********************
  # Topic Resource Actions
  # **********************
  def create_topic(params) do
    IO.puts("params in create_topic")
    IO.inspect(params)
  end
  
  def list_topics(sub_category_id) do
    IO.puts("sub_category_id in list_topics")
    IO.inspect(sub_category_id)
  end
  
  def update_topic_title(topic_id) do
    IO.puts("topic_id in update_topic_title")
    IO.inspect(topic_id)
  end
  
  def delete_topic(topic_id) do
    IO.puts("topic_id in delete_topic")
    IO.inspect(topic_id)
  end
  
  # *********************
  # Note Resource Actions
  # *********************
  def create_note(params) do
    IO.puts("params in create_note")
    IO.inspect(params)
  end
  
  def list_notes(topic_id) do
    IO.puts("topic_id in list_notes")
    IO.inspect(topic_id)
  end
  
  def update_note_title(note_id) do
    IO.puts("note_id in update_note_title")
    IO.inspect(note_id)
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

  end
  
  def delete_note(note_id) do
    IO.puts("note_id in delete_note")
    IO.inspect(note_id)
  end
  
  # *****************************
  # Topic & Note Resource Actions
  # *****************************
  def add_tags(:topic, topic_id, tags) do
    # TODO: Concatenate tags onto the JSONB array in the DB.
  end
  
  def add_tags(:note, note_id, tags) do
    # TODO: Concatenate tags onto the JSONB array in the DB.
  end
  
  def remove_tags(:topic, topic_id, tag) do
    # TODO: Remove single tag from resource's JSONB array in the DB.
  end
  
  def remove_tags(:note, topic_id, tag) do
    # TODO: Remove single tag from resource's JSONB array in the DB.
  end
end