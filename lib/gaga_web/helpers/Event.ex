defmodule Helpers.Event do
  alias Gaga.Poker

  def handle_fold(user_id, game_id, room_id) do
    event = %{
      type: "fold",
      user_id: user_id,
      game_id: game_id,
      amount: 0,
      inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
      updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    }

    is_last_user? = Poker.create_event(event)
    next_user_id = Poker.find_active_user_by_game_id(game_id)
    hands = Poker.get_hands_by_game_id(game_id)

    game = Poker.get_game_by_id(game_id)

    fold_msg = %{
      type: "fold",
      amt: 0,
      game: game,
      user_id: user_id,
      turn: %{user_id: next_user_id, hands: hands}
    }

    is_end_of_round? = Poker.get_round_and_check_if_end(game_id)
    round = Poker.get_round_by_game_id(game_id)
    is_game_over? = is_end_of_round? and round == 3

    if is_game_over? or is_last_user? do
      Helpers.Game.end_game(game_id)

      new_msg =
        fold_msg
        |> Map.put(:turn, %{user_id: 0, hands: fold_msg.turn.hands})

      new_game_msg = Helpers.Game.start_and_send_game(room_id, game_id)

      %{fold_msg: new_msg, game_msg: new_game_msg}
    else
      if is_end_of_round? do
        msg = Helpers.Game.handle_rounds_return_game_hands(fold_msg.turn.hands, game_id)

        new_fold_msg =
          Map.put(fold_msg, :game, msg.game)
          |> Map.put(:turn, %{hands: msg.hands, user_id: fold_msg.turn.user_id})

        %{fold_msg: new_fold_msg, game_msg: nil}
      else
        %{fold_msg: fold_msg, game_msg: nil}
      end
    end
  end

  def handle_call(user_id, game_id, room_id) do
    amount_to_call = Poker.calculate_amount_to_call(user_id, game_id)

    event = %{
      type: "call",
      user_id: user_id,
      game_id: game_id,
      amount: amount_to_call,
      inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
      updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    }

    Poker.create_event(event)
    hands = Poker.get_hands_by_game_id(game_id)

    is_all_in? = PokerLogic.is_everyone_all_in?(hands)
    IO.inspect(hands)

    if is_all_in? do
      IO.puts("WE ALL IN BABY")
      game = Poker.get_game_by_id(game_id)

      %{
        type: "all-in",
        amt: amount_to_call,
        game: game,
        user_id: user_id,
        turn: %{user_id: 0, hands: hands}
      }
    else
      next_user_id = Poker.find_active_user_by_game_id(game_id)

      game = Poker.get_game_by_id(game_id)

      call_msg = %{
        type: "call",
        amt: amount_to_call,
        game: game,
        user_id: user_id,
        turn: %{user_id: next_user_id, hands: hands}
      }

      is_end_of_round? = Poker.get_round_and_check_if_end(game_id)
      round = Poker.get_round_by_game_id(game_id)
      is_game_over? = is_end_of_round? and round == 3

      if is_game_over? do
        new_msg =
          call_msg
          |> Map.put(:turn, %{user_id: 0, hands: call_msg.turn.hands})

        Helpers.Game.end_game(game_id)
        new_game_msg = Helpers.Game.start_and_send_game(room_id, game_id)

        %{call_msg: new_msg, game_msg: new_game_msg}
      else
        if is_end_of_round? do
          msg = Helpers.Game.handle_rounds_return_game_hands(call_msg.turn.hands, game_id)

          new_call_msg =
            Map.put(call_msg, :game, msg.game)
            |> Map.put(:turn, %{hands: msg.hands, user_id: call_msg.turn.user_id})

          %{call_msg: new_call_msg, game_msg: nil}
        else
          %{call_msg: call_msg, game_msg: nil}
        end
      end
    end
  end

  def handle_raise(user_id, game_id, amt) do
    amount_to_call = Poker.calculate_amount_to_call(user_id, game_id)
    raise_amount = amount_to_call + amt

    event = %{
      type: "raise",
      user_id: user_id,
      game_id: game_id,
      amount: raise_amount,
      inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
      updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    }

    Poker.create_event(event)
    next_user_id = Poker.find_active_user_by_game_id(game_id)

    hands = Poker.get_hands_by_game_id(game_id)
    game = Poker.get_game_by_id(game_id)

    %{
      type: "raise",
      amt: amt,
      game: game,
      user_id: user_id,
      turn: %{user_id: next_user_id, hands: hands}
    }
  end
end
