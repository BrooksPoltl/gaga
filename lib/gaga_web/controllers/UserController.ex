defmodule GagaWeb.UserController do
  use GagaWeb, :controller
  alias Gaga.Accounts

  def index(conn, _params) do
    case Accounts.get_user!(conn.assigns.user_id) do
      user ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(user))
    end
  end

  def create(conn, %{"name" => name}) do
    case Accounts.create_user(%{name: name}) do
      {:ok, user} ->
        IO.inspect(user)
        token = Phoenix.Token.sign(GagaWeb.Endpoint, System.get_env("TOKEN_SECRET"), user.id)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(201, Jason.encode!(%{"user" => user, "token" => token}))

      {:error} ->
        {:error, conn}
    end
  end

  def options(conn, params) do
  end
end
