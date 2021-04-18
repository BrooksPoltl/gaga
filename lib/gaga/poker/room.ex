defmodule Gaga.Poker.Room do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :name, :user]}
  schema "rooms" do
    field :name, :string
    belongs_to :user, Gaga.Accounts.User
    has_many :games, Gaga.Poker.Game
    many_to_many :users, Gaga.Accounts.User, join_through: "room_users"
    timestamps()
  end

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
