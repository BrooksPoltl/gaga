defmodule GagaWeb.TableChannel do
  use GagaWeb, :channel
  alias Gaga.Poker
  alias Gaga.Repo

  intercept ["get_table"]

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
      game_id = start_game(table_users, room_id)
      game = Poker.get_game_by_room_id(room_id)
      hands = Poker.get_hands_by_game_id(game_id)

      broadcast(socket, "get_table", %{
        game: game,
        hands: hands,
        new_game: true
      })

      # create hands for each player
    else
      game = Poker.get_game_by_room_id(room_id)
      hands = Poker.get_hands_by_game_id(game.id)
      broadcast(socket, "get_table", %{game: game, hands: hands, new_game: false})
    end

    {:reply, {:ok, []}, socket}
  end

  def handle_out("get_table", msg, socket) do
    game = %{
      id: msg.game.id,
      big_user_id: msg.game.big_user_id,
      small_user_id: msg.game.small_user_id,
      card1:
        if msg.game.shown_flop do
          msg.game.card1
        else
          nil
        end,
      card2:
        if msg.game.shown_flop do
          msg.game.card2
        else
          nil
        end,
      card3:
        if msg.game.shown_flop do
          msg.game.card1
        else
          nil
        end,
      card4:
        if msg.game.shown_turn do
          msg.game.card4
        else
          nil
        end,
      card5:
        if msg.game.shown_river do
          msg.game.card5
        else
          nil
        end
    }

    hands =
      Enum.map(msg.hands, fn h ->
        if h.user_id == socket.assigns.user_id do
          h
        else
          h
          |> Map.put(:card1, nil)
          |> Map.put(:card2, nil)
        end
      end)

    big_user_index = Enum.find_index(hands, fn x -> game.big_user_id == x.user_id end)
    IO.inspect(big_user_index)

    if socket.assigns.user_id do
    end

    push(
      socket,
      "get_table",
      %{game: game, hands: hands}
    )

    {:noreply, socket}
  end

  def create_game(table, room_id, big_user_id, small_user_id) do
    {new_table, flop} = PokerLogic.create_game(table)
    {:ok, game} = Poker.create_game(flop, room_id, big_user_id, small_user_id)

    formatted_hands =
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

    Poker.create_hands(formatted_hands)
    game.id
  end

  # If when you join and there are now 2 players start game
  # If game already in progress wait
  def start_game(table, room_id, first_game \\ true) do
    IO.inspect(table)

    if first_game do
      big_user = Enum.at(table, 0)
      small_user = Enum.at(table, 1)
      game_id = create_game(table, room_id, big_user.user_id, small_user.user_id)
      game_id
    else
      # logic to determine big/small blinds
    end
  end

  def leave(room_id, user_id) do
    # Remove user from room
    Poker.leave_room(user_id, room_id)
    # TODO: If its the last user delete the room
    # TODO: Need to find way to handle disconnects that would end game
    # TODO: wait a little after disconnect to determine if they need to be removed
    IO.inspect("USER IS LEAVING")
  end
end
