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
      start_game(table_users, room_id)

      # create hands for each player
      {:reply, {:ok, []}, socket}
    end
  end

  # If when you join and there are now 2 players start game
  # If game already in progress wait
  def start_game(table, room_id) do
    {new_table, flop} = PokerLogic.create_game(table)
    # user = Enum.find(new_table, fn x -> x.user_id == socket.assigns.user_id end)
    {:ok, game} = Poker.create_game(flop, room_id)
    IO.inspect(game.id)

    format_hands =
      Enum.map(new_table, fn x ->
        %{
          card1: Enum.at(x.hand, 0),
          card2: Enum.at(x.hand, 1),
          user_id: x.user_id,
          game_id: game.id,
          is_active: true,
          inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
          updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        }
      end)

    Poker.create_hands(format_hands)
  end

  def leave(room_id, user_id) do
    # Remove user from room
    Poker.leave_room(user_id, room_id)
    # TODO: If its the last user delete the room
    # TODO: Need to find way to handle disconnects that would end game
    IO.inspect("USER IS LEAVING")
  end
end
