defmodule PokerParser do
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

  def handle_three_of_kind(matches, kicker) do
    ordered_matches = Enum.sort(matches, &(&1 >= &2))

    kicker_list =
      [Enum.at(ordered_matches, 2), kicker]
      |> Enum.sort(&(&1 >= &2))

    two_pair(Enum.at(ordered_matches, 0), Enum.at(ordered_matches, 1), Enum.at(kicker_list, 0))
  end

  ## is this necessary? I think this catches highest pairs first
  def check_three_of_kind(primary_rank, secondary_rank, kicker) do
    case kicker do
      [a, a, k] -> handle_three_of_kind([primary_rank, secondary_rank, a], k)
      [k, a, a] -> handle_three_of_kind([primary_rank, secondary_rank, a], k)
      _ -> two_pair(primary_rank, secondary_rank, Enum.at(kicker, 0))
    end
  end

  def two_pair?(cards) do
    ranks = PokerLogic.extract_ranks(cards)

    case ranks do
      [a, a, b, b, k1, k2, k3] -> check_three_of_kind(a, b, [k1, k2, k3])
      [a, a, k1, b, b, k2, k3] -> check_three_of_kind(a, b, [k1, k2, k3])
      [a, a, k1, k2, b, b, k3] -> check_three_of_kind(a, b, [k1, k2, k3])
      [a, a, k1, k2, k3, b, b] -> check_three_of_kind(a, b, [k1, k2, k3])
      [k1, a, a, b, b, k2, k3] -> check_three_of_kind(a, b, [k1, k2, k3])
      [k1, a, a, k2, b, b, k3] -> check_three_of_kind(a, b, [k1, k2, k3])
      [k1, a, a, k2, k3, b, b] -> check_three_of_kind(a, b, [k1, k2, k3])
      [k1, k2, a, a, b, b, k3] -> check_three_of_kind(a, b, [k1, k2, k3])
      [k1, k2, a, a, k3, b, b] -> check_three_of_kind(a, b, [k1, k2, k3])
      [k1, k2, k3, a, a, b, b] -> check_three_of_kind(a, b, [k1, k2, k3])
      _ -> nil
    end
  end
end
