defmodule Dbstore.NoteTimer do
  use Ecto.Schema
  import Ecto.Changeset
  alias Dbstore.{Credential, Membership}

  schema "note_timers" do
    # NOTE: timer is the millisecond representation of the time elasped thus far.
    field(:timer, :time)
    field(:description, :string)
    field(:timer_count, :integer)
    
    timestamps()
    belongs_to(:notes, Dbstore.Note, foreign_key: :note_id)
  end
  
  def changeset(note_timer, params \\ %{}) do
    note_timer
    |> cast(params, [:timer, :timer_count, :note_id])
    |> validate_required([:timer, :timer_count, :note_id])
  end
end