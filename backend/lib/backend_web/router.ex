defmodule BackendWeb.Router do
  use BackendWeb, :router

  pipeline :api do
    plug CORSPlug, origin: "http://localhost:7000"
    plug :accepts, ["json"]
  end

  pipeline :admin do
    plug CORSPlug, origin: "http://localhost:8000"
    plug :accepts, ["json"]
  end

  scope "/api", BackendWeb do
    pipe_through :api

    # UserControllers
    get("/test", TestApiController, :test)
  end

  scope "/admin", BackendWeb do
    pipe_through :admin

    # UserControllers
    get("/test", TestAdminController, :test)
  end
end
