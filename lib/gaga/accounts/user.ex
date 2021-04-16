defmodule Gaga.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:cash, :name, :id]}
  schema "users" do
    field(:cash, :integer)
    field(:name, :string)
    has_one :room, Gaga.Poker.Room
    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
