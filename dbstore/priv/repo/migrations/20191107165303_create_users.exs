defmodule Dbstore.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table("users") do
      add(:username, :string, null: false)
      add(:last_seen_active, :date)
      add(:account_active, :boolean, default: false)
      
      timestamps(type: :utc_datetime)
    end
    
    create(unique_index("users", :username))
  end
end