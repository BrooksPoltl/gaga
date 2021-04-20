defmodule Gaga.Poker.RoomUser do
  use Ecto.Schema
  import Ecto.Changeset

  schema "room_users" do
    field :room_id, :id
    field :user_id, :id

    timestamps()
  end

  @doc false
  def changeset(room_user, attrs) do
    room_user
    |> cast(attrs, [:room_id, :user_id])
    |> validate_required([:room_id, :user_id])
    |> unique_constraint(:already_joined, name: :table_member)
  end
end
