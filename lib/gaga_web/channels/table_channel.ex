defmodule GagaWeb.TableChannel do
  use GagaWeb, :channel

  def join("tables:" <> room_id, _params, socket) do
    IO.inspect(socket)

    if(socket.assigns["users"]) do
      socket =
        assign(
          socket,
          :users,
          Map.merge(socket.assigns.users, %{"socket.assigns.user_id" => 10000})
        )

      {:ok, socket}
    else
      user_id = socket.assigns.user_id
      socket = assign(socket, :users, %{user_id => 10000})
      IO.inspect(socket)
      {:ok, socket}
    end
  end

  def handle_in(_name, _body, socket) do
    IO.inspect(socket)
    {:reply, :ok, socket}
  end
end
