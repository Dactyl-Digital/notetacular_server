defmodule Dbstore.Repo.Migrations.CreateUserRole do
  use Ecto.Migration

  def change do
    create table("user_roles") do
      add(:user_id, references("users"), null: false)
      add(:role_id, references("roles"), null: false)
      
      timestamps(type: :utc_datetime)
    end

    create(index("user_roles", :user_id))
    create(index("user_roles", :role_id))
  end
end
