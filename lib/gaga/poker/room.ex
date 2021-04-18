defmodule Gaga.Poker.Room do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :name, :user]}
  schema "rooms" do
    field :name, :string
    belongs_to :user, Gaga.Accounts.User
    timestamps()
  end

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
