defmodule GagaWeb.Router do
  use GagaWeb, :router

  pipeline :api do
    plug(CORSPlug, origin: ["*"])
    plug(:accepts, ["json"])
    plug(GagaWeb.Plugs.SetUser)
  end

  scope "/api", GagaWeb do
    scope "/user" do
      pipe_through(:api)

      get("/", UserController, :index)
      options("/", UserController, :options)
      post("/", UserController, :create)
    end
  end
end
