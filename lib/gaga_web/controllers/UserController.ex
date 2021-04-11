defmodule GagaWeb.UserController do
  use GagaWeb, :controller
  alias Gaga.Accounts
  alias Gaga.Accounts.User

  def index(conn, params) do
    users = Accounts.list_users()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(users))
  end

  def create(conn, %{"name" => name}) do
    IO.inspect(name)

    case Accounts.create_user(%{name: name}) do
      {:ok, user} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(user))

      {:error} ->
        {:error, conn}
    end
  end

  def options(conn, params) do
  end
end
