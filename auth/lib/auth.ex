defmodule Auth do
  @moduledoc """
  Documentation for Auth.
  """
  
  defdelegate check_authorization(params, fetch_user_fn), to: Auth.Authorization
  defdelegate hash_password(password, salt), to: Auth.Authentication
  defdelegate check_password(user, password), to: Auth.Authentication
  defdelegate create_session_data(username, remember_token_bytes), to: Auth.Authentication
  defdelegate hash_remember_token(remember_token), to: Auth.Authentication
end
