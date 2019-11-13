defmodule Dbstore.Repo.Migrations.NotebookShareusers do
  use Ecto.Migration

  def change do
    create table("notebook_shareusers") do
      add(:user_id, references("users"), null: false)
      add(:notebook_id, references("notebooks"), null: false)
      add(:read_only, :boolean, null: false)
      
      timestamps(type: :utc_datetime)
    end

    create(index("notebook_shareusers", :user_id))
    create(index("notebook_shareusers", :notebook_id))
  end
end