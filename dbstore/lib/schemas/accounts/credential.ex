defmodule Dbstore.Credential do
  use Ecto.Schema
  import Ecto.Changeset

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

  @doc """
    Used for the purpose of seeting the email_verification_token_expiry and hashed_email_verification_token
    fields to nil.
  """
  def activate_account_changeset(credential, params \\ %{}) do
    credential
    |> cast(params, [:id, :email_verification_token_expiry, :hashed_email_verification_token])
  end

  def add_hashed_remember_token_changeset(credential, params \\ %{}) do
    credential
    |> cast(params, [:hashed_remember_token])
    |> validate_required([:hashed_remember_token])
  end

  defp put_pass_hash(changeset = %Ecto.Changeset{valid?: true, changes: %{password: password}}) do
    put_change(
      changeset,
      :password_hash,
      # TODO: Could utilize Mix.ENV to determine whether in dev, test, prod to determine hash rounds
      Auth.hash_password(password)
    )
  end

  defp put_pass_hash(changeset), do: changeset
end
