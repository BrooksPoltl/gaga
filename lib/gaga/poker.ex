defmodule Gaga.Poker do
  import Ecto.Query, warn: false
  import Ecto.Changeset
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
        where: room_user.room_id == ^room_id,
        order_by: [asc: u.inserted_at]
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

  def create_game(flop, room_id, big_user_id, small_user_id) do
    big_user = Repo.get_by(User, id: big_user_id)
    small_user = Repo.get_by(User, id: small_user_id)
    IO.inspect(small_user)

    change(big_user, %{cash: big_user.cash - 40})
    |> Repo.update()

    change(small_user, %{cash: small_user.cash - 20})
    |> Repo.update()

    %Game{}
    |> Game.changeset(%{
      card1: Enum.at(flop, 0),
      card2: Enum.at(flop, 1),
      card3: Enum.at(flop, 2),
      card4: Enum.at(flop, 3),
      card5: Enum.at(flop, 4),
      big_user_id: big_user_id,
      small_user_id: small_user_id,
      room_id: room_id,
      ante: 20
    })
    |> Repo.insert()
  end

  def get_hands_by_game_id(game_id) do
    get_hands =
      from(h in "hands",
        join: game in Game,
        on: [id: h.game_id],
        join: ru in RoomUser,
        on: [user_id: h.user_id, room_id: game.room_id],
        join: u in User,
        on: [id: h.user_id],
        select: %{
          id: h.id,
          card1: h.card1,
          card2: h.card2,
          user_id: h.user_id,
          name: u.name,
          cash: u.cash,
          is_active: h.is_active
        },
        where: h.game_id == ^game_id,
        order_by: [asc: ru.inserted_at]
      )

    Repo.all(get_hands)
  end

  def get_game_by_room_id(room_id) do
    room_id_int = String.to_integer(room_id)

    get_game =
      from(g in "games",
        select: %{
          id: g.id,
          card1: g.card1,
          card2: g.card2,
          card3: g.card3,
          card4: g.card4,
          card5: g.card5,
          big_user_id: g.big_user_id,
          small_user_id: g.small_user_id,
          shown_flop: g.shown_flop,
          shown_turn: g.shown_turn,
          shown_river: g.shown_river
        },
        limit: 1,
        where: g.room_id == ^room_id_int,
        order_by: [desc: :inserted_at]
      )

    Repo.one(get_game)
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
