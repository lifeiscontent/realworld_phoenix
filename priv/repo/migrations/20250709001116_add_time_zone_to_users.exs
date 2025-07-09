defmodule Realworld.Repo.Migrations.AddTimeZoneToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :time_zone, :string, default: "UTC"
    end
  end
end