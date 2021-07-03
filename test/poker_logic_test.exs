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
    assert score.name == :two_pair
  end

  test "handles three of kind" do
    score = PokerLogic.evaluate_score(["H4", "S3", "D2", "SQ", "DQ", "DA", "HQ"])
    assert score.name == :three_of_a_kind
  end

  test "handles straight" do
    score = PokerLogic.evaluate_score(["H4", "S3", "D2", "S6", "D7", "D5", "H9"])
    assert score.name == :straight
    assert Enum.at(score.tie_breaking_ranks, 0) == 7
  end

  test "handles straight ace high" do
    score = PokerLogic.evaluate_score(["H4", "S3", "D10", "SJ", "DK", "DA", "HQ"])
    assert score.name == :straight
    assert Enum.at(score.tie_breaking_ranks, 0) == 14
  end

  test "handles straight ace low five high" do
    score = PokerLogic.evaluate_score(["H4", "S3", "D2", "S5", "DQ", "DA", "HQ"])
    assert score.name == :straight
    assert Enum.at(score.tie_breaking_ranks, 0) == 5
  end

  test "handles full house" do
    score = PokerLogic.evaluate_score(["HA", "S3", "D2", "SQ", "DQ", "DA", "HQ"])
    assert score.name == :full_house
  end

  test "picks higher pair with full house" do
    score = PokerLogic.evaluate_score(["HA", "S3", "D3", "SQ", "DQ", "DA", "HQ"])
    assert score.name == :full_house
    assert Enum.at(score.tie_breaking_ranks, 1) == 14
  end

  test "picks higher three of a kind with full house" do
    score = PokerLogic.evaluate_score(["HA", "SA", "D3", "SQ", "DQ", "DA", "HQ"])
    assert score.name == :full_house
    assert Enum.at(score.tie_breaking_ranks, 0) == 14
  end

  test "flush with right kickers" do
    score = PokerLogic.evaluate_score(["H4", "HA", "H3", "HQ", "H7", "H10", "SQ"])
    assert score.name == :flush
    assert Enum.at(score.tie_breaking_ranks, 0) == 14
  end

  test "four of a kind" do
    score = PokerLogic.evaluate_score(["H4", "HA", "S4", "D4", "C4", "H10", "SQ"])
    assert score.name == :four_of_a_kind
    assert Enum.at(score.tie_breaking_ranks, 1) == 14
  end

  test "royal flush" do
    score = PokerLogic.evaluate_score(["HA", "HK", "HQ", "HJ", "H10", "H7", "SQ"])
    assert score.name == :straight_flush
    assert Enum.at(score.tie_breaking_ranks, 0) == 14
  end

  test "straight flush" do
    score = PokerLogic.evaluate_score(["HA", "H2", "HQ", "HJ", "H10", "H8", "H9"])
    assert score.name == :straight_flush
    assert Enum.at(score.tie_breaking_ranks, 0) == 12
  end
end
