defmodule Gaga.Poker do
  import Ecto.Query, warn: false
  import Ecto.Changeset
  alias Gaga.Repo

  alias Gaga.Poker.{Room, RoomUser, Game, Hand, Event}
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

  def bet_amount(user_id, amt) do
    user = Repo.get_by(User, id: user_id)

    change(user, %{cash: user.cash - amt})
    |> Repo.update()
  end

  def give_user_money(user_id, money) do
    user = Repo.get_by(User, id: user_id)

    change(user, %{cash: user.cash + money})
    |> Repo.update()
  end

  def get_users_left(game_id) do
    query = from(h in "hands", where: h.game_id == ^game_id and h.is_active == true)
    Repo.aggregate(query, :count, :is_active)
  end

  def get_pot_size(game_id) do
    query = from(e in "events", where: e.game_id == ^game_id)
    Repo.aggregate(query, :sum, :amount)
  end

  # Returns whether or not to start a new game
  def fold_hand(user_id, game_id) do
    hand = Repo.get_by(Hand, user_id: user_id, game_id: game_id)

    change(hand, %{is_active: false})
    |> Repo.update()

    if Gaga.Poker.get_users_left(game_id) == 1 do
      pot_size = Gaga.Poker.get_users_left(game_id)

      query =
        from(h in "hands",
          select: %{id: h.user_id},
          where: h.is_active == true and h.game_id == ^game_id
        )

      user_that_is_left = Repo.one(query)
      give_user_money(user_that_is_left.id, pot_size)
      true
    end

    false
  end

  def create_event(attrs \\ %{}) do
    if attrs.type != "fold" do
      bet_amount(attrs.user_id, attrs.amount)
    else
      fold_hand(attrs.user_id, attrs.game_id)
    end

    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert()

    if attrs.type != "fold" do
      bet_amount(attrs.user_id, attrs.amount)
    else
      fold_hand(attrs.user_id, attrs.game_id)
    end
  end

  def create_hands(hands) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert_all(:insert_all, Hand, hands)
    |> Repo.transaction()
  end

  def create_game(flop, room_id, big_user_id, small_user_id) do
    {:ok, game} =
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

    create_event(%{
      type: "ante",
      user_id: big_user_id,
      game_id: game.id,
      amount: 40,
      inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
      updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    })

    create_event(%{
      type: "ante",
      user_id: small_user_id,
      game_id: game.id,
      amount: 20,
      inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
      updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    })

    {:ok, game}
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
        order_by: [asc: u.inserted_at]
      )

    Repo.all(get_hands)
  end

  def set_value_if_true(val, bool) do
    if bool do
      val
    end

    nil
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
          room_id: g.room_id,
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

    game = Repo.one(get_game)

    Map.put(game, :card1, set_value_if_true(game.card1, game.shown_flop))
    |> Map.put(:card2, set_value_if_true(game.card2, game.shown_flop))
    |> Map.put(:card3, set_value_if_true(game.card3, game.shown_flop))
    |> Map.put(:card4, set_value_if_true(game.card4, game.shown_turn))
    |> Map.put(:card5, set_value_if_true(game.card5, game.shown_river))
  end

  def calculate_amount_to_call(user_id, game_id) do
    query =
      from(e in "events",
        select: fragment("SUM(amount) as bet_amount"),
        group_by: e.user_id,
        order_by: fragment("bet_amount desc"),
        where: e.game_id == ^game_id,
        limit: 1
      )

    max_amount = Repo.one(query)

    amount_to_call_query =
      from(e in "events",
        select: fragment("SUM(amount) as bet_amount"),
        where: e.game_id == ^game_id and e.user_id == ^user_id,
        limit: 1
      )

    user_bet_amount = Repo.one(amount_to_call_query)

    if(user_bet_amount == nil) do
      max_amount
    else
      max_amount - user_bet_amount
    end
  end

  def find_active_user_by_game_id(game_id) do
    # TODO: this logic could have been easily done in the programming language
    # but was much harder and messier in sql
    # refactor to just pull all active users and determine which one should be next

    # if there is no events follow same logic as hands
    get_event =
      from(e in "events",
        select: %{id: e.id, user_id: e.user_id},
        limit: 1,
        where: e.game_id == ^game_id and e.type != "ante",
        order_by: [desc: :inserted_at]
      )

    event = Repo.one(get_event)

    if event == nil do
      inner_query =
        from(
          g in "games",
          join: u in User,
          on: [id: g.big_user_id],
          select: %{inserted_at: u.inserted_at},
          where: g.id == ^game_id
        )

      get_user_if_not_at_start_of_table =
        from(
          g in "games",
          limit: 1,
          join: h in Hand,
          on: [game_id: g.id],
          join: u in User,
          on: [id: h.user_id],
          join: bu in subquery(inner_query),
          select: %{user_id: h.user_id, username: u.name},
          where: g.id == ^game_id and u.inserted_at > bu.inserted_at and h.is_active == true,
          order_by: [asc: u.inserted_at]
        )

      active_user = Repo.one(get_user_if_not_at_start_of_table)

      if active_user do
        active_user
      else
        # TODO:  when new game starts need to handle this
        IO.puts("ISSUE WITH FINDING USER")
      end
    else
      inner_query =
        from(u in User,
          select: %{inserted_at: u.inserted_at},
          where: u.id == ^event.user_id
        )

      get_next_user =
        from(u in User,
          join: h in Hand,
          on: [user_id: u.id],
          left_join: bu in subquery(inner_query),
          where: h.game_id == ^game_id and h.is_active == true and u.inserted_at > bu.inserted_at,
          order_by: [asc: u.inserted_at],
          limit: 1,
          select: %{user_id: u.id, username: u.name}
        )

      active_user = Repo.one(get_next_user)

      if active_user do
        active_user
      else
        # TODO: when new game starts need to handle if this works or not for 3?
        # Select the use that has the lowest inserted date
        query =
          from(u in User,
            select: %{user_id: u.id, username: u.name},
            join: h in Hand,
            on: [user_id: u.id],
            limit: 1,
            where: h.game_id == ^game_id and h.is_active == true,
            order_by: [asc: u.inserted_at]
          )

        Repo.one(query)
      end

      # find user after event user_id
    end

    # if there is event take most recent event and find user after
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
