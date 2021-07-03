defmodule PokerLogicTest do
  use ExUnit.Case, async: true

  import TestHelper

  doctest PokerLogic

  test "evaluates to  high card" do
    score = PokerLogic.evaluate_score(["H4", "S2", "D3", "D10", "DQ", "DK", "HA"])
    assert score.name == :high_card
    assert Enum.at(score.tie_breaking_ranks, 0) == 14
  end

  test "prefers pair over high card" do
    score = PokerLogic.evaluate_score(["H4", "S3", "D3", "D10", "DQ", "DK", "HA"])
    assert score.name != :high_card
  end

  test "1 and 2 pair" do
    score = PokerLogic.evaluate_score(["H4", "S3", "D3", "D10", "DQ", "DK", "HA"])
    assert score.name == :pair
    assert Enum.at(score.tie_breaking_ranks, 0) == 3
  end

  test "end pair" do
    score = PokerLogic.evaluate_score(["H4", "SK", "DA", "D10", "DQ", "D3", "H3"])
    assert score.name == :pair
    assert Enum.at(score.tie_breaking_ranks, 0) == 3
  end

  test "prefers 2 pair over pair" do
    score = PokerLogic.evaluate_score(["H4", "SK", "DA", "SQ", "DQ", "D3", "H3"])
    assert score.name == :two_pair
  end

  test "handles three pair" do
    score = PokerLogic.evaluate_score(["H3", "S3", "DA", "SQ", "DQ", "DA", "H4"])
    IO.inspect(score)
    assert score.name == :two_pair
  end
end
