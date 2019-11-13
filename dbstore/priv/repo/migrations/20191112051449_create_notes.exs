defmodule Dbstore.Repo.Migrations.CreateNotes do
  use Ecto.Migration

  def change do
    create table("notes") do
      add(:title, :string, null: false)
      add(:content_markdown, :map)
      add(:content_text, :string)
      add(:order, :integer, null: false)
      add(:tags, {:array, :string}, default: [])
      add(:topic_id, references(:topics), on_delete: :delete_all)
      
      timestamps(type: :utc_datetime)
    end
    
    # Will this be useful for handling search?
    # create(index("notes", :id))
  end
end