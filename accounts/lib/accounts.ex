defmodule Accounts do
  @moduledoc """
  Documentation for Accounts.
  """

  defdelegate create_user(params), to: Accounts.Impl
  # defdelegate retrieve_user_by_username(username), to: Accounts.Impl
  defdelegate retrieve_users_credentials_by_email(email), to: Accounts.Impl
  defdelegate update_user_token(token_type, id, token), to: Accounts.Impl
end
