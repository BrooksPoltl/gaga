defmodule GagaWeb.TableChannel do
  use GagaWeb, :channel
  alias Gaga.Poker
  alias Gaga.Repo

  intercept ["get_table", "new_event", "new_turn", "new_game"]

  def join("tables:" <> room_id, _params, socket) do
    user_id = socket.assigns.user_id
    Poker.join_room(%{user_id: user_id, room_id: room_id, sitting_out: false})
    :ok = ChannelWatcher.monitor(:tables, self(), {__MODULE__, :leave, [room_id, user_id]})
    {:ok, assign(socket, :room_id, room_id)}
  end

  def handle_in("get_table", body, socket) do
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
      big_user_index == 0 ->
        broadcast(socket, "new_turn", %{
          user_id: Enum.at(msg.hands, length(msg.hands) - 1).user_id,
          hands: msg.hands
        })

      true ->
        broadcast(socket, "new_turn", %{
          user_id: Enum.at(msg.hands, big_user_index - 1).user_id,
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

  def handle_in("new_game", body, socket) do
    game = Poker.get_game_by_room_id(socket.assigns.room_id)
    hands = Poker.get_hands_by_game_id(body.game_id)

    broadcast(socket, "new_game", %{
      game: game,
      hands: hands
    })
  end

  def handle_out("new_game", msg, socket) do
    hands = blur_other_hands(msg.hands, socket.assigns.user_id)

    push(
      socket,
      "new_game",
      %{game: msg.game, hands: hands, user_id: msg.user_id}
    )

    {:noreply, socket}
  end

  def handle_in("new_event", %{"body" => body}, socket) do
    # Validate that the right person is betting
    game_id = Map.get(body, "gameId")
    active_user_id = Poker.find_active_user_by_game_id(game_id)

    if active_user_id == socket.assigns.user_id do
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
          next_user_id = Poker.find_active_user_by_game_id(game_id)

          hands = Poker.get_hands_by_game_id(game_id)

          broadcast!(socket, "new_event", %{
            type: "call",
            amt: amount_to_call,
            game_id: game_id,
            user_id: socket.assigns.user_id,
            turn: %{user_id: next_user_id, hands: hands}
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
            room_id = socket.assigns.room_id
            users = Poker.get_users_at_table(room_id)
            game_id = start_game(users, room_id, false, game_id)
            game = Poker.get_game_by_room_id(socket.assigns.room_id)
            hands = Poker.get_hands_by_game_id(game_id)
            user_id = Poker.find_active_user_by_game_id(game_id)
            broadcast!(socket, "new_game", %{game: game, hands: hands, user_id: user_id})
          else
            next_user_id = Poker.find_active_user_by_game_id(game_id)

            hands = Poker.get_hands_by_game_id(game_id)

            broadcast!(socket, "new_event", %{
              type: "fold",
              amt: 0,
              game_id: game_id,
              user_id: socket.assigns.user_id,
              turn: %{user_id: next_user_id, hands: hands}
            })
          end

        Map.get(body, "event") ==
            "raise" ->
          IO.inspect(body)
          amount_to_call = Poker.calculate_amount_to_call(socket.assigns.user_id, game_id)
          # TODO: add validation to make sure its a valid raise and they are capable
          raise_amount = amount_to_call + Map.get(body, "amt")

          event = %{
            type: "raise",
            user_id: socket.assigns.user_id,
            game_id: game_id,
            amount: raise_amount,
            inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
            updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
          }

          Poker.create_event(event)
          next_user_id = Poker.find_active_user_by_game_id(game_id)

          hands = Poker.get_hands_by_game_id(game_id)

          broadcast!(socket, "new_event", %{
            type: "raise",
            amt: Map.get(body, "amt"),
            game_id: game_id,
            user_id: socket.assigns.user_id,
            turn: %{user_id: next_user_id, hands: hands}
          })
      end

      # Send event request to the next person
    end

    {:reply, {:ok, []}, socket}
  end

  def handle_out("new_turn", msg, socket) do
    hands = blur_other_hands(msg.hands, socket.assigns.user_id)

    push(
      socket,
      "new_turn",
      %{user_id: msg.user_id, hands: hands}
    )

    {:noreply, socket}
  end

  def handle_out("new_event", msg, socket) do
    hands = blur_other_hands(msg.turn.hands, socket.assigns.user_id)
    # TODO: this should probably happen higher rather than for every person
    is_end_of_round? = Poker.get_round_and_check_if_end(msg.game_id)

    if is_end_of_round? do
      game = Poker.increment_round_and_get_game(msg.game_id)

      new_hands =
        hands
        |> Enum.map(fn x -> Map.replace(x, :amount_bet_this_round, 0) end)

      push(
        socket,
        "new_event",
        %{
          type: msg.type,
          amt: msg.amt,
          user_id: msg.user_id,
          game: game,
          turn: %{user_id: msg.turn.user_id, hands: new_hands}
        }
      )
    else
      push(
        socket,
        "new_event",
        %{
          type: msg.type,
          amt: msg.amt,
          user_id: msg.user_id,
          turn: %{user_id: msg.turn.user_id, hands: hands}
        }
      )
    end

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
  def start_game(table, room_id, first_game \\ true, prev_game_id \\ 0) do
    if first_game do
      big_user = Enum.at(table, 0)
      small_user = Enum.at(table, 1)
      game_id = create_game(table, room_id, big_user.user_id, small_user.user_id)
      game_id
    else
      # logic to determine big/small blinds
      # big and small blind might leave table.
      next_blinds = Poker.get_next_blind_user_ids(table, prev_game_id)
      # if they do we need to still get their created dates to use their dates
      game_id = create_game(table, room_id, next_blinds.big_user_id, next_blinds.small_user_id)
      game_id
    end
  end

  def leave(room_id, user_id) do
    # Remove user from room
    Poker.leave_room(user_id, room_id)
    # TODO: If its the last user delete the room
    # TODO: Need to find way to handle disconnects that would end game
    # TODO: wait a little after disconnect to determine if they need to be removed
    # TODO: trigger event for a disconnect or message is probably best if we build messages
    IO.inspect("USER IS LEAVING")
  end
end
