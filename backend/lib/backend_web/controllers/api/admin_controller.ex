defmodule BackendWeb.AdminController do
  use BackendWeb, :controller
  import Backend.AuthPlug

  plug(:authorize_user)

  # PRIORITY TODO:
  # 1. Admin with TopLevel privileges should be able to manually override a user's subscribed_until date
  #    by toggling a flag of subscription_required (add the subscription_required field to the DB) from true to false.
  # And that's really all I care about for now.... YEAH!
  # def verify_email(conn, %{"email_verification_token" => _token, "email" => _email} = params) do
  #   with {:ok, %{account_active: true}} <- Auth.verify_email(params) do
  #     conn |> put_status(200) |> json(%{message: "You've successfully verified your email!"})
  #   else
  #     {:error, "UNAUTHORIZED_REQUEST"} ->
  #       conn |> put_status(401) |> json(%{message: "UNAUTHORIZED_REQUEST"})

  #     _ ->
  #       conn |> put_status(500) |> json(%{message: "Oops... Something went wrong."})
  #   end
  # end
end
