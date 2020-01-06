defmodule Notebooks do
  @moduledoc """
  Documentation for Notebooks Context.
  """

  # *************************
  # Notebook Resource Actions
  # *************************
  defdelegate create_notebook(params), to: Notebooks.Impl
  defdelegate retrieve_notebook_with_sub_categories(params), to: Notebooks.Impl
  defdelegate list_notebooks(params), to: Notebooks.Impl
  defdelegate list_shared_notebooks(params), to: Notebooks.Impl
  defdelegate update_notebook_title(params), to: Notebooks.Impl
  defdelegate delete_notebook(params), to: Notebooks.Impl
  defdelegate share_notebook_with_user(params), to: Notebooks.Impl

  # ****************************
  # SubCategory Resource Actions
  # ****************************
  defdelegate create_sub_category(params), to: Notebooks.Impl
  defdelegate retrieve_sub_category_with_topics(params), to: Notebooks.Impl
  defdelegate list_sub_categories(params), to: Notebooks.Impl
  defdelegate update_sub_category_title(sub_category_id), to: Notebooks.Impl
  defdelegate delete_sub_category(sub_category_id), to: Notebooks.Impl

  # **********************
  # Topic Resource Actions
  # **********************
  defdelegate create_topic(params), to: Notebooks.Impl
  defdelegate list_topics(sub_category_id), to: Notebooks.Impl
  defdelegate update_topic_title(params), to: Notebooks.Impl
  defdelegate delete_topic(params), to: Notebooks.Impl

  # *********************
  # Note Resource Actions
  # *********************
  defdelegate create_note(params), to: Notebooks.Impl
  defdelegate retrieve_note(params), to: Notebooks.Impl
  defdelegate list_notes(topic_id), to: Notebooks.Impl
  defdelegate update_note_title(params), to: Notebooks.Impl
  defdelegate update_note_content(params), to: Notebooks.Impl
  defdelegate update_note_order(note_id_and_order_list), to: Notebooks.Impl
  defdelegate delete_note(params), to: Notebooks.Impl
  defdelegate search_note_content(params), to: Notebooks.Impl

  # **************************
  # NoteTimer Resource Actions
  # **************************
  defdelegate create_note_timer(params), to: Notebooks.Impl
  defdelegate list_note_timers(params), to: Notebooks.Impl
  defdelegate update_note_timer(params), to: Notebooks.Impl
  defdelegate delete_note_timer(params), to: Notebooks.Impl

  # **************************************
  # For Internal Usage within Context only
  # (Exposing only for purposes of testing)
  # **************************************
  defdelegate retrieve_notes_associated_notebook(params), to: Notebooks.Impl

  # *****************************
  # Topic & Note Resource Actions
  # *****************************
  defdelegate add_tags(resource, params), to: Notebooks.Impl
  defdelegate remove_tag(resource, params), to: Notebooks.Impl
end
