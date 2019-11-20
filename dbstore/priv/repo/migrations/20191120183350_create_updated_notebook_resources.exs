defmodule Dbstore.Repo.Migrations.CreateUpdatedNotebookResources do
  use Ecto.Migration
  
  def change do
    create table("updated_notebook_resources") do
      add(:updated_resource, :string, null: false)
      add(:old_content, :map)
      add(:new_content, :map)
      add(:notebook_id, references(:notebooks), on_delete: :delete_all)
      add(:sub_category_id, references(:sub_categories), on_delete: :delete_all)
      add(:topic_id, references(:topics), on_delete: :delete_all)
      add(:note_id, references(:notes), on_delete: :delete_all)
      add(:note_timer_id, references(:note_timers), on_delete: :delete_all)
      
      timestamps(type: :utc_datetime)
    end
    
    create(index("updated_notebook_resources", :notebook_id))
    create(index("updated_notebook_resources", :sub_category_id))
    create(index("updated_notebook_resources", :topic_id))
    create(index("updated_notebook_resources", :note_id))
    create(index("updated_notebook_resources", :note_timer_id))
  end
end