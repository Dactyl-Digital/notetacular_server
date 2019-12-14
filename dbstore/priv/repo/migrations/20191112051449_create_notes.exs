defmodule Dbstore.Repo.Migrations.CreateNotes do
  use Ecto.Migration

  def change do
    create table("notes") do
      add(:title, :string, null: false)
      add(:content_markdown, :map)
      add(:content_text, :tsvector)
      add(:order, :integer, null: false)
      add(:tags, {:array, :string}, default: [])
      add(:topic_id, references(:topics), on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    # Was in a SO post.. Suppose this would be necessary for converting any existing values to a Tsvector
    #   "UPDATE notes SET content_text_vector = to_tsvector('english', concat_ws(' ', content_text))"

    create(index("notes", :id))
    create(index(:notes, [:content_text], using: :gin))

    # Will this be useful for handling search?
  end
end
