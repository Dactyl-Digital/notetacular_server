defmodule Auth.Authentication do
  use Timex

  @expiry_time_days 2

  @failed_password_match_message "Username or password is incorrect."

  def hash_password(password), do: Argon2.hash_pwd_salt(password)

  def check_password(nil, _password), do: {:error, @failed_password_match_message}

  @doc """
    Returns {:ok, %{user_id: user_id, username: username}}
    In the case of a successful password match in order to facilitate piping this functions
    output into accounts/accounts/impl.ex's login function.
  """
  def check_password(%{password_hash: password_hash} = user_credentials, user_input_password) do
    case Argon2.verify_pass(user_input_password, password_hash) do
      true ->
        :ok

      false ->
        {:error, @failed_password_match_message}
    end
  end

  # TODO: Look into how to set hash_key. Should it be an environment variable?
  def create_session_data(credential_id) do
    Auth.create_hashed_remember_token()
    |> generate_session_data(credential_id)
  end

  # NOTE: I'm opting for credential_id/uuid in an attempt to not put
  #       the user's email on the session.
  # Create UUID for credential? Would this be worth it.
  defp generate_session_data({:ok, {remember_token, hashed_remember_token}}, credential_id) do
    session_data =
      %{credential_id: credential_id, remember_token: remember_token}
      |> generate_expiry_time

    {:ok, {session_data, hashed_remember_token}}
  end

  # Handling the failure case of hash_remember_token/2
  defp generate_session_data({:error, msg}, _), do: {:error, msg}

  defp generate_expiry_time(session_data) do
    expiry =
      Timex.now()
      # TODO: May also use Application.get_env to set @expiry_time_days as well.
      |> Timex.shift(days: @expiry_time_days, hours: 12)
      |> DateTime.to_unix()

    Map.put(session_data, :expiry, expiry)
  end
end
