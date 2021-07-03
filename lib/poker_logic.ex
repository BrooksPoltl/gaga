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

  defp parse_rank("J"), do: 11
  defp parse_rank("Q"), do: 12
  defp parse_rank("K"), do: 13
  defp parse_rank("A"), do: 14

  defp parse_rank(numeric_face) do
    {rank, _} = Integer.parse(numeric_face)
    rank
  end

  def format_card(card) do
    {suit, rank} = String.split_at(card, 1)
    %{suit: suit, rank: parse_rank(rank)}
  end

  def evaluate_score(cards) do
    formatted_cards =
      Enum.map(cards, &format_card/1)
      |> Enum.sort(&(&1.rank >= &2.rank))

    calculate_score(formatted_cards)
  end

  defp calculate_score(cards) do
    [top_score | _] =
      [
        # straight_flush?(cards),
        PokerParser.four_of_a_kind?(cards),
        PokerParser.flush?(cards),
        PokerParser.full_house?(cards),
        PokerParser.straight?(cards),
        PokerParser.three_of_a_kind?(cards),
        PokerParser.two_pair?(cards),
        PokerParser.pair?(cards),
        PokerParser.high_card?(cards)
      ]
      |> Enum.reject(&(&1 == nil))

    top_score
  end

  def extract_ranks(cards) do
    Enum.map(cards, fn x -> x.rank end)
  end

  def extract_suits(cards) do
    Enum.map(cards, fn x -> x.suit end)
  end
end
