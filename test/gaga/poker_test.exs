defmodule Gaga.PokerTest do
  use Gaga.DataCase

  alias Gaga.Poker

  describe "rooms" do
    alias Gaga.Poker.Room

    @valid_attrs %{name: "some name"}
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    def room_fixture(attrs \\ %{}) do
      {:ok, room} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Poker.create_room()

      room
    end

    test "list_rooms/0 returns all rooms" do
      room = room_fixture()
      assert Poker.list_rooms() == [room]
    end

    test "get_room!/1 returns the room with given id" do
      room = room_fixture()
      assert Poker.get_room!(room.id) == room
    end

    test "create_room/1 with valid data creates a room" do
      assert {:ok, %Room{} = room} = Poker.create_room(@valid_attrs)
      assert room.name == "some name"
    end

    test "create_room/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Poker.create_room(@invalid_attrs)
    end

    test "update_room/2 with valid data updates the room" do
      room = room_fixture()
      assert {:ok, %Room{} = room} = Poker.update_room(room, @update_attrs)
      assert room.name == "some updated name"
    end

    test "update_room/2 with invalid data returns error changeset" do
      room = room_fixture()
      assert {:error, %Ecto.Changeset{}} = Poker.update_room(room, @invalid_attrs)
      assert room == Poker.get_room!(room.id)
    end

    test "delete_room/1 deletes the room" do
      room = room_fixture()
      assert {:ok, %Room{}} = Poker.delete_room(room)
      assert_raise Ecto.NoResultsError, fn -> Poker.get_room!(room.id) end
    end

    test "change_room/1 returns a room changeset" do
      room = room_fixture()
      assert %Ecto.Changeset{} = Poker.change_room(room)
    end
  end

  describe "room_users" do
    alias Gaga.Poker.RoomUser

    @valid_attrs %{}
    @update_attrs %{}
    @invalid_attrs %{}

    def room_user_fixture(attrs \\ %{}) do
      {:ok, room_user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Poker.create_room_user()

      room_user
    end

    test "list_room_users/0 returns all room_users" do
      room_user = room_user_fixture()
      assert Poker.list_room_users() == [room_user]
    end

    test "get_room_user!/1 returns the room_user with given id" do
      room_user = room_user_fixture()
      assert Poker.get_room_user!(room_user.id) == room_user
    end

    test "create_room_user/1 with valid data creates a room_user" do
      assert {:ok, %RoomUser{} = room_user} = Poker.create_room_user(@valid_attrs)
    end

    test "create_room_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Poker.create_room_user(@invalid_attrs)
    end

    test "update_room_user/2 with valid data updates the room_user" do
      room_user = room_user_fixture()
      assert {:ok, %RoomUser{} = room_user} = Poker.update_room_user(room_user, @update_attrs)
    end

    test "update_room_user/2 with invalid data returns error changeset" do
      room_user = room_user_fixture()
      assert {:error, %Ecto.Changeset{}} = Poker.update_room_user(room_user, @invalid_attrs)
      assert room_user == Poker.get_room_user!(room_user.id)
    end

    test "delete_room_user/1 deletes the room_user" do
      room_user = room_user_fixture()
      assert {:ok, %RoomUser{}} = Poker.delete_room_user(room_user)
      assert_raise Ecto.NoResultsError, fn -> Poker.get_room_user!(room_user.id) end
    end

    test "change_room_user/1 returns a room_user changeset" do
      room_user = room_user_fixture()
      assert %Ecto.Changeset{} = Poker.change_room_user(room_user)
    end
  end

  describe "games" do
    alias Gaga.Poker.Game

    @valid_attrs %{ante: 42, card1: "some card1", card2: "some card2", card3: "some card3", card4: "some card4", card5: "some card5"}
    @update_attrs %{ante: 43, card1: "some updated card1", card2: "some updated card2", card3: "some updated card3", card4: "some updated card4", card5: "some updated card5"}
    @invalid_attrs %{ante: nil, card1: nil, card2: nil, card3: nil, card4: nil, card5: nil}

    def game_fixture(attrs \\ %{}) do
      {:ok, game} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Poker.create_game()

      game
    end

    test "list_games/0 returns all games" do
      game = game_fixture()
      assert Poker.list_games() == [game]
    end

    test "get_game!/1 returns the game with given id" do
      game = game_fixture()
      assert Poker.get_game!(game.id) == game
    end

    test "create_game/1 with valid data creates a game" do
      assert {:ok, %Game{} = game} = Poker.create_game(@valid_attrs)
      assert game.ante == 42
      assert game.card1 == "some card1"
      assert game.card2 == "some card2"
      assert game.card3 == "some card3"
      assert game.card4 == "some card4"
      assert game.card5 == "some card5"
    end

    test "create_game/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Poker.create_game(@invalid_attrs)
    end

    test "update_game/2 with valid data updates the game" do
      game = game_fixture()
      assert {:ok, %Game{} = game} = Poker.update_game(game, @update_attrs)
      assert game.ante == 43
      assert game.card1 == "some updated card1"
      assert game.card2 == "some updated card2"
      assert game.card3 == "some updated card3"
      assert game.card4 == "some updated card4"
      assert game.card5 == "some updated card5"
    end

    test "update_game/2 with invalid data returns error changeset" do
      game = game_fixture()
      assert {:error, %Ecto.Changeset{}} = Poker.update_game(game, @invalid_attrs)
      assert game == Poker.get_game!(game.id)
    end

    test "delete_game/1 deletes the game" do
      game = game_fixture()
      assert {:ok, %Game{}} = Poker.delete_game(game)
      assert_raise Ecto.NoResultsError, fn -> Poker.get_game!(game.id) end
    end

    test "change_game/1 returns a game changeset" do
      game = game_fixture()
      assert %Ecto.Changeset{} = Poker.change_game(game)
    end
  end

  describe "hands" do
    alias Gaga.Poker.Hand

    @valid_attrs %{card1: "some card1", card2: "some card2", is_active: true}
    @update_attrs %{card1: "some updated card1", card2: "some updated card2", is_active: false}
    @invalid_attrs %{card1: nil, card2: nil, is_active: nil}

    def hand_fixture(attrs \\ %{}) do
      {:ok, hand} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Poker.create_hand()

      hand
    end

    test "list_hands/0 returns all hands" do
      hand = hand_fixture()
      assert Poker.list_hands() == [hand]
    end

    test "get_hand!/1 returns the hand with given id" do
      hand = hand_fixture()
      assert Poker.get_hand!(hand.id) == hand
    end

    test "create_hand/1 with valid data creates a hand" do
      assert {:ok, %Hand{} = hand} = Poker.create_hand(@valid_attrs)
      assert hand.card1 == "some card1"
      assert hand.card2 == "some card2"
      assert hand.is_active == true
    end

    test "create_hand/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Poker.create_hand(@invalid_attrs)
    end

    test "update_hand/2 with valid data updates the hand" do
      hand = hand_fixture()
      assert {:ok, %Hand{} = hand} = Poker.update_hand(hand, @update_attrs)
      assert hand.card1 == "some updated card1"
      assert hand.card2 == "some updated card2"
      assert hand.is_active == false
    end

    test "update_hand/2 with invalid data returns error changeset" do
      hand = hand_fixture()
      assert {:error, %Ecto.Changeset{}} = Poker.update_hand(hand, @invalid_attrs)
      assert hand == Poker.get_hand!(hand.id)
    end

    test "delete_hand/1 deletes the hand" do
      hand = hand_fixture()
      assert {:ok, %Hand{}} = Poker.delete_hand(hand)
      assert_raise Ecto.NoResultsError, fn -> Poker.get_hand!(hand.id) end
    end

    test "change_hand/1 returns a hand changeset" do
      hand = hand_fixture()
      assert %Ecto.Changeset{} = Poker.change_hand(hand)
    end
  end

  describe "messages" do
    alias Gaga.Poker.Message

    @valid_attrs %{content: "some content"}
    @update_attrs %{content: "some updated content"}
    @invalid_attrs %{content: nil}

    def message_fixture(attrs \\ %{}) do
      {:ok, message} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Poker.create_message()

      message
    end

    test "list_messages/0 returns all messages" do
      message = message_fixture()
      assert Poker.list_messages() == [message]
    end

    test "get_message!/1 returns the message with given id" do
      message = message_fixture()
      assert Poker.get_message!(message.id) == message
    end

    test "create_message/1 with valid data creates a message" do
      assert {:ok, %Message{} = message} = Poker.create_message(@valid_attrs)
      assert message.content == "some content"
    end

    test "create_message/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Poker.create_message(@invalid_attrs)
    end

    test "update_message/2 with valid data updates the message" do
      message = message_fixture()
      assert {:ok, %Message{} = message} = Poker.update_message(message, @update_attrs)
      assert message.content == "some updated content"
    end

    test "update_message/2 with invalid data returns error changeset" do
      message = message_fixture()
      assert {:error, %Ecto.Changeset{}} = Poker.update_message(message, @invalid_attrs)
      assert message == Poker.get_message!(message.id)
    end

    test "delete_message/1 deletes the message" do
      message = message_fixture()
      assert {:ok, %Message{}} = Poker.delete_message(message)
      assert_raise Ecto.NoResultsError, fn -> Poker.get_message!(message.id) end
    end

    test "change_message/1 returns a message changeset" do
      message = message_fixture()
      assert %Ecto.Changeset{} = Poker.change_message(message)
    end
  end

  describe "events" do
    alias Gaga.Poker.Event

    @valid_attrs %{amount: 42, type: "some type"}
    @update_attrs %{amount: 43, type: "some updated type"}
    @invalid_attrs %{amount: nil, type: nil}

    def event_fixture(attrs \\ %{}) do
      {:ok, event} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Poker.create_event()

      event
    end

    test "list_events/0 returns all events" do
      event = event_fixture()
      assert Poker.list_events() == [event]
    end

    test "get_event!/1 returns the event with given id" do
      event = event_fixture()
      assert Poker.get_event!(event.id) == event
    end

    test "create_event/1 with valid data creates a event" do
      assert {:ok, %Event{} = event} = Poker.create_event(@valid_attrs)
      assert event.amount == 42
      assert event.type == "some type"
    end

    test "create_event/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Poker.create_event(@invalid_attrs)
    end

    test "update_event/2 with valid data updates the event" do
      event = event_fixture()
      assert {:ok, %Event{} = event} = Poker.update_event(event, @update_attrs)
      assert event.amount == 43
      assert event.type == "some updated type"
    end

    test "update_event/2 with invalid data returns error changeset" do
      event = event_fixture()
      assert {:error, %Ecto.Changeset{}} = Poker.update_event(event, @invalid_attrs)
      assert event == Poker.get_event!(event.id)
    end

    test "delete_event/1 deletes the event" do
      event = event_fixture()
      assert {:ok, %Event{}} = Poker.delete_event(event)
      assert_raise Ecto.NoResultsError, fn -> Poker.get_event!(event.id) end
    end

    test "change_event/1 returns a event changeset" do
      event = event_fixture()
      assert %Ecto.Changeset{} = Poker.change_event(event)
    end
  end
end
