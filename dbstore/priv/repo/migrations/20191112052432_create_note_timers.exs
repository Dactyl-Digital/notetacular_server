defmodule Dbstore.Repo.Migrations.CreateNoteTimers do
  use Ecto.Migration

  def change do
    create table("note_timers") do
      add(:timer, :time, null: false)
      add(:description, :string)
      add(:timer_count, :integer, null: false)
      add(:note_id, references(:notes), on_delete: :delete_all, null: false)
      
      timestamps(type: :utc_datetime)
    end
    
    create(index("note_timers", :note_id))
  end
end