defmodule Gaga.Poker.Event do
  use Ecto.Schema
  import Ecto.Changeset

  schema "events" do
    field :amount, :integer
    field :type, :string
    field :user_id, :id
    field :game_id, :id

    timestamps()
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:type, :amount, :user_id, :game_id])
    |> validate_required([:type, :amount, :user_id, :game_id])
  end
end
