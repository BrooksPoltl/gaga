defmodule GagaWeb.Plugs.SetUser do
  import Plug.Conn

  alias Discuss.Repo
  alias Discuss.Accounts.User

  def init(_params) do
  end

  def call(conn, _params) do
    conn
    |> fetch_session(conn)
  end
end
