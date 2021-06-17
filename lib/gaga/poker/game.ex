defmodule Gaga.Poker.Game do
  use Ecto.Schema
  import Ecto.Changeset

  schema "games" do
    field :ante, :integer
    field :card1, :string
    field :card2, :string
    field :card3, :string
    field :card4, :string
    field :card5, :string
    field :room_id, :id
    field :big_user_id, :id
    field :small_user_id, :id
    field :shown_flop, :boolean
    field :shown_river, :boolean
    field :shown_turn, :boolean
    timestamps()
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [
      :card1,
      :card2,
      :card3,
      :card4,
      :card5,
      :ante,
      :room_id,
      :big_user_id,
      :small_user_id
    ])
    |> validate_required([
      :card1,
      :card2,
      :card3,
      :card4,
      :card5,
      :ante,
      :room_id,
      :big_user_id,
      :small_user_id
    ])
  end
end
