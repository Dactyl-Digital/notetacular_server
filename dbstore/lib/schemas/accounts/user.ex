defmodule Dbstore.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Dbstore.{Credential, Membership}

  schema "users" do
    field(:username, :string)
    # PRIORITY TODO: Update this field in the DB when user logs in...
    # I think I haven't gotten around to handling this yet.
    field(:last_seen_active, :date)
    field(:account_active, :boolean)

    timestamps()
    has_one(:credentials, Dbstore.Credential)
    has_one(:memberships, Dbstore.Membership)
    has_one(:billings, Dbstore.Billing)
    many_to_many(:roles, Dbstore.Role, join_through: "user_roles")
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

  def activate_account_changeset(user, params \\ %{}) do
    user
    |> cast(params, [:account_active])
    |> cast_assoc(:credentials, with: &Credential.activate_account_changeset/2)
    |> validate_required([:account_active, :credentials])
  end
end
