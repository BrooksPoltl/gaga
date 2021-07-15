defmodule PokerTest do
  use ExUnit.Case, async: true

  import TestHelper
  import Gaga.Factory

  doctest Gaga.Poker

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Gaga.Repo)
  end

  def start_game() do
    user1 = insert(:user)
    user2 = insert(:user)
    room1 = insert(:room, user: user1)
    insert(:room_user, user_id: user1.id, room_id: room1.id)
    insert(:room_user, user_id: user2.id, room_id: room1.id)
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

    test "starts game" do
      IO.inspect(start_game())
      assert false == true
    end
  end
end
