ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Gaga.Repo, :manual)

defmodule TestHelper do
  def print(card) do
    "#{card.suit}#{print_face(card)}"
  end

  defp parse_rank("J"), do: 11
  defp parse_rank("Q"), do: 12
  defp parse_rank("K"), do: 13
  defp parse_rank("A"), do: 14

  defp parse_rank(numeric_face) do
    {rank, _} = Integer.parse(numeric_face)
    rank
  end

  defp print_face(card) do
    r = card.rank

    cond do
      r in 2..10 -> Integer.to_string(r)
      r == 11 -> 'J'
      r == 12 -> 'Q'
      r == 13 -> 'K'
      r == 14 -> 'A'
    end
  end

  def print_cards(cards) do
    cards
    |> Enum.map(fn x -> print(x) end)
    |> Enum.join(" ")
  end
end
