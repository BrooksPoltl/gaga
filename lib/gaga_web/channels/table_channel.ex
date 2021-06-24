defmodule GagaWeb.TableChannel do
  use GagaWeb, :channel
  alias Gaga.Poker
  alias Gaga.Repo

  intercept ["get_table", "new_turn"]

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
    cond do
      length(table_users) == 2 ->
        game_id = start_game(table_users, room_id)
        game = Poker.get_game_by_room_id(room_id)
        hands = Poker.get_hands_by_game_id(game_id)

        broadcast(socket, "get_table", %{
          game: game,
          hands: hands,
          new_game: true
        })

      length(table_users) == 1 ->
        nil

      true ->
        game = Poker.get_game_by_room_id(room_id)
        hands = Poker.get_hands_by_game_id(game.id)
        broadcast(socket, "get_table", %{game: game, hands: hands, new_game: false})
    end

    {:reply, {:ok, []}, socket}
  end

  def blur_other_hands(hands, user_id) do
    Enum.map(hands, fn h ->
      if h.user_id == user_id do
        h
      else
        h
        |> Map.put(:card1, nil)
        |> Map.put(:card2, nil)
      end
    end)
  end

  def handle_out("get_table", msg, socket) do
    big_user_index = Enum.find_index(msg.hands, fn x -> msg.game.big_user_id == x.user_id end)

    cond do
      big_user_index + 1 == length(msg.hands) ->
        broadcast(socket, "new_turn", %{user: Enum.at(msg.hands, 0).user_id, hands: msg.hands})

      true ->
        broadcast(socket, "new_turn", %{
          user: Enum.at(msg.hands, big_user_index + 1).user_id,
          hands: msg.hands
        })
    end

    push(
      socket,
      "get_table",
      %{game: msg.game}
    )

    {:noreply, socket}
  end

  def handle_in("new_event", %{"body" => body}, socket) do
    # Validate that the right person is betting
    game_id = Map.get(body, "gameId")
    active_user = Poker.find_active_user_by_game_id(game_id)

    if active_user.user_id == socket.assigns.user_id do
      # Create the event
      cond do
        Map.get(body, "event") ==
            "call" ->
          amount_to_call = Poker.calculate_amount_to_call(socket.assigns.user_id, game_id)

          event = %{
            type: "call",
            user_id: socket.assigns.user_id,
            game_id: game_id,
            amount: amount_to_call,
            inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
            updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
          }

          Poker.create_event(event)
          next_user = Poker.find_active_user_by_game_id(game_id)

          hands = Poker.get_hands_by_game_id(game_id)

          broadcast!(socket, "new_turn", %{user: next_user.user_id, hands: hands})

          broadcast!(socket, "new_event", %{
            type: "call",
            amt: amount_to_call,
            user_id: socket.assigns.user_id
          })

        Map.get(body, "event") ==
            "fold" ->
          event = %{
            type: "fold",
            user_id: socket.assigns.user_id,
            game_id: game_id,
            amount: 0,
            inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
            updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
          }

          is_game_over? = Poker.create_event(event)

          if is_game_over? do
            # start_game()
          else
            next_user = Poker.find_active_user_by_game_id(game_id)

            hands = Poker.get_hands_by_game_id(game_id)

            broadcast!(socket, "new_turn", %{user: next_user.user_id, hands: hands})

            broadcast!(socket, "new_event", %{
              type: "fold",
              amt: 0,
              user_id: socket.assigns.user_id
            })
          end
      end

      # Send event request to the next person
    end

    {:reply, {:ok, []}, socket}
  end

  def handle_out("new_turn", msg, socket) do
    IO.inspect(socket.assigns.user_id)
    hands = blur_other_hands(msg.hands, socket.assigns.user_id)

    push(
      socket,
      "new_turn",
      %{user: msg.user, hands: hands}
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
