defmodule Dbstore.Repo.Migrations.CreateNotes do
  use Ecto.Migration

  def change do
    create table("notes") do
      add(:title, :string, null: false)
      add(:content_markdown, :map)
      add(:content_text, :string)
      add(:content_text_vector, :tsvector)
      add(:order, :integer, null: false)
      add(:tags, {:array, :string}, default: [])
      add(:topic_id, references(:topics), on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    # Was in a SO post.. Suppose this would be necessary for converting any existing values to a Tsvector
    #   "UPDATE notes SET content_text_vector = to_tsvector('english', concat_ws(' ', content_text))"

    # NOTE: tsvector_update_trigger was recommended in postgreSQL up and running book @ Location 3191 of 8478
    # Considering that I'll need to refactor the migration to have both content_text and content_text_vector
    # This may be the more appropriate manner to handle this. Ah... But note this is for vectorizing two
    # columns in a table... So this may actually be unnecessary.
    # CREATE TRIGGER trig_tsv_film_iu
    # BEFORE INSERT OR UPDATE OF title, description ON film FOR EACH ROW
    # EXECUTE PROCEDURE tsvector_update_trigger(fts,'pg_catalog.english',
    # title,description);

    create(index("notes", :id))
    create(index(:notes, [:content_text_vector], using: :gin))

    # Will this be useful for handling search?
  end
end

# This is all you need to facilitate search!
# SELECT id, topic_id, title, content_text FROM notes WHERE notes.content_text @@ to_tsquery('fuck');
