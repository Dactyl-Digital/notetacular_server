defmodule Dbstore.Permission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "permissions" do
    field(:name, :string)
    
    timestamps()
    many_to_many(:roles, Dbstore.Role, join_through: "role_permissions")
  end
  
  def changeset(role, params \\ %{}) do
    role
    |> cast(params, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: 3, max: 30)
  end
end