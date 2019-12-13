defmodule Dbstore.Repo.Migrations.CreateNotes do
  use Ecto.Migration

  def change do
    create table("notes") do
      add(:title, :string, null: false)
      add(:content_markdown, :map)
      add(:content_text, :tsvector)
      # add(:content_text_vector, :tsvector)
      add(:order, :integer, null: false)
      add(:tags, {:array, :string}, default: [])
      add(:topic_id, references(:topics), on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    # execute(
    #   "UPDATE notes SET content_text_vector = to_tsvector('english', concat_ws(' ', content_text))"
    # )

    create(index("notes", :id))
    create(index(:notes, [:content_text], using: :gin))

    # Will this be useful for handling search?
  end
end
