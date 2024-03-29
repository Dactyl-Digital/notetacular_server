defmodule Auth.Authorization do
  # alias Auth

  # Key for hashing the user's remember_token TODO: (This is duplicated in lib/accounts/impl.ex)
  # Take a similar approach to hash keys just as Salts for hashing a user's pw -> store them in db?
  # TODO: Still needed to look into the reasoning behind doing so.
  # WARNING: This is duplicated in the account project's impl.ex file
  # @hash_key "7b8lEvA2aWxGB1f2MhBjhz8YRf1p21fgTxn8Qf6KciM9IJCaJ9aIn4SNna0FybxZ"

  def check_authorization(nil, _), do: {:error, "No user session retrieved from conn."}

  def check_authorization(%{expiry: expiry} = params, fetch_crendential_fn) do
    Timex.now()
    |> DateTime.to_unix()
    |> check_expiry(expiry)
    |> fetch_crendential(params, fetch_crendential_fn)
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

  defp fetch_crendential(
         {:ok, "Valid session"},
         %{credential_id: credential_id, remember_token: remember_token},
         fetch_credential_fn
       ) do
    case fetch_credential_fn.(credential_id) do
      credential ->
        {:ok, {credential, remember_token}}

      nil ->
        {:error, "Session cleared due to being unable to find user by username."}
    end
  end

  defp fetch_crendential({:error, msg}, _params, _fetch_crendential_fn), do: {:error, msg}

  defp auth_check({:ok, {credential, remember_token}}) do
    case Auth.token_matches?(:remember_token, credential, remember_token) do
      true ->
        {:ok, %{user_id: credential.user_id}}

      false ->
        {:error, "Remember token doesn't match hashed remember token"}
    end
  end

  defp auth_check({:error, msg}), do: {:error, msg}
end
