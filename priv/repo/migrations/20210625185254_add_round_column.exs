defmodule Gaga.Repo.Migrations.AddRoundColumn do
  use Ecto.Migration

  def change do
    alter table("events") do
      add(:round, :integer, default: 0)
  end
end
end
