defmodule Dbstore.Permission do
  use Ecto.Schema

  schema "permissions" do
    field(:name, :string, null: false)
    
    timestamps()
    many_to_many(:roles, Dbstore.Role, join_through: "role_roles")
  end
end
