defmodule Backend.AuthPlug do
  import Plug.Conn
  alias Accounts
  alias Auth
  alias Backend.Helpers
  
  def authorize_user(conn, _opts) do
    get_session(conn, :session_token)
    |> Auth.check_authorization(fn username -> Accounts.retrieve_user_by_username(username) end)
    |> assign_user_to_conn(conn)
  end
  
  defp assign_user_to_conn({:ok, user}, conn), do: conn |> set_session(user)
  defp assign_user_to_conn({:error, _msg}, conn), do: conn |> clean_session()
  
  defp set_session(conn, user), do: conn |> assign(:current_user, user.username)

  # Prefer this... but it seems as though there's a decent amount of coupling
  # Especially since I wanted to move this plug into a separate app to facilitate reuse...
  defp clean_session(conn) do
    conn
    |> delete_session(:session_token)
    |> assign(:current_user, nil)
    |> Helpers.send_client_response(400, %{message: "Invalid session"})
  end
end