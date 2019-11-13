defmodule Dbstore.Role do
  use Ecto.Schema
  import Ecto.Changeset

  schema "roles" do
    field(:name, :string)
    field(:description, :string)
    
    timestamps()
    many_to_many(:users, Dbstore.User, join_through: "user_roles")
    many_to_many(:permissions, Dbstore.Permission, join_through: "role_permissions")
  end
  
  def changeset(role, params \\ %{}) do
    role
    |> cast(params, [:name, :description])
    |> validate_required([:name, :description])
    |> validate_length(:name, min: 3, max: 30)
  end
end