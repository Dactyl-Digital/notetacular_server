defmodule Dbstore.Credential do
  use Ecto.Schema
  import Ecto.Changeset
  
  # TODO: Use mix phx.gen.secret..
  # Actually... this needs to be stored in the DB.
  # Read the post on handling Password salts securely and handle this properly later.
  @salty "somesaltSOMESALT"

  schema "credentials" do
    field(:email, :string)
    field(:password, :string, virtual: true)
    field(:password_hash, :string)
    field(:hashed_remember_token, :string)
    field(:email_verification_token_expiry, :date)
    field(:hashed_email_verification_token, :string)
    
    timestamps()
    belongs_to(:users, Dbstore.User, foreign_key: :user_id)
  end
  
  def changeset(credential, params \\ %{}) do
    credential
    |> cast(params, [:email, :password])
    |> validate_required([:email, :password])
    |> validate_length(:password, min: 8, max: 50)
    |> unsafe_validate_unique([:email], Dbstore.Repo, message: "That email is already taken")
    |> unique_constraint(:email)
    |> put_pass_hash
  end
  
  defp put_pass_hash(changeset = %Ecto.Changeset{valid?: true, changes: %{password: password}}) do
    put_change(
      changeset,
      :password_hash,
      # TODO: Could utilize Mix.ENV to determine whether in dev, test, prod to determine hash rounds
      Auth.hash_password(password, @salty)
    )
  end

  defp put_pass_hash(changeset), do: changeset
end