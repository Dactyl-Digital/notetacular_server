defmodule BackendWeb.AuthController do
  use BackendWeb, :controller
  import Backend.AuthPlug
  import Bamboo

  # NOTE: this plug will only be ran for the logout controller within this module
  # Thanks to the handy TIL posts https://til.hashrocket.com/posts/ee98c8a632-use-elixir-plug-for-only-some-controller-actions
  plug(:authorize_user when action in [:logout])

  def csrf(conn, _params) do
    csrf_token = get_csrf_token()
    json(conn, %{csrf_token: csrf_token})
  end

  def verify_email(conn, %{"email_verification_token" => _token, "email" => _email} = params) do
    with {:ok, %{account_active: true}} <- Auth.verify_email(params) do
      conn |> put_status(200) |> json(%{message: "You've successfully verified your email!"})
    else
      {:error, "UNAUTHORIZED_REQUEST"} ->
        conn |> put_status(401) |> json(%{message: "UNAUTHORIZED_REQUEST"})

      _ ->
        # TODO: Implement a resend email verification link email just incase all sorts
        #       of fuckery happened that would prevent a user from completing the signup process?
        conn |> put_status(500) |> json(%{message: "Oops... Something went wrong."})
    end
  end

  def signup(conn, %{
        "email" => email,
        "username" => username,
        "password" => password
      }) do
    with {:ok, _user} <-
           Accounts.create_user(%{email: email, username: username, password: password}),
         %Bamboo.Email{} <-
           Backend.Email.deliver_email_verification_email(email) do
      conn |> put_status(201) |> json(%{message: "Please verify your email"})
    else
      {:error, errors} ->
        conn |> put_status(400) |> json(%{errors: errors})

      _ ->
        conn |> put_status(500) |> json(%{message: "Oops... Something went wrong."})
    end
  end

  # NOW TODO:
  # Start setting up the controllers for creating and reading Notebook resources
  # First order of business will be getting the plug which pulls off the session cookie
  # and retrieves the user's credential resource to grab the user_id
  def login(conn, %{
        "username" => username,
        "password" => password
      }) do
    with {:ok, session_data} <- Accounts.login_user(%{username: username, password: password}) do
      conn
      |> put_session(:session_data, session_data)
      |> put_status(200)
      |> json(%{message: "You've successfully logged in."})
    else
      {:error, failed_password_match_message} ->
        conn |> put_status(400) |> json(%{message: failed_password_match_message})

      _ ->
        conn |> put_status(500) |> json(%{message: "Oops... Something went wrong."})
    end
  end

  def logout(conn, _params) do
    %{current_user: current_user} = conn.assigns

    with {:ok, "Successfully removed the remove_hashed_remember_token from user's credentials."} <-
           Accounts.remove_hashed_remember_token(current_user.user_id) do
      conn
      |> delete_session(:session_data)
      |> put_status(200)
      |> json(%{message: "LOGOUT_SUCCESS"})
    else
      {:error, "Unable to retrieve the credential."} ->
        conn |> put_status(500) |> json(%{message: "Invalid Request."})

      {:error, "Oops, something went wrong."} ->
        conn |> put_status(500) |> json(%{message: "Oops... Something went wrong."})
    end
  end
end
