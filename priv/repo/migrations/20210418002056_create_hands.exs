defmodule Gaga.Repo.Migrations.CreateHands do
  use Ecto.Migration

  def change do
    create table(:hands) do
      add :card1, :string
      add :card2, :string
      add :is_active, :boolean, default: false, null: false
      add :game_id, references(:games, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:hands, [:game_id])
    create index(:hands, [:user_id])
  end
end
