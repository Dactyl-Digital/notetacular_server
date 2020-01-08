defmodule Auth do
  @moduledoc """
  Documentation for Auth.
  """

  defdelegate check_authorization(params, fetch_user_fn), to: Auth.Authorization
  defdelegate hash_password(password), to: Auth.Authentication
  defdelegate check_password(user, password), to: Auth.Authentication
  defdelegate create_session_data(username), to: Auth.Authentication

  defdelegate create_hashed_remember_token, to: Auth.Token
  defdelegate create_hashed_email_verification_token, to: Auth.Token
  defdelegate hash_token(token, hash_fn), to: Auth.Token
  defdelegate token_matches?(token_type, user, token), to: Auth.Token
  defdelegate verify_email(params), to: Auth.Token
  # defdelegate hmac_remember_token(token), to: Auth.Token
  # defdelegate hmac_email_verification_token(token), to: Auth.Token
end
