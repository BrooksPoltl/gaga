defmodule GagaWeb.RoomController do
  use GagaWeb, :controller
  alias Gaga.Poker
  alias Gaga.Repo

  def index(conn, _params) do
    case Poker.list_rooms() do
      rooms ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(rooms))
    end
  end

  def create(conn, %{"room" => name}) do
    user_id = conn.assigns.user_id

    case Poker.create_room(name, user_id) do
      {:ok, room} ->
        roomWithUser = Repo.preload(room, user: [:room])

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(201, Jason.encode!(%{"room" => roomWithUser}))

      {:error} ->
        {:error, conn}
    end
  end

  def options(conn, params) do
  end
end
