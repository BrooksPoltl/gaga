defmodule Gaga.Poker do
  import Ecto.Query, warn: false
  alias Gaga.Repo

  alias Gaga.Poker.{Room, RoomUser}
  alias Gaga.Accounts.User

  def get_users_at_table(room_id) do
    query =
      from(u in "users",
        join: room_user in RoomUser,
        on: [user_id: u.id],
        select: %{
          username: u.name,
          user_id: u.id,
          cash: u.cash
        },
        where: room_user.room_id == ^room_id
      )

    Repo.all(query)
  end

  def list_rooms do
    query =
      from(r in "rooms",
        left_join: room_user in RoomUser,
        on: [room_id: r.id],
        join: user in User,
        on: [id: r.user_id],
        group_by: [r.id, r.name, r.user_id, user.name],
        select: %{
          name: r.name,
          user_id: r.user_id,
          id: r.id,
          count: count(room_user.id),
          username: user.name
        }
      )

    Repo.all(query)
  end

  @doc """
  Creates a room.

  ## Examples

      iex> create_room(%{field: value})
      {:ok, %Room{}}

      iex> create_room(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_room(attrs \\ %{}, user) do
    %Room{user_id: user}
    |> Room.changeset(attrs)
    |> Repo.insert()
  end
end
