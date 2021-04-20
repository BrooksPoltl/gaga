defmodule Gaga.Repo.Migrations.CreateRoomUsers do
  use Ecto.Migration

  def change do
    create table(:room_users) do
      add :room_id, references(:rooms, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)
      add :sitting_out, :boolean, defaults: false

      timestamps()
    end

    create index(:room_users, [:room_id])
    create index(:room_users, [:user_id])
  end
end
