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
        where: room_user.room_id == ^room_id and u.cash > 0,
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

    if user.cash > amt do
      change(user, %{cash: user.cash - amt})
      |> Repo.update()
    else
      change(user, %{cash: 0})
      |> Repo.update()
    end
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

  def get_round_and_check_if_end(game_id) do
    round = get_round_by_game_id(game_id)
    check_if_its_end_of_round(game_id, round)
  end

  def get_round_by_game_id(game_id) do
    query =
      from(g in "games",
        select: %{shown_flop: g.shown_flop, shown_turn: g.shown_turn, shown_river: g.shown_river},
        where: g.id == ^game_id
      )

    game = Repo.one(query)

    cond do
      game.shown_river ->
        3

      game.shown_turn ->
        2

      game.shown_flop ->
        1

      true ->
        0
    end
  end

  def increment_round_and_get_game(game_id) do
    round = get_round_by_game_id(game_id)
    game = Repo.get_by(Game, id: game_id)

    cond do
      round == 0 ->
        change(game, %{shown_flop: true})
        |> Repo.update()

      round == 1 ->
        change(game, %{shown_turn: true})
        |> Repo.update()

      round == 2 ->
        change(game, %{shown_river: true})
        |> Repo.update()

      true ->
        nil
    end

    get_game_by_id(game_id)
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
          amount_of_events: fragment("count(*)"),
          user_id: e.user_id
        }
      )

    vals = Repo.all(query)
    first = Enum.at(vals, 0)

    is_amount_even? =
      Enum.reduce(vals, first.amount_of_events != 0, fn x, acc ->
        x.amount_paid == first.amount_paid and
          acc
      end)

    is_events_even? =
      Enum.reduce(vals, first.amount_of_events != 0, fn x, acc ->
        x.amount_of_events == first.amount_of_events and
          acc
      end)

    query2 =
      from(h in "hands",
        join: u in Users,
        on: [id: h.user_id],
        where: h.game_id == ^game_id and h.is_active == true and u.cash != 0,
        select: %{user_id: h.user_id}
      )

    hands = Repo.all(query2)

    filtered_folds =
      Enum.filter(vals, fn x ->
        Enum.find(hands, fn y -> y.user_id == x.user_id end) != nil
      end)

    if Enum.count(hands) == Enum.count(filtered_folds) do
      if is_amount_even? and is_events_even? do
        true
      else
        if first.amount_paid != 0 do
          is_amount_even?
        else
          false
        end
      end
    else
      false
    end
  end

  def create_event(attrs \\ %{}) do
    round = get_round_by_game_id(attrs.game_id)
    attrs_and_round = Map.put(attrs, :round, round)

    %Event{}
    |> Event.changeset(attrs_and_round)
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
    round = get_round_by_game_id(game_id)

    sub_query =
      from(e in "events",
        group_by: [e.user_id, e.round, e.game_id],
        select: %{
          user_id: e.user_id,
          amount_bet_this_round: sum(e.amount)
        },
        where: e.round == ^round and e.game_id == ^game_id
      )

    get_hands =
      from(h in "hands",
        join: game in Game,
        on: [id: h.game_id],
        join: ru in RoomUser,
        on: [user_id: h.user_id, room_id: game.room_id],
        join: u in User,
        on: [id: h.user_id],
        left_join: su in subquery(sub_query),
        on: su.user_id == h.user_id,
        select: %{
          id: h.id,
          card1: h.card1,
          card2: h.card2,
          user_id: h.user_id,
          name: u.name,
          cash: u.cash,
          is_active: h.is_active,
          amount_bet_this_round: su.amount_bet_this_round
        },
        where: h.game_id == ^game_id,
        order_by: [asc: u.inserted_at]
      )

    Repo.all(get_hands)
  end

  def set_value_if_true(val, bool) do
    if bool do
      val
    else
      nil
    end
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

  def break_ties(hands) do
    max_value =
      Enum.reduce(hands, 0, fn x, acc ->
        val = Enum.at(x.tie_breaking_ranks, 0)

        if val > acc do
          val
        else
          acc
        end
      end)

    filtered_hands =
      hands
      |> Enum.filter(&(Enum.at(&1.tie_breaking_ranks, 0) == max_value))

    if(
      length(filtered_hands) == 1 or length(Enum.at(filtered_hands, 0).tie_breaking_ranks) == 1
    ) do
      filtered_hands
    else
      pivoted_hands =
        Enum.map(filtered_hands, fn x ->
          new_tie_breaks =
            x.tie_breaking_ranks
            |> tl()

          Map.put(x, :tie_breaking_ranks, new_tie_breaks)
        end)

      break_ties(pivoted_hands)
    end
  end

  def evaluate_results(hands) do
    max_value =
      Enum.reduce(hands, 0, fn x, acc ->
        if x.value > acc do
          x.value
        else
          acc
        end
      end)

    ties =
      hands
      |> Enum.filter(&(&1.value == max_value))

    break_ties(ties)
  end

  def determine_winners(game, hands) do
    active_hands = Enum.filter(hands, fn x -> x.is_active == true end)

    if length(active_hands) == 1 do
      active_hands
    else
      scores =
        Enum.map(active_hands, fn x ->
          PokerLogic.evaluate_score([
            game.card1,
            game.card2,
            game.card3,
            game.card4,
            game.card5,
            x.card1,
            x.card2
          ])
        end)

      attach_scores =
        Enum.map(0..(length(active_hands) - 1), fn x ->
          Map.merge(Enum.at(active_hands, x), Enum.at(scores, x))
        end)

      evaluate_results(attach_scores)
    end
  end

  def get_game_by_id(game_id) do
    sub_query =
      from(e in "events",
        group_by: [e.game_id],
        select: %{pot_size: sum(e.amount), game_id: e.game_id},
        where: e.game_id == ^game_id
      )

    get_game =
      from(g in "games",
        join: su in subquery(sub_query),
        on: [game_id: g.id],
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
          shown_river: g.shown_river,
          pot_size: su.pot_size
        },
        limit: 1,
        where: g.id == ^game_id
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
      big_user_id = get_big_user_id(game_id)
      reverse_users = Enum.reverse(get_users)
      big_user_index = Enum.find_index(reverse_users, fn x -> x.user_id == big_user_id end)

      {start, end_enum} = Enum.split(reverse_users, big_user_index)

      concat_user =
        [end_enum, start]
        |> Enum.concat()

      if length(concat_user) == 2 do
        Enum.at(get_users, length(get_users) - 1).user_id
      else
        get_rid_of_first_two = Enum.slice(concat_user, 2, length(concat_user))
        Enum.at(Enum.reverse(get_rid_of_first_two), 0).user_id
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
      Enum.find(Enum.reverse(get_rid_of_first), fn x -> x.is_active and x.cash != 0 end).user_id
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
