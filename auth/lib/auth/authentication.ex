defmodule Auth.Authentication do
  use Timex
  
  @expiry_time_days 1
  
  @failed_password_match_message "Username or password is incorrect."

  def hash_password(password, salt) do
    # TODO: look into the t_cost and m_cost options.
    Argon2.Base.hash_password(password, salt, t_cost: 4, m_cost: 18)
  end

  def check_password(nil, _password), do: {:error, @failed_password_match_message}

  @doc """
    Returns {:ok, %{user_id: user_id, username: username}}
    In the case of a successful password match in order to facilitate piping this functions
    output into accounts/accounts/impl.ex's login function.
  """
  def check_password(user, password) do
    case user |> Argon2.check_pass(password) do
      {:ok, _} ->
        {:ok, %{user_id: user.id, username: user.username}}

      {:error, "invalid password"} ->
        {:error, @failed_password_match_message}
    end
  end

  # TODO: Look into how to set hash_key. Should it be an environment variable?
  def create_session_data(username) do
    Auth.create_hashed_remember_token
    |> generate_session_data(username)
  end

  # defp generate_remember_token(bytes), do: :crypto.strong_rand_bytes(bytes) |> Base.encode64()

  # @doc """
  #   remember_token is stored on the cookie.
    
  #   hashed_remember_token is stored in the database.
    
  #   When a subsequent request reaches the web server, then the remember_token
  #   from the cookie will be hashed, and the resulting hash will be compared against
  #   the hashed_remember_token in the database.
    
  #   If the hash matches, then we know that the contents of the cookie haven't been
  #   tampered with.
  # """
  # def hash_remember_token(remember_token) do
  #   case :crypto.hmac(:sha384, @hash_key, remember_token) |> Base.encode64() do
  #     hashed_remember_token ->
  #       {:ok, {remember_token, hashed_remember_token}}
        
  #     # TODO: Got an error saying this line will never match due to line 39.
  #     #       Need to see what the result of :crypto.hmac and Base.encode64 can possibly
  #     #       be in the event of an error result.
  #     # _ ->
  #     #   {:error, "Something went wrong hashing the remember_token"}
  #   end
  # end

  defp generate_session_data({:ok, {remember_token, hashed_remember_token}}, username) do
    session_data =
      %{username: username, remember_token: remember_token}
      |> generate_expiry_time

    {:ok, {session_data, hashed_remember_token}}
  end

  # Handling the failure case of hash_remember_token/2
  defp generate_session_data({:error, msg}, _), do: {:error, msg}

  defp generate_expiry_time(session_data) do
    expiry =
      Timex.now()
      |> Timex.shift(days: @expiry_time_days, hours: 12)
      |> DateTime.to_unix()

    Map.put(session_data, :expiry, expiry)
  end
end
