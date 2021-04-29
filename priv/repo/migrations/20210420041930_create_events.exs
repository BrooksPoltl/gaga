defmodule Gaga.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :type, :string
      add :amount, :integer
      add :user_id, references(:users, on_delete: :nothing)
      add :room_id, references(:rooms, on_delete: :nothing)

      timestamps()
    end

    create index(:events, [:user_id])
    create index(:events, [:room_id])
  end
end
