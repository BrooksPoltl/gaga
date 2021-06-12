defmodule PokerLogic do
  def create_game(table) do
    deck =
      create_deck()
      |> shuffle_deck()

    deal(table, deck)
  end

  def create_deck() do
    values = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
    suits = ["S", "C", "H", "D"]

    for suit <- suits, value <- values do
      "#{suit}#{value}"
    end
  end

  def shuffle_deck(deck) do
    Enum.shuffle(deck)
  end

  def deal(table, deck) do
    {new_table, new_deck} = add_hands(table, deck)

    flop =
      add_flop(new_deck)
      |> Tuple.to_list()
      |> Enum.at(0)

    {new_table, flop}
  end

  def add_flop(deck) do
    Enum.split(deck, 5)
  end

  def add_hands(table, deck) do
    Enum.map_reduce(table, deck, fn user, acc ->
      {hand, new_deck} = Enum.split(acc, 2)
      new_user = Map.put(user, :hand, hand)
      {new_user, new_deck}
    end)
  end
end
