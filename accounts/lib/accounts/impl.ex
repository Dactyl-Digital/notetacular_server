defmodule Accounts.Impl do
  @moduledoc """
  Documentation for Accounts.Impl
  """
  import Ecto.Query
  alias Ecto.Changeset
  alias Dbstore.{Repo, Helpers, User, Credential, Permissions}

  @salty "somesaltSOMESALT"
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
    |> Repo.insert()
    |> Helpers.handle_creation_result()
  end

  def login_user(%{username: username, password: password}) do
    # NOTE: The commented code below is how I would've thought the checkin gof the
    # user inputted password against the stored hashed_pw would need to be done....
    # How does Argon2.check_password know what salt to use..... Need to look deeper
    # into this.
    # TODO: Look into how to safely handle storing the password hashing salt on users
    # %User{credentials: %Credential{
    #     password_hash: password_hash
    #   }
    # }
    # %User{account_active: account_active, credentials: credentials} =
    retrieve_user_with_credentials_by_username(username)
    |> check_password_if_account_active(password)

    # new_pw_hash = hash_password(password, @salty)
  end

  def check_password_if_account_active(nil, _),
    do: {:error, "Incorrect username or password."}

  def check_password_if_account_active(%{account_active: false}, _),
    do: {:error, "You must verify your email before you may login."}

  def check_password_if_account_active(
        %{account_active: true, credentials: credentials},
        password
      ) do
    case Auth.check_password(credentials, password) do
      :ok ->
        {:ok, {session_data, hashed_remember_token}} = Auth.create_session_data(credentials.id)

        {:ok, _} =
          %Credential{id: credentials.id}
          |> Credential.add_hashed_remember_token_changeset(%{
            hashed_remember_token: hashed_remember_token
          })
          |> Repo.update()

        {:ok, session_data}

      {:error, failed_password_match_message} ->
        {:error, failed_password_match_message}
    end
  end

  def retrieve_credentials_by_id(id), do: Repo.get(Credential, id)
  def retrieve_users_credentials_by_email(email), do: Repo.get_by(Credential, email: email)

  defp retrieve_user_with_credentials_by_username(username),
    do: Repo.get_by(User, username: username) |> IO.inspect() |> Repo.preload([:credentials])

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

  def remove_hashed_remember_token(user_id) do
    IO.puts("removing hashed remember token")
    IO.inspect(user_id)
    # credential = Repo.get_by(Dbstore.Credential, user_id: 1)
    update_query =
      from(c in Credential,
        where: c.user_id == ^user_id,
        update: [set: [hashed_remember_token: nil]]
      )

    case update_query |> Repo.update_all([]) do
      {1, nil} ->
        {:ok, "Successfully removed the remove_hashed_remember_token from user's credentials."}

      {_, nil} ->
        {:error, "Unable to retrieve the credential."}

      _ ->
        {:error, "Oops, something went wrong."}
    end
  end
end
