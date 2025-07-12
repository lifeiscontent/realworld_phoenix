defmodule Realworld.Repo.Migrations.CreateUserFollows do
  use Ecto.Migration

  def change do
    create table(:user_follows, primary_key: false) do
      add :follower_id, references(:users, on_delete: :delete_all), null: false, primary_key: true

      add :following_id, references(:users, on_delete: :delete_all),
        null: false,
        primary_key: true

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:user_follows, [:follower_id])
    create index(:user_follows, [:following_id])
  end
end
