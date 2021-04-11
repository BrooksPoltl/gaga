defmodule Gaga.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:name, :string)
      add(:cash, :integer, default: 10000)

      timestamps()
    end
  end
end
