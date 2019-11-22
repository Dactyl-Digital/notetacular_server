defmodule Accounts.Impl do
  @moduledoc """
  Documentation for Accounts.Impl
  """
  import Ecto.Query
  alias Ecto.Changeset
  alias Dbstore.{Repo, Helpers, User, Credential, Permissions}

  # Key for hashing the user's remember_token TODO: (This is duplicated in backend/temp/auth_plug.ex)
  # mix phx.gen.secret [length]
  # TODO: keep this secret in prod
  # WARNING: This is duplicated in the backend project's auth_plug.ex file
  @hash_key "7b8lEvA2aWxGB1f2MhBjhz8YRf1p21fgTxn8Qf6KciM9IJCaJ9aIn4SNna0FybxZ"
  @remember_token_bytes 32

  # Status Codes
  @created_code 201
  @bad_request_code 400
  @forbidden_code 403

  # Response Messages
  @signup_success_message "You've successfully signed up!"
  @login_success_message "You've successfully logged in!"
  @something_went_wrong_message "Oops... Something went wrong. Please try again."
  @permission_not_found_message "Permission not found"
  
  def create_user(%{email: email, username: username, password: password}) do
    %User{}
    |> User.changeset(%{
        username: username,
        credentials: %{
          email: email,
          password: password
        },
        memberships: %{
          subscribed_until: Timex.now() |> Timex.shift(days: 31)
        }
      })
    |> Repo.insert
    |> Helpers.handle_creation_result
  end
  
  def retrieve_users_credentials_by_email(email), do: Repo.get_by(Credential, email: email)
  
  def update_user_token(:hashed_remember_token, id, token) do
    %User{id: id}
    |> Changeset.cast(
      %{hashed_remember_token: token},
      [:hashed_remember_token]
    )
    |> Repo.update()
  end
  
  def update_user_token(:hashed_email_verification_token, id, token) do
    expiry = Timex.now() |> Timex.shift(hours: 24)
    %Credential{id: id}
    |> Changeset.cast(
      %{
        hashed_email_verification_token: token,
        email_verification_token_expiry: expiry
      },
      [:hashed_email_verification_token, :email_verification_token_expiry]
    )
    |> Repo.update()
  end
end