defmodule Dbstore.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Dbstore.{Credential, Membership}

  schema "users" do
    field(:username, :string)
    field(:last_seen_active, :date)
    
    timestamps()
    has_one :credentials, Dbstore.Credential
    has_one :memberships, Dbstore.Membership
    # has_one :billings, Dbstore.Billing
    # many_to_many(:roles, Dbstore.Role, join_through: "user_roles")
  end
  
  def changeset(user, params \\ %{}) do
    user
    |> cast(params, [:username])
    |> cast_assoc(:credentials, with: &Credential.changeset/2)
    |> cast_assoc(:memberships, with: &Membership.changeset/2)
    |> validate_required([:username, :credentials, :memberships])
    |> validate_length(:username, min: 3, max: 20)
    |> unique_constraint(:username)
    |> unsafe_validate_unique([:username], Dbstore.Repo, message: "That username is already taken")
  end
end
