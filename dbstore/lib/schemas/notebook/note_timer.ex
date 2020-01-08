defmodule Dbstore.NoteTimer do
  use Ecto.Schema
  import Ecto.Changeset
  alias Dbstore.{Credential, Membership}

  schema "note_timers" do
    # NOTE: timer is the millisecond representation of the time elasped thus far.
    field(:elapsed_seconds, :integer)
    field(:description, :string)
    # TODO: Possibly remove this... I believe I added it so that the timers can be rearranged.
    # but changing the order will be too cumbersome when a timer is deleted. So it's no big deal.
    # This rearrangement of resources in the UI is something that I intended to implement
    # for Notebooks, SubCats, Topics, and Notes as well, so there should be no avoiding it.
    field(:timer_count, :integer)

    # TODO:
    # Look into creating a unique compound index on note_id/timer_count
    # https://stackoverflow.com/a/37859294/10383131
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
