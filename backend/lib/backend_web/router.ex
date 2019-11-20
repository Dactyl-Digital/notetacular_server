defmodule BackendWeb.Router do
  use BackendWeb, :router

  pipeline :test do
    plug(CORSPlug, origin: "*")
    plug(:accepts, ["json"])
  end

  pipeline :api do
    origin =
      if Mix.env() === :prod do
        "notastical.com"
      else
        "http://localhost:7000"
      end

    IO.puts("the origin is set as:")
    IO.inspect(origin)
    plug(CORSPlug, origin: origin)
    plug(:accepts, ["json"])
  end

  pipeline :admin do
    plug(CORSPlug, origin: "http://localhost:8000")
    plug(:accepts, ["json"])
  end

  scope "/test", BackendWeb do
    pipe_through(:test)

    get("/test", TestApiController, :test)
  end

  scope "/api", BackendWeb do
    pipe_through(:api)

    get("/test", TestApiController, :test)
    # Usage in the email template which will be sent to user:
    # The key is that the helper function will be based on the controller name
    # i.e. Backend.Router.Helpers.auth_path(Backend.Endpoint, :verify_email, %{} = params)
    get("/verify-email", AuthController, :verify_email)
    
    post("/signup", AuthController, :signup)
  end

  scope "/admin", BackendWeb do
    pipe_through(:admin)

    get("/test", TestAdminController, :test)
  end
end
