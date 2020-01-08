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
        # NOTE: For the CORS error that was occuring in prod/
        # Adding this array fixed it.... But which one accurately
        # reflects the origin which my client sets in the header?
        ["https://notastical.com", "https://www.notastical.com"]
      else
        "http://localhost:8000"
      end

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
    # WTF:
    # Request from production client site sends request...
    # Running production server response w/
    # 08:33:20.420 [info] OPTIONS /api/signup
    # 08:33:20.421 [info] Sent 204 in 922µs
    # I never sent a 204 response in the controller.... so what gives?
    # ANSWER: It was a CORS issue still, wasn't configured properly when running in
    # prod when the error was encounted. Adding this -> ["https://notastical.com", "https://www.notastical.com"]
    # as the cors origin fixed it.
    post("/signup", AuthController, :signup)
    # NOTE: using this *options* is necessary otherwise CORS issues
    #       regarding Allow-Access-Control-Headers not being set by the
    #       backend pop up.
    options("/signup", AuthController, :options)
    post("/login", AuthController, :login)
    post("/logout", AuthController, :logout)
    options("/login", AuthController, :options)
    options("/logout", AuthController, :options)

    # Notebook Controllers
    post("/notebook", NotebookController, :create_notebook)
    get("/notebook", NotebookController, :list_notebooks)
    get("/notebook/sub-categories", NotebookController, :retrieve_notebook_with_sub_categories)
    delete("/notebook/:id", NotebookController, :delete_notebook)
    delete("/notebook/:id", NoteController, :delete_notebook)
    options("/notebook", NotebookController, :options)
    options("/notebook/:id", NotebookController, :options)

    # Sub Category Controllers
    post("/sub-category", SubCategoryController, :create_sub_category)
    get("/sub-category", SubCategoryController, :list_sub_categories)
    get("/sub-category/topics", SubCategoryController, :retrieve_sub_category_with_topics)
    delete("/sub-category/:id", SubCategoryController, :delete_sub_category)
    options("/sub-category", SubCategoryController, :options)
    options("/sub-category/:id", SubCategoryController, :options)

    # Topic Controllers
    post("/topic", TopicController, :create_topic)
    get("/topic", TopicController, :list_topics)
    delete("/topic/:id", TopicController, :delete_topic)
    post("/topic/tags", TopicController, :add_tags)
    patch("/topic/tags", TopicController, :remove_tag)
    options("/topic", TopicController, :options)
    options("/topic/tags", TopicController, :options)
    options("/topic/:id", TopicController, :options)

    # Note Controllers
    post("/note", NoteController, :create_note)
    get("/note", NoteController, :list_notes)
    delete("/note/:id", NoteController, :delete_note)
    put("/note/content", NoteController, :update_note_content)
    post("/note/tags", NoteController, :add_tags)
    patch("/note/tags", NoteController, :remove_tag)
    get("/note/search", NoteController, :search_notes)
    options("/note", NoteController, :options)
    options("/note/content", NoteController, :options)
    options("/note/tags", NoteController, :options)
    options("/note/search", NoteController, :options)
    options("/note/:id", NoteController, :options)

    # Note Timer Controllers
    post("/note-timer", NoteController, :create_note_timer)
    get("/note-timer", NoteController, :list_note_timers)
    patch("/note-timer", NoteController, :update_note_timer)
    options("/note-timer", NoteController, :options)
    delete("/note-timer/:id", NoteController, :delete_note_timer)
    options("/note-timer/:id", NoteController, :options)
  end

  scope "/admin", BackendWeb do
    pipe_through(:admin)

    get("/test", TestAdminController, :test)
  end
end
