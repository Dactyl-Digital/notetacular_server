defmodule Dbstore.Repo.Migrations.CreateRolePermissions do
  use Ecto.Migration

  def change do
    create table("role_permissions") do
      add(:role_id, references("roles"), null: false)
      add(:permission_id, references("permissions"), null: false)
      
      timestamps(type: :utc_datetime)
    end

    create(index("role_permissions", :role_id))
    create(index("role_permissions", :permission_id))
  end
end