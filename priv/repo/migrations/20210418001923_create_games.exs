defmodule Gaga.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :card1, :string
      add :card2, :string
      add :card3, :string
      add :card4, :string
      add :card5, :string
      add :ante, :integer
      add :room_id, references(:rooms, on_delete: :nothing)
      add :big_user_id, references(:users, on_delete: :nothing)
      add :small_user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:games, [:room_id])
    create index(:games, [:big_user_id])
    create index(:games, [:small_user_id])
  end
end
