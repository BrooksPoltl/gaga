defmodule Gaga.Poker.Event do
  use Ecto.Schema
  import Ecto.Changeset

  schema "events" do
    field :amount, :integer
    field :type, :string
    field :user_id, :id
    field :room_id, :id

    timestamps()
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:type])
    |> validate_required([:type])
  end
end
