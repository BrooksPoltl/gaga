defmodule Gaga.Repo.Migrations.CreateRooms do
  use Ecto.Migration

  def change do
    create table(:rooms) do
      add :name, :string
      add :user_id, references(:users)
      timestamps()
    end

  end
end
