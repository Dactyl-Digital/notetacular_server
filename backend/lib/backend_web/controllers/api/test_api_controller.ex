defmodule BackendWeb.TestApiController do
  use BackendWeb, :controller

  def test(conn, _params) do
    # csrf_token = get_csrf_token()
    json(conn, %{message: "YOU HIT THE TEST API CONTROLLER"})
  end
end
