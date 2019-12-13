defmodule Dbstore.NoteTimer do
  use Ecto.Schema
  import Ecto.Changeset
  alias Dbstore.{Credential, Membership}

  schema "note_timers" do
    # NOTE: timer is the millisecond representation of the time elasped thus far.
    field(:elapsed_seconds, :integer)
    field(:description, :string)
    field(:timer_count, :integer)

    timestamps()
    belongs_to(:notes, Dbstore.Note, foreign_key: :note_id)
  end

  def changeset(note_timer, params \\ %{}) do
    note_timer
    |> cast(params, [:elapsed_seconds, :timer_count, :note_id])
    |> validate_required([:elapsed_seconds, :timer_count, :note_id])
  end

  def update_changeset(note_timer, params \\ %{}) do
    note_timer
    |> cast(params, [:elapsed_seconds, :description])
    |> validate_required([:elapsed_seconds])
  end
end
