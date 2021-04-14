defmodule GagaWeb.Plugs.SetUser do
  import Plug.Conn

  def init(_params) do
  end

  def call(conn, _params) do
    token = get_req_header(conn, "authorization")

    case Phoenix.Token.verify(
           GagaWeb.Endpoint,
           System.get_env("TOKEN_SECRET"),
           List.first(token)
         ) do
      {:ok, user_id} ->
        conn
        |> assign(:user_id, user_id)

      {:error, _reason} ->
        conn
        |> assign(:user_id, 0)
    end
  end
end
