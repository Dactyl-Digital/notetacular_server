defmodule Dbstore.Role do
  use Ecto.Schema

  schema "roles" do
    field(:name, :string, null: false)
    field(:description, :string, null: false)
    
    timestamps()
    many_to_many(:users, Dbstore.User, join_through: "user_roles")
    many_to_many(:permissions, Dbstore.Permission, join_through: "role_permissions")
  end
end
