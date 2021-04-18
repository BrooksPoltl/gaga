defmodule Gaga.Poker.Hand do
  use Ecto.Schema
  import Ecto.Changeset

  schema "hands" do
    field :card1, :string
    field :card2, :string
    field :is_active, :boolean, default: false
    field :game_id, :id
    field :user_id, :id

    timestamps()
  end

  @doc false
  def changeset(hand, attrs) do
    hand
    |> cast(attrs, [:card1, :card2, :is_active])
    |> validate_required([:card1, :card2, :is_active])
  end
end
