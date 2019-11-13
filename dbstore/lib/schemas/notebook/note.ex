defmodule Dbstore.Note do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notes" do
    field(:title, :string)
    field(:content_markdown, :map)
    field(:content_text, :string)
    field(:order, :integer)
    field(:tags, {:array, :string})
    
    timestamps()
    belongs_to(:topics, Dbstore.Topic, foreign_key: :topic_id)
    has_many(:note_timers, Dbstore.NoteTimer)
  end
  
  def changeset(note, params \\ %{}) do
    note
    |> cast(params, [:title, :order])
    |> validate_required([:title, :order])
    |> validate_length(:title, min: 4, max: 50)
  end
end