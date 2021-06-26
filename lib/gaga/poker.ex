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
          cash: u.cash,
          inserted_at: u.inserted_at
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

  # returns number
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
    else
      false
    end
  end

  def check_if_its_end_of_round(game_id, round) do
    sub_query =
      from(e in "events",
        select: %{
          user_id: e.user_id,
          amount_paid: fragment("sum(amount)")
        },
        where: e.game_id == ^game_id and e.round == ^round,
        group_by: e.user_id
      )

    query =
      from(en in subquery(sub_query),
        join: e in Event,
        on: [user_id: en.user_id],
        where: e.game_id == ^game_id and e.round == ^round and e.type != "ante",
        group_by: [e.user_id, en.amount_paid],
        select: %{
          amount_paid: en.amount_paid,
          amount_of_events: fragment("count(*)")
        }
      )

    vals = Repo.all(query)
    first = Enum.at(vals, 0)

    Enum.reduce(vals, first.amount_of_events != 0, fn x, acc ->
      x.amount_paid == first.amount_paid and x.amount_of_events == first.amount_of_events and acc
    end)

    # edge cases folding?
    # what if they havent gone yet
  end

  def create_event(attrs \\ %{}) do
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

  def get_next_blind_user_ids(users, prev_game_id) do
    query =
      from(g in "games",
        join: u in User,
        on: fragment("u1.id = g0.big_user_id or u1.id = g0.small_user_id"),
        where: g.id == ^prev_game_id,
        select: %{
          id: u.id,
          inserted_at: u.inserted_at,
          big_user_id: g.big_user_id,
          small_user_id: g.small_user_id
        }
      )

    prev_big_and_small_user = Repo.all(query)

    big_user_inserted_at =
      Enum.find(prev_big_and_small_user, fn x -> x.big_user_id == x.id end).inserted_at

    # Format list so that they are in order starting with new small blind
    reverse_users = users

    small_user_index =
      Enum.find_index(reverse_users, fn x ->
        comparison = NaiveDateTime.compare(x.inserted_at, big_user_inserted_at)
        IO.inspect(comparison)
        comparison == :eq or comparison == :gt
      end)

    {start, end_enum} = Enum.split(reverse_users, small_user_index)

    concat_users = Enum.concat(end_enum, start)

    %{
      small_user_id: Enum.at(concat_users, 0).user_id,
      big_user_id: Enum.at(concat_users, 1).user_id
    }
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

  def get_big_user_id(game_id) do
    query = from(g in "games", select: %{id: g.big_user_id}, where: g.id == ^game_id)

    user_obj = Repo.one(query)
    user_obj.id
  end

  def find_active_user_by_game_id(game_id) do
    get_event =
      from(e in "events",
        select: %{id: e.id, user_id: e.user_id},
        limit: 1,
        where: e.game_id == ^game_id and e.type != "ante",
        order_by: [desc: :inserted_at]
      )

    event = Repo.one(get_event)

    if event == nil do
      get_users = get_hands_by_game_id(game_id)
      get_active_users = Enum.filter(get_users, fn x -> x.is_active == true end)
      big_user_id = get_big_user_id(game_id)

      big_user_index = Enum.find_index(get_active_users, fn x -> x.user_id == big_user_id end)

      if big_user_index == 0 do
        Enum.at(get_active_users, length(get_active_users) - 1).user_id
      else
        Enum.at(get_active_users, big_user_index - 1).user_id
      end
    else
      get_users = get_hands_by_game_id(game_id)
      reverse_users = Enum.reverse(get_users)
      event_user_index = Enum.find_index(reverse_users, fn x -> x.user_id == event.user_id end)

      {start, end_enum} = Enum.split(reverse_users, event_user_index)

      concat_user =
        [end_enum, start]
        |> Enum.concat()

      get_rid_of_first = Enum.slice(concat_user, 1, length(concat_user))
      Enum.find(get_rid_of_first, fn x -> x.is_active end).user_id
    end
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
