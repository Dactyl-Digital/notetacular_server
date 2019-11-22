defmodule BackendWeb.AuthController do
  use BackendWeb, :controller

  def csrf(conn, _params) do
    csrf_token = get_csrf_token()
    json(conn, %{csrf_token: csrf_token})
  end
  
  def signup(conn, %{
    "email" => email,
    "username" => username,
    "password" => password
  }) do
   with {:ok, _user} <- Accounts.create_user(%{email: email, username: username, password: password}),
        {_, {:delivered_email, _email}} <- Backend.Email.deliver_email_verification_email(email)
    do
      conn |> put_status(201) |> json(%{message: "Please verify your email"})
    else
      {:err, errors} ->
        conn |> put_status(400) |> json(%{errors: errors})
      _ ->
        conn |> put_status(500) |> json(%{message: "Oops... Something went wrong."})
    end
  end
  
  def verify_email(conn, %{"email_verification_token" => _token, "email" => _email} = params) do
    with {:ok, %{account_active: true}} <- Auth.verify_email(params)
      do
        conn |> put_status(200) |> json(%{message: "You've successfully verified your email!"})
      else
        {:err, "UNAUTHORIZED_REQUEST"} ->
          conn |> put_status(401) |> json(%{message: "UNAUTHORIZED_REQUEST"})
        _ ->
          # TODO: Implement a resend email verification link email just incase all sorts
          #       of fuckery happened that would prevent a user from completing the signup process?
          conn |> put_status(500) |> json(%{message: "Oops... Something went wrong."})
      end
  end
end