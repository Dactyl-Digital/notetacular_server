defmodule Auth.Authorization do
  alias Auth

  # Key for hashing the user's remember_token TODO: (This is duplicated in lib/accounts/impl.ex)
  # Take a similar approach to hash keys just as Salts for hashing a user's pw -> store them in db?
  # TODO: Still needed to look into the reasoning behind doing so.
  # WARNING: This is duplicated in the account project's impl.ex file
  # @hash_key "7b8lEvA2aWxGB1f2MhBjhz8YRf1p21fgTxn8Qf6KciM9IJCaJ9aIn4SNna0FybxZ"

  def check_authorization(nil, _), do: {:error, "No retrieved from conn."}

  def check_authorization(%{expiry: expiry} = params, fetch_user_fn) do
    Timex.now()
    |> DateTime.to_unix()
    |> check_expiry(expiry)
    |> fetch_user(params, fetch_user_fn)
    |> auth_check()
  end

  defp check_expiry(datetime, expiry) do
    case datetime < expiry do
      true ->
        {:ok, "Valid session"}

      false ->
        {:error, "Invalid session"}
    end
  end

  defp fetch_user({:ok, "Valid session"}, %{username: username, remember_token: remember_token}, fetch_user_fn) do
    # TODO: Remove this comment , but implement this function in the Accounts context: case Accounts.retrieve_user_by_username(username) do
    case fetch_user_fn.(username) do
      user ->
        {:ok, {user, remember_token}}

      nil ->
        {:error, "Session cleared due to being unable to find user by username."}
    end
  end
  
  defp fetch_user({:error, msg}, _params, _fetch_user_fn), do: {:error, msg}

  defp auth_check({:ok, {user, remember_token}}) do
    case remember_token_matches?(user, remember_token) do
      true ->
        {:ok, user}

      false ->
        {:error, "Remember token doesn't match hashed remember token"}
    end
  end

  defp auth_check({:error, msg}), do: {:error, msg}

  @doc """
    remember_token is the incoming token from the request.

    hashed_remember_token is the one that was stored in Credential
    GenServer state.

    TODO: add user struct pattern match for the first arg for extra clarity
  """
  defp remember_token_matches?(
         %{hashed_remember_token: hashed_remember_token},
         remember_token
       ) do
    {:ok, {_remember_token, hashed_token}} = Auth.hash_remember_token(remember_token)
    hashed_token === hashed_remember_token
  end
end
