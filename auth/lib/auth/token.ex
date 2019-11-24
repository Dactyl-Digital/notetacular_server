defmodule Auth.Token do
  alias Ecto.Changeset
  alias Dbstore.{Repo, User, Credential}

  # TODO: Look into ideal bytes to use...
  @bytes 255
  # TODO: FIGURE OUT THE SITUATION WITH THIS AS AN ENVIRONMENT VARIABLE?!?
  @hash_key "7b8lEvA2aWxGB1f2MhBjhz8YRf1p21fgTxn8Qf6KciM9IJCaJ9aIn4SNna0FybxZ"

  @doc """
  Success output case:
  {:ok, {remember_token, hashed_remember_token}}
  """
  def create_hashed_remember_token do
    generate_remember_token()
    |> hash_token(fn token -> hmac_remember_token(token) end)
  end

  @doc """
  Success output case:
  {:ok, {email_verification_token, hashed_email_verification_token}}
  """
  def create_hashed_email_verification_token do
    generate_email_verification_token()
    |> hash_token(fn token -> hmac_email_verification_token(token) end)
  end

  @doc """
    remember_token is the incoming token from the request.

    hashed_remember_token is the one that was stored in the database.
  """
  def token_matches?(
        :remember_token,
        %{hashed_remember_token: stored_hashed_remember_token},
        remember_token
      ) do
    {:ok, {_remember_token, freshly_hashed_token}} =
      remember_token
      |> Auth.hash_token(fn token -> hmac_remember_token(token) end)

    stored_hashed_remember_token === freshly_hashed_token
  end

  @doc """
  email_verification_token is the one from the email verification link.

  hashed_email_verification_token is the one that was stored in the database.
  """
  def token_matches?(
        :email_verification_token,
        %{hashed_email_verification_token: stored_hashed_email_verification_token},
        email_verification_token
      ) do
    {:ok, {_email_verification_token, freshly_hashed_token}} =
      email_verification_token
      |> Auth.hash_token(fn token -> hmac_email_verification_token(token) end)

    stored_hashed_email_verification_token === freshly_hashed_token
  end

  defp hmac_remember_token(token),
    do: :crypto.mac(:hmac, :sha384, @hash_key, token) |> Base.encode64()

  defp hmac_email_verification_token(token) do
    :crypto.mac(:hmac, :sha384, @hash_key, token) |> Base.url_encode64()
  end

  defp generate_remember_token, do: :crypto.strong_rand_bytes(@bytes) |> Base.encode64()

  defp generate_email_verification_token do
    :crypto.strong_rand_bytes(@bytes) |> Base.url_encode64()
  end

  @doc """
    token is stored on the cookie.

    hashed_token is stored in the database.

    When a subsequent request reaches the web server, then the token
    from the cookie will be hashed, and the resulting hash will be compared against
    the hashed_token in the database.

    If the hash matches, then we know that the contents of the cookie haven't been
    tampered with.
  """
  def hash_token(token, hash_fn) do
    # NOTE: You were using a case statement before...
    #       but the erlang documentation doesn't indicate
    #       that the :crypto.hmac/3 function can possibly
    #       return a failure result...
    hashed_token = hash_fn.(token)
    {:ok, {token, hashed_token}}
  end

  def verify_email(%{"email_verification_token" => email_verification_token, "email" => email}) do
    # 1. Fetch credential resource from database via email.
    credentials = retrieve_users_credentials_by_email(email)
    # 2. Verify that email_verification_token_expiry has not elapsed.
    # NOTE: The result will be positive if the first date/time comes after the second.
    case Timex.diff(credentials.email_verification_token_expiry, Timex.now())
         |> expiry_elapsed? do
      false ->
        # 3. Hash the token received in controller params and compare
        #    it to the hashed_email_verification_token retrieved from the
        #    credential resource from the DB.
        case token_matches?(:email_verification_token, credentials, email_verification_token) do
          true ->
            # 4. If the two match, then set the credential's email_token fields to null
            #    and switch the user's account_active to true.
            {:ok, %{account_active: account_active}} =
              Repo.get(User, credentials.user_id)
              |> Repo.preload([:credentials])
              |> User.activate_account_changeset(%{
                account_active: true,
                credentials: %{
                  id: credentials.id,
                  hashed_email_verification_token: nil,
                  email_verification_token_expiry: nil
                }
              })
              |> Repo.update()

            {:ok, %{account_active: account_active}}

          false ->
            {:error, "UNAUTHORIZED_REQUEST"}
        end

      true ->
        {:error, "UNAUTHORIZED_REQUEST"}
    end
  end

  def expiry_elapsed?(diff) when diff > 0 do
    false
  end

  def expiry_elapsed?(diff) when diff < 0 do
    true
  end

  defp retrieve_users_credentials_by_email(email), do: Repo.get_by(Credential, email: email)
end
