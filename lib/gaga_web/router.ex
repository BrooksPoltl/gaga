defmodule GagaWeb.Router do
  use GagaWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
    plug(CORSPlug, origin: "*")
  end

  scope "/api", GagaWeb do
    pipe_through(:api)
    get("/")
  end
end
