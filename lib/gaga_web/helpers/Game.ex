defmodule Helpers.Game do
  alias Gaga.Poker

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

  def start_game(table, room_id, first_game \\ true, prev_game_id \\ 0) do
    if length(table) > 1 do
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
  end

  def start_and_send_game(room_id, prev_game_id) do
    # send message telling who won and how maybe add the kicker that won it if its a tie?
    users = Poker.get_users_at_table(room_id)

    if length(users) >= 2 do
      new_game_id = start_game(users, room_id, false, prev_game_id)

      new_game = Poker.get_game_by_id(new_game_id)
      new_hands = Poker.get_hands_by_game_id(new_game_id)
      user_id = Poker.find_active_user_by_game_id(new_game_id)

      %{
        game: new_game,
        hands: new_hands,
        user_id: user_id
      }
    else
      false
    end
  end

  def end_game(game_id) do
    hands =
      Poker.get_hands_by_game_id(game_id)
      |> Enum.filter(&(&1.is_active == true))

    game = Poker.get_game_by_id(game_id)
    # Need to validate and check side games and determine winners
    # Find min amount bet this round
    # side_bets = PokerLogic.find_side_bets(hands, [])
    # PokerLogic.evaluate_side_bets(game, side_bets, [], 0)

    winner = PokerLogic.determine_winners(game, hands)
    total = game.pot_size / length(winner)

    Enum.each(winner, fn x ->
      Poker.give_user_money(x.user_id, floor(total))
    end)
  end

  def handle_rounds_return_game_hands(hands, game_id) do
    updated_game = Poker.increment_round_and_get_game(game_id)

    new_hands =
      hands
      |> Enum.map(fn x -> Map.replace(x, :amount_bet_this_round, 0) end)

    %{game: updated_game, hands: new_hands}
  end
end
