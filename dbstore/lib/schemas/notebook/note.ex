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
    |> cast(params, [:title, :order, :topic_id])
    |> validate_required([:title, :order, :topic_id])
    |> validate_length(:title, min: 4, max: 50)
  end
  
  def update_content_changeset(note, params \\ %{}) do
    IO.puts("inside changeset")
    note
    |> cast(params, [:content_markdown, :content_text])
    |> IO.inspect()
    |> validate_required([:content_markdown, :content_text])
    # TODO: Will need to write a customer validator for the content_markdown?
    # |> validate_length(:content_markdown, min: 20)
    # |> validate_length(:content_text, min: 20)
  end
end