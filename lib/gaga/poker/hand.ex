defmodule Gaga.Poker.Hand do
  use Ecto.Schema
  import Ecto.Changeset

  schema "hands" do
    field :card1, :string
    field :card2, :string
    field :is_active, :boolean, default: true
    field :game_id, :id
    field :user_id, :id

    timestamps()
  end

  @doc false
  def changeset(hand, attrs) do
    hand
    |> cast(attrs, [:card1, :card2, :game_id, :user_id])
    |> validate_required([:card1, :card2, :user_id, :game_id])
  end
end
