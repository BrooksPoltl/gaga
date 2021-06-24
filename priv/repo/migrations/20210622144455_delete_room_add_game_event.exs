defmodule Gaga.Repo.Migrations.DeleteRoomAddGameEvent do
  use Ecto.Migration

  def change do
    alter table("events") do
      add :game_id, references(:games, on_delete: :nothing)
      remove :room_id
    end
  end
end
