defmodule PokerTest do
  use ExUnit.Case, async: true

  import TestHelper
  import Gaga.Factory

  doctest Gaga.Poker

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Gaga.Repo)
  end

  def start_game_two_users() do
    user1 = insert(:user)
    user2 = insert(:user)
    room1 = insert(:room, user: user1)
    insert(:room_user, user_id: user1.id, room_id: room1.id)
    insert(:room_user, user_id: user2.id, room_id: room1.id)
    table_users = Gaga.Poker.get_users_at_table(room1.id)
    Helpers.Game.start_game(table_users, room1.id)
  end

  def start_game_three_users() do
    user1 = insert(:user)
    user2 = insert(:user)
    user3 = insert(:user)
    room1 = insert(:room, user: user1)
    insert(:room_user, user_id: user1.id, room_id: room1.id)
    insert(:room_user, user_id: user2.id, room_id: room1.id)
    insert(:room_user, user_id: user3.id, room_id: room1.id)
    table_users = Gaga.Poker.get_users_at_table(room1.id)
    Helpers.Game.start_game(table_users, room1.id)
  end

  describe "break_ties" do
    test "handles when 1 person is passed in" do
      hands = [
        %{
          tie_breaking_ranks: [13, 4, 14],
          user_id: 61
        }
      ]

      result = PokerLogic.break_ties(hands)
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

      result = PokerLogic.break_ties(hands)
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

      result = PokerLogic.break_ties(hands)
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

      result = PokerLogic.break_ties(hands)
      assert Enum.at(result, 0).user_id == 62
    end
  end

  describe "get_users_left" do
    test "gets users left at table without fold" do
      game_id = start_game_three_users()

      users_left = Gaga.Poker.get_users_left(game_id)
      assert users_left == 3
    end

    test "gets users left at table with fold" do
      game_id = start_game_three_users()
      hands = Gaga.Poker.get_hands_by_game_id(game_id)
      assert Enum.count(hands) == 3

      Gaga.Poker.create_event(%{
        type: "fold",
        user_id: Enum.at(hands, 0).user_id,
        game_id: game_id,
        amount: 0,
        inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      })

      users_left = Gaga.Poker.get_users_left(game_id)
      assert users_left == 2
    end
  end

  describe "evaluate_results" do
    test "returns user with highest value" do
      hands = [
        %{id: 1, value: 2, tie_breaking_ranks: [1, 2, 3]},
        %{id: 2, value: 1, tie_breaking_ranks: [1, 2, 3]}
      ]

      winners = PokerLogic.evaluate_results(hands)

      assert Enum.at(winners, 0).id == 1
    end
  end

  describe "calculate_amount_to_call" do
    test "handles call amount lower than cash" do
      game_id = start_game_three_users()
      hands = Gaga.Poker.get_hands_by_game_id(game_id)
      hand3 = Enum.at(hands, 2)
      amount_to_call = Gaga.Poker.calculate_amount_to_call(hand3.user_id, game_id)
      assert amount_to_call == 40
    end

    test "handles call amount higher than cash" do
      game_id = start_game_three_users()
      hands = Gaga.Poker.get_hands_by_game_id(game_id)
      hand1 = Enum.at(hands, 0)
      hand3 = Enum.at(hands, 2)

      Gaga.Poker.create_event(%{
        type: "raise",
        user_id: hand1.user_id,
        game_id: game_id,
        amount: 1_000_000,
        inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      })

      amount_to_call = Gaga.Poker.calculate_amount_to_call(hand3.user_id, game_id)
      assert amount_to_call == 10000
    end
  end

  describe("find_active_user_by_game_id") do
    test "starts game with right user" do
      game_id = start_game_two_users()
      hands = Gaga.Poker.get_hands_by_game_id(game_id)
      hand3 = Enum.at(hands, 1)
      user_id = Gaga.Poker.find_active_user_by_game_id(game_id)

      assert hand3.user_id == user_id
    end
  end
end
