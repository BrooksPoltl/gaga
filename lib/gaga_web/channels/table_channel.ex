defmodule GagaWeb.TableChannel do
  use GagaWeb, :channel
  alias Gaga.Poker

  def join("tables:" <> room_id, _params, socket) do
    user_id = socket.assigns.user_id
    Poker.join_room(%{user_id: user_id, room_id: room_id, sitting_out: false})
    :ok = ChannelWatcher.monitor(:tables, self(), {__MODULE__, :leave, [room_id, user_id]})
    {:ok, assign(socket, :room_id, room_id)}
  end

  def handle_in("join_get_table", _body, socket) do
    room_id = socket.assigns.room_id
    IO.inspect(room_id)
    table = Poker.get_users_at_table(room_id)
    {:reply, {:ok, table}, assign(socket, :table, table)}
  end

  def leave(room_id, user_id) do
    # Remove user from room
    Poker.leave_room(user_id, room_id)
    # TODO: If its the last user delete the room
    IO.inspect("USER IS LEAVING")
  end
end
