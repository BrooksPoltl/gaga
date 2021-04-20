defmodule GagaWeb.TableChannel do
  use GagaWeb, :channel
  alias Gaga.Poker

  def join("tables:" <> room_id, _params, socket) do
    # todo: implement monitoring
    user_id = socket.assigns.user_id
    Poker.join_room(%{user_id: user_id, room_id: room_id, sitting_out: false})
    users = Poker.get_users_at_table(room_id)

    :ok = ChannelWatcher.monitor(:tables, self(), {__MODULE__, :leave, [room_id, user_id]})
    {:ok, users, socket}
  end

  def handle_in(_name, _body, socket) do
    IO.inspect(socket)
    {:reply, :ok, socket}
  end

  def leave(room_id, user_id) do
    # Remove user from room
    Poker.leave_room(user_id, room_id)
    IO.inspect("USER IS LEAVING")
    IO.inspect(room_id)
    IO.inspect(user_id)
  end
end
