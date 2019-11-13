defmodule Notebooks do
  @moduledoc """
  Documentation for Notebooks Context.
  """
  
  # *************************
  # Notebook Resource Actions
  # *************************
  defdelegate create_notebook(params), to: Notebooks.Impl
  defdelegate list_notebooks(owner_id), to: Notebooks.Impl
  defdelegate update_notebook_title(notebook_id), to: Notebooks.Impl
  defdelegate delete_notebook(notebook_id), to: Notebooks.Impl
  
  # ****************************
  # SubCategory Resource Actions
  # ****************************
  defdelegate create_sub_category(params), to: Notebooks.Impl
  defdelegate list_sub_categories(owner_id), to: Notebooks.Impl
  defdelegate update_sub_category_title(sub_category_id), to: Notebooks.Impl
  defdelegate delete_sub_category(sub_category_id), to: Notebooks.Impl
  
  # **********************
  # Topic Resource Actions
  # **********************
  defdelegate create_topic(params), to: Notebooks.Impl
  defdelegate list_topics(sub_category_id), to: Notebooks.Impl
  defdelegate update_topic_title(topic_id), to: Notebooks.Impl
  defdelegate delete_topic(topic_id), to: Notebooks.Impl
  
  # *********************
  # Note Resource Actions
  # *********************
  defdelegate create_note(params), to: Notebooks.Impl
  defdelegate list_notes(topic_id), to: Notebooks.Impl
  defdelegate update_note_title(note_id), to: Notebooks.Impl
  defdelegate update_note_order(note_id_and_order_list), to: Notebooks.Impl
  defdelegate delete_note(note_id), to: Notebooks.Impl
  
  # *****************************
  # Topic & Note Resource Actions
  # *****************************
  defdelegate add_tags(resource, resource_id, tags), to: Notebooks.Impl
  defdelegate remove_tag(resource, resource_id, tag), to: Notebooks.Impl
end
