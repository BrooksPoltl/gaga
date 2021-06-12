defmodule Gaga.Repo.Migrations.AddShownColumns do
  use Ecto.Migration

  def change do

    alter table("games") do
      add :shown_flop, :boolean, default: false
      add :shown_turn, :boolean, default: false
      add :shown_river, :boolean, default: false
    end

  end
end
