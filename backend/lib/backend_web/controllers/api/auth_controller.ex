defmodule BackendWeb.AuthController do
  use BackendWeb, :controller

  def signup(conn, %{
    "email" => email,
    "username" => username,
    "password" => password
  }) do
    # TODO: send back proper JSON responses.
   when {:ok, user} <- create_user(%{email: email, username: username, password: password}),
        {:deliveed_email, _email} <- deliver_email_verification_email(email)
    do
      {:ok, "Please verify your email"}
    else
      {:err, errors} ->
        {:err, errors}
      _ ->
        {:err, "Oops... Something went wrong."}
    end
  end
  
  def verify_email(conn, %{"token" => token, "email" => email} = params) do
    Auth.verify_email(params)
  end
end