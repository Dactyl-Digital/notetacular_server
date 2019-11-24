defmodule BackendWeb.AuthController do
  use BackendWeb, :controller

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
         {_, {:delivered_email, _email}} <- Backend.Email.deliver_email_verification_email(email) do
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
      IO.puts("logging user in with session_data")
      IO.inspect(session_data)

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
end

# TODO:
# examples taken from budgetapp:

# def logout_user(conn) do
#   %{email: email} = get_session(conn, :session_token)

#   email
#   |> CredentialServer.remove_hashed_remember_token()
#   |> logout_response(conn)
# end
