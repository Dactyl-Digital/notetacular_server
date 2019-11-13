defmodule Dbstore.Repo.Migrations.CreateNotebooks do
  use Ecto.Migration

  def change do
    create table("notebooks") do
      add(:title, :string, null: false)
      add(:owner_id, references(:users), on_delete: :delete_all, null: false)
      
      timestamps(type: :utc_datetime)
    end
    
    create(index("notebooks", :owner_id))
  end
end