defmodule PokerTest do
  use ExUnit.Case, async: true

  import TestHelper

  doctest Gaga.Poker

  test "handles when 1 person is passed in" do
    hands = [
      %{
        tie_breaking_ranks: [13, 4, 14],
        user_id: 61
      }
    ]

    result = Gaga.Poker.break_ties(hands)
    assert Enum.at(result, 0).user_id == 61
  end

  test "handles a direct tie" do
    hands = [
      %{
        tie_breaking_ranks: [13, 4, 14],
        user_id: 61
      },
      %{
        tie_breaking_ranks: [13, 4, 14],
        user_id: 61
      }
    ]

    result = Gaga.Poker.break_ties(hands)
    assert length(result) == 2
  end

  test "handles a non tie" do
    hands = [
      %{
        tie_breaking_ranks: [12, 4, 14],
        user_id: 62
      },
      %{
        tie_breaking_ranks: [13, 4, 14],
        user_id: 61
      }
    ]

    result = Gaga.Poker.break_ties(hands)
    assert Enum.at(result, 0).user_id == 61
  end

  test "handles a secondary tie" do
    hands = [
      %{
        tie_breaking_ranks: [13, 5, 14],
        user_id: 62
      },
      %{
        tie_breaking_ranks: [13, 4, 14],
        user_id: 61
      }
    ]

    result = Gaga.Poker.break_ties(hands)
    assert Enum.at(result, 0).user_id == 62
  end
end
