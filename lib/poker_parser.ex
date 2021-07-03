defmodule PokerParser do
  defp consecutive?([_a]), do: true

  defp consecutive?([a | [b | t]]) do
    a + 1 == b and consecutive?([b | t])
  end

  defp iterative_five(ranks, i) do
    Enum.reverse(Enum.take(Enum.drop(ranks, i), 5))
  end

  def high_card(kickers) do
    %{name: :high_card, value: 1, tie_breaking_ranks: kickers}
  end

  def high_card?(cards) do
    kickers = PokerLogic.extract_ranks(cards)
    high_card(kickers)
  end

  def pair(primary_rank, kickers) do
    %{
      name: :pair,
      value: 2,
      tie_breaking_ranks: [primary_rank] ++ kickers
    }
  end

  def pair?(cards) do
    ranks = PokerLogic.extract_ranks(cards)

    case ranks do
      [a, a, k1, k2, k3, _k4, _k5] -> pair(a, [k1, k2, k3])
      [k1, a, a, k2, k3, _k4, _k5] -> pair(a, [k1, k2, k3])
      [k1, k2, a, a, k3, _k4, _k5] -> pair(a, [k1, k2, k3])
      [k1, k2, k3, a, a, _k4, _k5] -> pair(a, [k1, k2, k3])
      [k1, k2, k3, _k4, a, a, _k5] -> pair(a, [k1, k2, k3])
      [k1, k2, k3, _k4, _k5, a, a] -> pair(a, [k1, k2, k3])
      _ -> nil
    end
  end

  def two_pair(primary_rank, secondary_rank, kicker) do
    %{
      name: :two_pair,
      value: 3,
      tie_breaking_ranks: [primary_rank, secondary_rank, kicker]
    }
  end

  # def handle_three_of_kind(matches, kicker) do
  #   ordered_matches = Enum.sort(matches, &(&1 >= &2))

  #   kicker_list =
  #     [Enum.at(ordered_matches, 2), kicker]
  #     |> Enum.sort(&(&1 >= &2))

  #   two_pair(Enum.at(ordered_matches, 0), Enum.at(ordered_matches, 1), Enum.at(kicker_list, 0))
  # end

  ## is this necessary? I think this catches highest pairs first
  # def check_three_of_pair(primary_rank, secondary_rank, kicker) do
  #   case kicker do
  #     [a, a, k] -> handle_three_of_kind([primary_rank, secondary_rank, a], k)
  #     [k, a, a] -> handle_three_of_kind([primary_rank, secondary_rank, a], k)
  #     _ -> two_pair(primary_rank, secondary_rank, Enum.at(kicker, 0))
  #   end
  # end

  def two_pair?(cards) do
    ranks = PokerLogic.extract_ranks(cards)

    case ranks do
      [a, a, b, b, k1, _k2, _k3] -> two_pair(a, b, k1)
      [a, a, k1, b, b, _k2, _k3] -> two_pair(a, b, k1)
      [a, a, k1, _k2, b, b, _k3] -> two_pair(a, b, k1)
      [a, a, k1, _k2, _k3, b, b] -> two_pair(a, b, k1)
      [k1, a, a, b, b, _k2, _k3] -> two_pair(a, b, k1)
      [k1, a, a, _k2, b, b, _k3] -> two_pair(a, b, k1)
      [k1, a, a, _k2, _k3, b, b] -> two_pair(a, b, k1)
      [k1, _k2, a, a, b, b, _k3] -> two_pair(a, b, k1)
      [k1, _k2, a, a, _k3, b, b] -> two_pair(a, b, k1)
      [k1, _k2, _k3, a, a, b, b] -> two_pair(a, b, k1)
      _ -> nil
    end
  end

  def three_of_a_kind(primary_rank, kickers) do
    %{
      name: :three_of_a_kind,
      value: 4,
      tie_breaking_ranks: [primary_rank] ++ kickers
    }
  end

  def three_of_a_kind?(cards) do
    ranks = PokerLogic.extract_ranks(cards)

    case ranks do
      [a, a, a, k1, k2, _k3, _k4] -> three_of_a_kind(a, [k1, k2])
      [k1, a, a, a, k2, _k3, _k4] -> three_of_a_kind(a, [k1, k2])
      [k1, k2, a, a, a, _k3, _k4] -> three_of_a_kind(a, [k1, k2])
      [k1, k2, _k3, a, a, a, _k4] -> three_of_a_kind(a, [k1, k2])
      [k1, k2, _k3, _k4, a, a, a] -> three_of_a_kind(a, [k1, k2])
      _ -> nil
    end
  end

  def straight(primary_rank) do
    %{
      name: :straight,
      value: 5,
      tie_breaking_ranks: [primary_rank]
    }
  end

  def straight?(cards) do
    ranks = PokerLogic.extract_ranks(cards)

    if Enum.at(ranks, 0) == 14 do
      mod_ranks = ranks ++ [1]

      cond do
        consecutive?(Enum.reverse(Enum.take(mod_ranks, 5))) ->
          straight(Enum.at(mod_ranks, 0))

        consecutive?(iterative_five(mod_ranks, 1)) ->
          straight(Enum.at(iterative_five(mod_ranks, 1), 4))

        consecutive?(iterative_five(mod_ranks, 2)) ->
          straight(Enum.at(iterative_five(mod_ranks, 2), 4))

        consecutive?(iterative_five(mod_ranks, 3)) ->
          straight(Enum.at(iterative_five(mod_ranks, 3), 4))

        true ->
          nil
      end
    else
      mod_ranks = ranks ++ [0]

      cond do
        consecutive?(Enum.reverse(Enum.take(mod_ranks, 5))) ->
          straight(Enum.at(mod_ranks, 0))

        consecutive?(iterative_five(mod_ranks, 1)) ->
          straight(Enum.at(iterative_five(mod_ranks, 1), 4))

        consecutive?(iterative_five(mod_ranks, 2)) ->
          straight(Enum.at(iterative_five(mod_ranks, 2), 4))

        consecutive?(iterative_five(mod_ranks, 3)) ->
          straight(Enum.at(iterative_five(mod_ranks, 3), 4))

        true ->
          nil
      end
    end
  end

  def full_house(primary_rank, secondary_rank) do
    %{
      name: :full_house,
      value: 7,
      tie_breaking_ranks: [primary_rank, secondary_rank]
    }
  end

  def full_house?(cards) do
    ranks = PokerLogic.extract_ranks(cards)

    case ranks do
      [a, a, a, b, b, _k1, _k2] -> full_house(a, b)
      [a, a, a, _k1, b, b, _k2] -> full_house(a, b)
      [a, a, a, _k1, _k2, b, b] -> full_house(a, b)
      [_k1, a, a, a, b, b, _k2] -> full_house(a, b)
      [_k1, a, a, a, _k2, b, b] -> full_house(a, b)
      [b, b, a, a, a, _k1, _k2] -> full_house(a, b)
      [_k1, _k2, a, a, a, b, b] -> full_house(a, b)
      [b, b, _k1, a, a, a, _k2] -> full_house(a, b)
      [_k1, b, b, a, a, a, _k2] -> full_house(a, b)
      [b, b, _k1, _k2, a, a, a] -> full_house(a, b)
      [_k1, b, b, _k2, a, a, a] -> full_house(a, b)
      [_k1, _k2, b, b, a, a, a] -> full_house(a, b)
      _ -> nil
    end
  end

  def same_suit?(suits) do
    Enum.at(suits, 0) === Enum.at(suits, 4)
  end

  def flush(kickers) do
    %{name: :flush, value: 6, tie_breaking_ranks: Enum.reverse(kickers)}
  end

  def flush?(cards) do
    sorted_suits = Enum.sort(cards, &(&1.suit >= &2.suit))
    ranks = PokerLogic.extract_ranks(sorted_suits)
    suits = PokerLogic.extract_suits(sorted_suits)

    cond do
      same_suit?(Enum.take(suits, 5)) ->
        flush(Enum.take(ranks, 5))

      same_suit?(iterative_five(suits, 1)) ->
        flush(iterative_five(ranks, 1))

      same_suit?(iterative_five(suits, 2)) ->
        flush(iterative_five(ranks, 2))

      same_suit?(iterative_five(suits, 3)) ->
        flush(iterative_five(ranks, 3))

      true ->
        nil
    end
  end

  def four_of_a_kind(primary_rank, secondary_rank) do
    %{
      name: :four_of_a_kind,
      value: 8,
      tie_breaking_ranks: [primary_rank, secondary_rank]
    }
  end

  def four_of_a_kind?(cards) do
    ranks = PokerLogic.extract_ranks(cards)

    case ranks do
      [a, a, a, a, x, _y1, _y2] -> four_of_a_kind(a, x)
      [x, a, a, a, a, _y1, _y2] -> four_of_a_kind(a, x)
      [x, _y1, a, a, a, a, _y2] -> four_of_a_kind(a, x)
      [x, _y1, _y2, a, a, a, a] -> four_of_a_kind(a, x)
      _ -> nil
    end
  end
end
