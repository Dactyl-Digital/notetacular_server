defmodule BackendWeb.Router do
  use BackendWeb, :router

  pipeline :test do
    plug(CORSPlug, origin: "*")
    plug(:accepts, ["json"])
    plug(:fetch_session)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
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
    plug(:fetch_session)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :admin do
    plug(CORSPlug, origin: "http://localhost:8000")
    plug(:accepts, ["json"])
    plug(:fetch_session)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  scope "/test", BackendWeb do
    pipe_through(:test)

    get("/test", TestApiController, :test)
  end

  scope "/api", BackendWeb do
    pipe_through(:api)

    get("/test", TestApiController, :test)

    # Auth Controllers
    get("/csrf", AuthController, :csrf)
    # Usage in the email template which will be sent to user:
    # The key is that the helper function will be based on the controller name
    # i.e. Backend.Router.Helpers.auth_path(Backend.Endpoint, :verify_email, %{} = params)
    get("/verify-email", AuthController, :verify_email)
    post("/signup", AuthController, :signup)
    post("/login", AuthController, :login)

    # Notebook Controllers
    post("/notebook", NotebookController, :create_notebook)
    get("/notebook", NotebookController, :list_notebooks)

    # Sub Category Controllers
    post("/sub_category", SubCategoryController, :create_sub_category)
    get("/sub_category", SubCategoryController, :list_sub_categories)

    # Topic Controllers
    post("/topic", TopicController, :create_topic)
    get("/topic", TopicController, :list_topics)

    # Note Controllers
    post("/note", NoteController, :create_note)
    get("/note", NoteController, :list_notes)
  end

  scope "/admin", BackendWeb do
    pipe_through(:admin)

    get("/test", TestAdminController, :test)
  end
end
