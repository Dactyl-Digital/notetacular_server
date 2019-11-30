defmodule Backend.AuthPlug do
  # use BackendWeb, :controller
  import Plug.Conn
  alias Accounts
  alias Auth
  # alias Backend.Helpers

  def authorize_user(conn, _opts) do
    get_session(conn, :session_data)
    |> Auth.check_authorization(fn id -> Accounts.retrieve_credentials_by_id(id) end)
    |> assign_user_to_conn(conn)
  end

  defp assign_user_to_conn({:ok, %{user_id: _id} = current_user}, conn),
    do: conn |> set_session(current_user)

  defp assign_user_to_conn({:error, _msg}, conn), do: conn |> clean_session()

  defp set_session(conn, current_user), do: conn |> assign(:current_user, current_user)

  # Prefer this... but it seems as though there's a decent amount of coupling
  # Especially since I wanted to move this plug into a separate app to facilitate reuse...
  defp clean_session(conn) do
    conn
    |> delete_session(:session_data)
    |> assign(:current_user, nil)
    |> put_status(400)
    |> Phoenix.Controller.json(%{message: "Invalid session"})
    |> halt
  end
end
