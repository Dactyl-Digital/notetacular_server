defmodule Dbstore.NoteTimer do
  use Ecto.Schema
  import Ecto.Changeset
  alias Dbstore.{Credential, Membership}

  schema "note_timers" do
    field(:title, :string)
    field(:description, :string)
    field(:timer, :time)
    field(:timer_count, :integer)
    
    timestamps()
    belongs_to(:notes, Dbstore.Note, foreign_key: :note_id)
  end
  
  def changeset(note_timer, params \\ %{}) do
    note_timer
    |> cast(params, [:title, :timer, :timer_count])
    |> validate_required([:title, :timer, :timer_count])
    |> validate_length(:title, min: 4, max: 50)
  end
end