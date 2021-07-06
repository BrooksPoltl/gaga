defmodule GagaWeb.TableChannel do
  use GagaWeb, :channel
  alias Gaga.Poker
  alias Gaga.Repo

  intercept ["get_table", "new_turn", "new_game", "new_event"]

  def join("tables:" <> room_id, _params, socket) do
    user_id = socket.assigns.user_id
    Poker.join_room(%{user_id: user_id, room_id: room_id, sitting_out: false})
    :ok = ChannelWatcher.monitor(:tables, self(), {__MODULE__, :leave, [room_id, user_id]})
    {:ok, assign(socket, :room_id, room_id)}
  end

  def handle_in("get_table", body, socket) do
    room_id = socket.assigns.room_id
    table_users = Poker.get_users_at_table(room_id)
    IO.inspect(table_users)

    cond do
      length(table_users) == 2 ->
        game_id = Helpers.Game.start_game(table_users, room_id)
        game = Poker.get_game_by_room_id(room_id)
        hands = Poker.get_hands_by_game_id(game_id)

        broadcast(socket, "get_table", %{
          game: game,
          hands: hands,
          new_game: true
        })

      length(table_users) <= 1 ->
        nil

      true ->
        game = Poker.get_game_by_room_id(room_id)
        hands = Poker.get_hands_by_game_id(game.id)
        broadcast(socket, "get_table", %{game: game, hands: hands, new_game: false})
    end

    {:reply, {:ok, []}, socket}
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
    Process.sleep(5000)
    hands = PokerLogic.blur_other_hands(msg.hands, socket.assigns.user_id)

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
          call(socket, game_id)

        Map.get(body, "event") ==
            "fold" ->
          fold(socket, game_id)

        Map.get(body, "event") ==
            "raise" ->
          make_raise(socket, game_id, Map.get(body, "amt"))
          nil
      end

      # Send event request to the next person
    end

    {:reply, {:ok, []}, socket}
  end

  def handle_out("new_event", msg, socket) do
    IO.inspect("CREATING A NEW EVENT")

    if msg.type == "all-in" do
      # show all active cards

      new_msg =
        msg
        |> Map.put(:turn, %{
          user_id: msg.turn.user_id,
          hands: PokerLogic.blur_inactive_hands(msg.turn.hands)
        })

      allin(socket, new_msg)
    else
      if msg.game_over? do
        new_msg =
          msg
          |> Map.put(:turn, %{
            user_id: msg.turn.user_id,
            hands: PokerLogic.blur_inactive_hands(msg.turn.hands)
          })

        push(
          socket,
          "new_event",
          new_msg
        )
      else
        new_msg =
          msg
          |> Map.put(:turn, %{
            user_id: msg.turn.user_id,
            hands: PokerLogic.blur_other_hands(msg.turn.hands, socket.assigns.user_id)
          })

        push(
          socket,
          "new_event",
          new_msg
        )
      end
    end

    {:noreply, socket}
  end

  def allin(socket, msg) do
    # turn remaining cards
    round = Poker.get_round_by_game_id(msg.game.id)

    if round == 3 do
      # end game
      Helpers.Game.end_game(msg.game.id)
      new_game_msg = Helpers.Game.start_and_send_game(socket.assigns.room_id, msg.game.id)
      push(socket, "new_game", new_game_msg)
    else
      # turn next card
      game = Poker.increment_round_and_get_game(msg.game.id)

      new_msg =
        msg
        |> Map.put(:game, game)

      Process.sleep(2000)
      push(socket, "new_event", new_msg)
      allin(socket, new_msg)
    end
  end

  def fold(socket, game_id) do
    msg = Helpers.Event.handle_fold(socket.assigns.user_id, game_id, socket.assigns.room_id)

    if msg.game_msg != nil do
      active_hands? = length(Enum.filter(msg.fold_msg.turn.hands, fn x -> x.is_active end)) > 1

      fold_msg =
        msg.fold_msg
        |> Map.put(:game_over?, active_hands?)

      broadcast(socket, "new_event", fold_msg)
      broadcast(socket, "new_game", msg.game_msg)
    else
      fold_msg =
        msg.fold_msg
        |> Map.put(:game_over?, false)

      broadcast(socket, "new_event", fold_msg)
    end
  end

  def call(socket, game_id) do
    msg = Helpers.Event.handle_call(socket.assigns.user_id, game_id, socket.assigns.room_id)

    if msg.type == "all-in" do
      broadcast(socket, "new_event", msg)
    else
      if msg.game_msg != nil do
        call_msg =
          msg.call_msg
          |> Map.put(:game_over?, true)

        broadcast(socket, "new_event", call_msg)
        broadcast(socket, "new_game", msg.game_msg)
      else
        call_msg =
          msg.call_msg
          |> Map.put(:game_over?, false)

        broadcast(socket, "new_event", call_msg)
      end
    end
  end

  def make_raise(socket, game_id, amt) do
    raise_msg =
      Helpers.Event.handle_raise(socket.assigns.user_id, game_id, amt)
      |> Map.put(:game_over?, false)

    broadcast!(socket, "new_event", raise_msg)
  end

  def handle_out("new_turn", msg, socket) do
    hands = PokerLogic.blur_other_hands(msg.hands, socket.assigns.user_id)

    push(
      socket,
      "new_turn",
      %{user_id: msg.user_id, hands: hands}
    )

    {:noreply, socket}
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
