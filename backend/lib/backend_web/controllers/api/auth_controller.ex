defmodule BackendWeb.AuthController do
  use BackendWeb, :controller

  def verify_email(conn, %{"token" => token, "email" => email} = params) do
    Auth.verify_email(params)
  end
end