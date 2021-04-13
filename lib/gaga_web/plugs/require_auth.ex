defmodule GagaWeb.Plugs.RequireAuth do
  import Plug.Conn
  import Phoenix.Controller

  def init(_params) do
  end

  def call(conn, _params) do
    if conn.assigns[:user] do
      conn
    else
      conn
      |> halt()
    end
  end
end
