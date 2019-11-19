defmodule Accounts.Impl do
  @moduledoc """
  Documentation for Accounts.Impl
  """
  import Ecto.Query
  alias Ecto.Changeset
  alias Dbstore.{Repo, User, Permissions}

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

  # Introduced this to provide "PIZZA_APPLICATION_MNAKER" to tests
  # And I suppose this is how any admins introduced into the prod version
  # will be created... But I still wanted to do more research to determine
  # if this is really the best way to go about it.
  def signup_user(params) do
    IO.puts("params in signup_user")
    IO.inspect(params)
  end
  
  defp update_user_token(:hashed_remember_token, user_id, token) do
    %User{id: user_id}
    |> Changeset.cast(
      %{hashed_remember_token: token},
      [:hashed_remember_token]
    )
    |> Repo.update()
  end
  
  defp update_user_token(:hashed_email_verification_token, user_id, token) do
    %User{id: user_id}
    |> Changeset.cast(
      %{hashed_email_verification_token: token},
      [:hashed_email_verification_token]
    )
    |> Repo.update()
  end
end