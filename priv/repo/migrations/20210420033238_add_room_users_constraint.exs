defmodule Gaga.Repo.Migrations.AddRoomUsersConstraint do
  use Ecto.Migration

  def change do
    create unique_index(:room_users, [:room_id, :user_id], name: :table_member)
  end
end
