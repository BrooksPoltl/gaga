defmodule Gaga.Poker do
  @moduledoc """
  The Poker context.
  """

  import Ecto.Query, warn: false
  alias Gaga.Repo

  alias Gaga.Poker.Room
  alias Gaga.Accounts.User

  @doc """
  Returns the list of rooms.

  ## Examples

      iex> list_rooms()
      [%Room{}, ...]

  """
  def list_rooms do
    Repo.all(Room)
    |> Repo.preload(user: [:room])
  end

  @doc """
  Gets a single room.

  Raises `Ecto.NoResultsError` if the Room does not exist.

  ## Examples

      iex> get_room!(123)
      %Room{}

      iex> get_room!(456)
      ** (Ecto.NoResultsError)

  """
  def get_room!(id), do: Repo.get!(Room, id)

  @doc """
  Creates a room.

  ## Examples

      iex> create_room(%{field: value})
      {:ok, %Room{}}

      iex> create_room(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_room(attrs \\ %{}, user) do
    %Room{user_id: user}
    |> Room.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a room.

  ## Examples

      iex> update_room(room, %{field: new_value})
      {:ok, %Room{}}

      iex> update_room(room, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_room(%Room{} = room, attrs) do
    room
    |> Room.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a room.

  ## Examples

      iex> delete_room(room)
      {:ok, %Room{}}

      iex> delete_room(room)
      {:error, %Ecto.Changeset{}}

  """
  def delete_room(%Room{} = room) do
    Repo.delete(room)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking room changes.

  ## Examples

      iex> change_room(room)
      %Ecto.Changeset{data: %Room{}}

  """
  def change_room(%Room{} = room, attrs \\ %{}) do
    Room.changeset(room, attrs)
  end

  alias Gaga.Poker.RoomUser

  @doc """
  Returns the list of room_users.

  ## Examples

      iex> list_room_users()
      [%RoomUser{}, ...]

  """
  def list_room_users do
    Repo.all(RoomUser)
  end

  @doc """
  Gets a single room_user.

  Raises `Ecto.NoResultsError` if the Room user does not exist.

  ## Examples

      iex> get_room_user!(123)
      %RoomUser{}

      iex> get_room_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_room_user!(id), do: Repo.get!(RoomUser, id)

  @doc """
  Creates a room_user.

  ## Examples

      iex> create_room_user(%{field: value})
      {:ok, %RoomUser{}}

      iex> create_room_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_room_user(attrs \\ %{}) do
    %RoomUser{}
    |> RoomUser.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a room_user.

  ## Examples

      iex> update_room_user(room_user, %{field: new_value})
      {:ok, %RoomUser{}}

      iex> update_room_user(room_user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_room_user(%RoomUser{} = room_user, attrs) do
    room_user
    |> RoomUser.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a room_user.

  ## Examples

      iex> delete_room_user(room_user)
      {:ok, %RoomUser{}}

      iex> delete_room_user(room_user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_room_user(%RoomUser{} = room_user) do
    Repo.delete(room_user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking room_user changes.

  ## Examples

      iex> change_room_user(room_user)
      %Ecto.Changeset{data: %RoomUser{}}

  """
  def change_room_user(%RoomUser{} = room_user, attrs \\ %{}) do
    RoomUser.changeset(room_user, attrs)
  end

  alias Gaga.Poker.Game

  @doc """
  Returns the list of games.

  ## Examples

      iex> list_games()
      [%Game{}, ...]

  """
  def list_games do
    Repo.all(Game)
  end

  @doc """
  Gets a single game.

  Raises `Ecto.NoResultsError` if the Game does not exist.

  ## Examples

      iex> get_game!(123)
      %Game{}

      iex> get_game!(456)
      ** (Ecto.NoResultsError)

  """
  def get_game!(id), do: Repo.get!(Game, id)

  @doc """
  Creates a game.

  ## Examples

      iex> create_game(%{field: value})
      {:ok, %Game{}}

      iex> create_game(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_game(attrs \\ %{}) do
    %Game{}
    |> Game.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a game.

  ## Examples

      iex> update_game(game, %{field: new_value})
      {:ok, %Game{}}

      iex> update_game(game, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_game(%Game{} = game, attrs) do
    game
    |> Game.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a game.

  ## Examples

      iex> delete_game(game)
      {:ok, %Game{}}

      iex> delete_game(game)
      {:error, %Ecto.Changeset{}}

  """
  def delete_game(%Game{} = game) do
    Repo.delete(game)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking game changes.

  ## Examples

      iex> change_game(game)
      %Ecto.Changeset{data: %Game{}}

  """
  def change_game(%Game{} = game, attrs \\ %{}) do
    Game.changeset(game, attrs)
  end

  alias Gaga.Poker.Hand

  @doc """
  Returns the list of hands.

  ## Examples

      iex> list_hands()
      [%Hand{}, ...]

  """
  def list_hands do
    Repo.all(Hand)
  end

  @doc """
  Gets a single hand.

  Raises `Ecto.NoResultsError` if the Hand does not exist.

  ## Examples

      iex> get_hand!(123)
      %Hand{}

      iex> get_hand!(456)
      ** (Ecto.NoResultsError)

  """
  def get_hand!(id), do: Repo.get!(Hand, id)

  @doc """
  Creates a hand.

  ## Examples

      iex> create_hand(%{field: value})
      {:ok, %Hand{}}

      iex> create_hand(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_hand(attrs \\ %{}) do
    %Hand{}
    |> Hand.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a hand.

  ## Examples

      iex> update_hand(hand, %{field: new_value})
      {:ok, %Hand{}}

      iex> update_hand(hand, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_hand(%Hand{} = hand, attrs) do
    hand
    |> Hand.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a hand.

  ## Examples

      iex> delete_hand(hand)
      {:ok, %Hand{}}

      iex> delete_hand(hand)
      {:error, %Ecto.Changeset{}}

  """
  def delete_hand(%Hand{} = hand) do
    Repo.delete(hand)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking hand changes.

  ## Examples

      iex> change_hand(hand)
      %Ecto.Changeset{data: %Hand{}}

  """
  def change_hand(%Hand{} = hand, attrs \\ %{}) do
    Hand.changeset(hand, attrs)
  end

  alias Gaga.Poker.Message

  @doc """
  Returns the list of messages.

  ## Examples

      iex> list_messages()
      [%Message{}, ...]

  """
  def list_messages do
    Repo.all(Message)
  end

  @doc """
  Gets a single message.

  Raises `Ecto.NoResultsError` if the Message does not exist.

  ## Examples

      iex> get_message!(123)
      %Message{}

      iex> get_message!(456)
      ** (Ecto.NoResultsError)

  """
  def get_message!(id), do: Repo.get!(Message, id)

  @doc """
  Creates a message.

  ## Examples

      iex> create_message(%{field: value})
      {:ok, %Message{}}

      iex> create_message(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a message.

  ## Examples

      iex> update_message(message, %{field: new_value})
      {:ok, %Message{}}

      iex> update_message(message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_message(%Message{} = message, attrs) do
    message
    |> Message.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a message.

  ## Examples

      iex> delete_message(message)
      {:ok, %Message{}}

      iex> delete_message(message)
      {:error, %Ecto.Changeset{}}

  """
  def delete_message(%Message{} = message) do
    Repo.delete(message)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking message changes.

  ## Examples

      iex> change_message(message)
      %Ecto.Changeset{data: %Message{}}

  """
  def change_message(%Message{} = message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end
end
