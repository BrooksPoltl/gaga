defmodule Gaga.Poker do
  import Ecto.Query, warn: false
  alias Gaga.Repo

  alias Gaga.Poker.{Room, RoomUser, Game, Hand}
  alias Gaga.Accounts.User

  def get_users_at_table(room_id) do
    query =
      from(u in "users",
        join: room_user in RoomUser,
        on: [user_id: u.id],
        select: %{
          username: u.name,
          user_id: u.id,
          cash: u.cash
        },
        where: room_user.room_id == ^room_id
      )

    Repo.all(query)
  end

  def list_rooms do
    query =
      from(r in "rooms",
        left_join: room_user in RoomUser,
        on: [room_id: r.id],
        join: user in User,
        on: [id: r.user_id],
        group_by: [r.id, r.name, r.user_id, user.name],
        select: %{
          name: r.name,
          user_id: r.user_id,
          id: r.id,
          count: count(room_user.id),
          username: user.name
        }
      )

    Repo.all(query)
  end

  def create_room(attrs \\ %{}, user) do
    %Room{user_id: user}
    |> Room.changeset(attrs)
    |> Repo.insert()
  end

  def create_hands(hands) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert_all(:insert_all, Hand, hands)
    |> Repo.transaction()
  end

  def create_game(flop, room_id) do
    IO.inspect(room_id)

    %Game{}
    |> Game.changeset(%{
      card1: Enum.at(flop, 0),
      card2: Enum.at(flop, 1),
      card3: Enum.at(flop, 2),
      card4: Enum.at(flop, 3),
      card5: Enum.at(flop, 4),
      room_id: room_id,
      ante: 20
    })
    |> Repo.insert()
  end

  def join_room(attrs \\ %{}) do
    %RoomUser{}
    |> RoomUser.changeset(attrs)
    |> Repo.insert()
  end

  def leave_room(user_id, room_id) do
    from(ru in RoomUser, where: ru.user_id == ^user_id and ru.room_id == ^room_id)
    |> Repo.delete_all()
  end
end
