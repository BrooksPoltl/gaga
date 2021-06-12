defmodule GagaWeb.TableChannel do
  use GagaWeb, :channel
  alias Gaga.Poker
  alias Gaga.Repo

  def join("tables:" <> room_id, _params, socket) do
    user_id = socket.assigns.user_id
    Poker.join_room(%{user_id: user_id, room_id: room_id, sitting_out: false})
    :ok = ChannelWatcher.monitor(:tables, self(), {__MODULE__, :leave, [room_id, user_id]})
    {:ok, assign(socket, :room_id, room_id)}
  end

  def handle_in("get_table", _body, socket) do
    room_id = socket.assigns.room_id
    table_users = Poker.get_users_at_table(room_id)
    # TODO: probably need a way to check if the game is in progress
    if length(table_users) == 2 do
      {new_table, flop} = start_game(table_users)
      user = Enum.find(new_table, fn x -> x.user_id == socket.assigns.user_id end)
      # create a game
      Poker.create_game(flop, room_id)

      # create hands for each player
      {:reply, {:ok, []}, assign(socket, :hand, user.hand)}
    end
  end

  # If when you join and there are now 2 players start game
  # If game already in progress wait
  def start_game(table) do
    PokerLogic.create_game(table)
  end

  def leave(room_id, user_id) do
    # Remove user from room
    Poker.leave_room(user_id, room_id)
    # TODO: If its the last user delete the room
    # TODO: Need to find way to handle disconnects that would end game
    IO.inspect("USER IS LEAVING")
  end
end
