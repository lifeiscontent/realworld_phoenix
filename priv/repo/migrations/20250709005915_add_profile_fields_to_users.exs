defmodule Realworld.Repo.Migrations.AddProfileFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :username, :string, null: false
      add :bio, :text
    end

    create unique_index(:users, [:username])
  end
end