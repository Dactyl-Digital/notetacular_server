defmodule Dbstore.Note do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notes" do
    field(:title, :string)
    field(:content_markdown, :map)
    field(:content_text, :string)
    field(:content_text_vector, Dbstore.Ecto.Types.TSVectorType)
    field(:order, :integer)
    field(:tags, {:array, :string})

    timestamps()
    belongs_to(:topics, Dbstore.Topic, foreign_key: :topic_id)
    has_many(:note_timers, Dbstore.NoteTimer)
  end

  def changeset(note, params \\ %{}) do
    note
    |> cast(params, [:title, :order, :topic_id])
    |> validate_required([:title, :order, :topic_id])
    |> validate_length(:title, min: 4, max: 50)
  end

  def update_content_changeset(note, params \\ %{}) do
    note
    |> cast(params, [:content_markdown, :content_text, :content_text_vector])
    |> validate_required([:content_markdown, :content_text, :content_text_vector])

    # PRIORITY TODO: Will need to write a custom validator for the content_markdown?
    # Also, what's my regex strategy for the content_text user input?
    # |> validate_length(:content_markdown, min: 20)
    # |> validate_length(:content_text, min: 20)
  end

  def add_tags_changeset(note, params \\ %{}) do
    note
    |> cast(params, [:tags])
    |> validate_required([:tags])

    # TODO: Add custom validator to ensure tag length > 2
  end
end
