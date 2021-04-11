defmodule GagaWeb.Router do
  use GagaWeb, :router

  pipeline :api do
    plug(CORSPlug, origin: "*")
    plug(:accepts, ["json"])
  end

  scope "/api", GagaWeb do
    pipe_through(:api)

    get("/", UserController, :index)
    options("/", UserController, :options)
    post("/", UserController, :create)
  end
end
