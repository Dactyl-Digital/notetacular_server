defmodule Dbstore.Repo.Migrations.CreateMemberships do
  use Ecto.Migration

  def change do
    create table("memberships") do
      add(:subscribed_until, :date, null: false)
      add(:user_id, references(:users), on_delete: :delete_all, null: false)
      
      timestamps(type: :utc_datetime)
    end
    
    create(index("memberships", :user_id))
  end
end