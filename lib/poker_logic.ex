defmodule PokerLogic do
  def create_game(table) do
    deck =
      create_deck()
      |> shuffle_deck()

    deal(table, deck)
  end

  def create_deck() do
    values = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
    suits = ["S", "C", "H", "D"]

    for suit <- suits, value <- values do
      "#{suit}#{value}"
    end
  end

  def shuffle_deck(deck) do
    Enum.shuffle(deck)
  end

  def deal(table, deck) do
    {new_table, new_deck} = add_hands(table, deck)

    flop =
      add_flop(new_deck)
      |> Tuple.to_list()
      |> Enum.at(0)

    {new_table, flop}
  end

  def add_flop(deck) do
    Enum.split(deck, 5)
  end

  def add_hands(table, deck) do
    Enum.map_reduce(table, deck, fn user, acc ->
      {hand, new_deck} = Enum.split(acc, 2)
      new_user = Map.put(user, :hand, hand)
      {new_user, new_deck}
    end)
  end

  defp parse_rank("J"), do: 11
  defp parse_rank("Q"), do: 12
  defp parse_rank("K"), do: 13
  defp parse_rank("A"), do: 14

  defp parse_rank(numeric_face) do
    {rank, _} = Integer.parse(numeric_face)
    rank
  end

  def format_card(card) do
    {suit, rank} = String.split_at(card, 1)
    %{suit: suit, rank: parse_rank(rank)}
  end

  def evaluate_score(cards) do
    formatted_cards =
      Enum.map(cards, &format_card/1)
      |> Enum.sort(&(&1.rank >= &2.rank))

    calculate_score(formatted_cards)
  end

  defp calculate_score(cards) do
    [top_score | _] =
      [
        PokerParser.straight_flush?(cards),
        PokerParser.four_of_a_kind?(cards),
        PokerParser.flush?(cards),
        PokerParser.full_house?(cards),
        PokerParser.straight?(cards),
        PokerParser.three_of_a_kind?(cards),
        PokerParser.two_pair?(cards),
        PokerParser.pair?(cards),
        PokerParser.high_card?(cards)
      ]
      |> Enum.reject(&(&1 == nil))

    top_score
  end

  def extract_ranks(cards) do
    Enum.map(cards, fn x -> x.rank end)
  end

  def extract_suits(cards) do
    Enum.map(cards, fn x -> x.suit end)
  end

  def is_everyone_all_in?(hands) do
    able_to_play =
      Enum.filter(hands, fn x ->
        x.cash != 0 and x.is_active == true
      end)

    length(able_to_play) < 1
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

  def blur_inactive_hands(hands) do
    Enum.map(hands, fn h ->
      if h.is_active do
        h
      else
        h
        |> Map.put(:card1, nil)
        |> Map.put(:card2, nil)
      end
    end)
  end

  def find_side_bets(hands, acc) do
    if length(hands) < 1 do
      acc
    else
      min_value = Enum.min_by(hands, & &1.amount_bet_this_game).amount_bet_this_game
      filtered_hands = Enum.filter(hands, fn x -> x.amount_bet_this_game > min_value end)
      find_side_bets(filtered_hands, acc ++ [hands])
    end
  end

  def limit_raise(cash, amount_to_call, amt) do
    if cash < amount_to_call + amt do
      cash
    else
      amount_to_call + amt
    end
  end

  def break_ties(hands) do
    max_value =
      Enum.reduce(hands, 0, fn x, acc ->
        val = Enum.at(x.tie_breaking_ranks, 0)

        if val > acc do
          val
        else
          acc
        end
      end)

    filtered_hands =
      hands
      |> Enum.filter(&(Enum.at(&1.tie_breaking_ranks, 0) == max_value))

    if(
      length(filtered_hands) == 1 or length(Enum.at(filtered_hands, 0).tie_breaking_ranks) == 1
    ) do
      filtered_hands
    else
      pivoted_hands =
        Enum.map(filtered_hands, fn x ->
          new_tie_breaks =
            x.tie_breaking_ranks
            |> tl()

          Map.put(x, :tie_breaking_ranks, new_tie_breaks)
        end)

      break_ties(pivoted_hands)
    end
  end

  def evaluate_results(hands) do
    max_value =
      Enum.reduce(hands, 0, fn x, acc ->
        if x.value > acc do
          x.value
        else
          acc
        end
      end)

    ties =
      hands
      |> Enum.filter(&(&1.value == max_value))

    break_ties(ties)
  end

  def determine_winners(game, hands) do
    active_hands = Enum.filter(hands, fn x -> x.is_active == true end)

    if length(active_hands) == 1 do
      active_hands
    else
      scores =
        Enum.map(active_hands, fn x ->
          evaluate_score([
            game.card1,
            game.card2,
            game.card3,
            game.card4,
            game.card5,
            x.card1,
            x.card2
          ])
        end)

      attach_scores =
        Enum.map(0..(length(active_hands) - 1), fn x ->
          Map.merge(Enum.at(active_hands, x), Enum.at(scores, x))
        end)

      evaluate_results(attach_scores)
    end
  end

  def evaluate_side_bets(game, side_bets, acc, paid_out) do
    # take
  end
end
