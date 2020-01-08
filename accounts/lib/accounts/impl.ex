defmodule Accounts.Impl do
  @moduledoc """
  Documentation for Accounts.Impl
  """
  import Ecto.Query
  alias Ecto.Changeset
  alias Dbstore.{Repo, Helpers, User, Credential, Permissions}

  # Key for hashing the user's remember_token TODO: (This is duplicated in backend/temp/auth_plug.ex)
  # mix phx.gen.secret [length]
  # WARNING: This is duplicated in the backend project's auth_plug.ex file
  # Application.get_env(:backend, :hash_key)
  # TODO: keep @hash_key secret in prod
  # Ensure that using the Application.get_env approach for the remember_token hash_key
  # will work in prod.
  @hash_key "7b8lEvA2aWxGB1f2MhBjhz8YRf1p21fgTxn8Qf6KciM9IJCaJ9aIn4SNna0FybxZ"
  @remember_token_bytes 32

  @email_regex ~r/.+@.+\.+/i
  @valid_username_regex ~r/[A-Za-z0-9_-]+/
  # Preventing XSS attacks (only the characters in the
  # regex are allowed.):
  # String.match?("<username>", reg_ex)
  # false
  # iex(3)> String.match?("username", reg_ex)
  # true

  # Status Codes
  @created_code 201
  @bad_request_code 400
  @forbidden_code 403

  # Response Messages
  @signup_success_message "You've successfully signed up!"
  @login_success_message "You've successfully logged in!"
  @something_went_wrong_message "Oops... Something went wrong. Please try again."
  @permission_not_found_message "Permission not found"

  ############################
  # VALIDATION FUNCTIONS
  ############################
  @username_length_error_msg "Username must be between 4 and 40 characters."
  @username_invalid_error_msg "Username is invalid."
  @email_length_error_msg "Email must be greater than 8 characters."
  @invalid_email_error_msg "Email is invalid."
  @password_length_min_error_msg "Password must be at least 12 characters."
  @password_length_max_error_msg "Password must be less than 100 characters."

  def validate_length_between(str, min, max, msgFn) do
    satisfies_min? = String.length(str) >= min
    satisfies_max? = String.length(str) <= max

    case satisfies_min? && satisfies_max? do
      true ->
        true

      false ->
        msgFn.(satisfies_min?, satisfies_max?)
    end
  end

  def validate_user_input(:username, username) do
    with trimmed_str <- String.trim(username),
         true <-
           validate_length_between(trimmed_str, 4, 40, fn _, _ ->
             @username_length_error_msg
           end),
         true <- String.match?(trimmed_str, @valid_username_regex) do
      true
    else
      @username_length_error_msg ->
        %{field: "username", message: @username_length_error_msg}

      false ->
        %{field: "username", message: @username_invalid_error_msg}
    end
  end

  def validate_user_input(:email, email) do
    with trimmed_str <- String.trim(email),
         true <-
           validate_length_between(trimmed_str, 8, 60, fn _, _ ->
             @email_length_error_msg
           end),
         true <- String.match?(trimmed_str, @email_regex) do
      true
    else
      @email_length_error_msg ->
        %{field: "email", message: @email_length_error_msg}

      false ->
        %{field: "email", message: @invalid_email_error_msg}
    end
  end

  def validate_user_input(:password, password) do
    with trimmed_str <- String.trim(password),
         true <-
           validate_length_between(trimmed_str, 12, 100, fn min?, max? ->
             password_length_error_message(min?, max?)
           end) do
      true
    else
      @password_length_min_error_msg ->
        %{field: "password", message: @password_length_min_error_msg}

      @password_length_max_error_msg ->
        %{field: "password", message: @password_length_max_error_msg}
    end
  end

  defp password_length_error_message(false, true), do: @password_length_min_error_msg

  defp password_length_error_message(true, false),
    do: @password_length_max_error_msg

  #################################
  # BEGIN DOMAIN HANDLERS
  #################################

  def create_user(%{email: email, username: username, password: password} = params) do
    [[:username, username], [:email, email], [:password, password]]
    |> Enum.map(fn [key, value] -> validate_user_input(key, value) end)
    |> Enum.filter(fn result -> result !== true end)
    |> create_user_or_fail(params)
  end

  @doc """
  If the list received is empty.
  Then all validations were performed successfully.
  """
  defp create_user_or_fail([], %{email: email, username: username, password: password}) do
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

  defp create_user_or_fail(errors, _), do: {:error, errors}

  def login_user(%{username: username, password: password}) do
    retrieve_user_with_credentials_by_username(username)
    |> check_password_if_account_active(password)
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
    do: Repo.get_by(User, username: username) |> Repo.preload([:credentials])

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
