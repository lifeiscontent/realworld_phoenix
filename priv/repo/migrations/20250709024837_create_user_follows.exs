defmodule Realworld.Repo.Migrations.CreateUserFollows do
  use Ecto.Migration

  def change do
    create table(:user_follows, primary_key: false) do
      add :follower_id, references(:users, on_delete: :delete_all), null: false
      add :following_id, references(:users, on_delete: :delete_all), null: false
      
      timestamps(updated_at: false, type: :utc_datetime)
    end

    create index(:user_follows, [:follower_id])
    create index(:user_follows, [:following_id])
    create unique_index(:user_follows, [:follower_id, :following_id])
    
    # Prevent users from following themselves
    create constraint(:user_follows, :cannot_follow_self, 
      check: "follower_id != following_id")
  end
end
