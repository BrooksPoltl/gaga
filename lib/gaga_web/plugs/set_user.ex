defmodule GagaWeb.Plugs.SetUser do
  import Plug.Conn

  def init(_params) do
  end

  def call(conn, _params) do
    token = get_req_header(conn, "authorization")

    cond do
      {:ok, user_id} =
          Phoenix.Token.verify(
            GagaWeb.Endpoint,
            "dadmfmi2q0mr2m",
            List.first(token)
          ) ->
        assign(conn, :user_id, user_id)

      true ->
        assign(conn, :user_id, 0)
    end
  end
end
