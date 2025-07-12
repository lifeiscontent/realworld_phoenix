defmodule Realworld.Repo.Migrations.CreateArticleFavorites do
  use Ecto.Migration

  def change do
    create table(:article_favorites, primary_key: false) do
      add :user_id, references(:users, on_delete: :delete_all), null: false, primary_key: true

      add :article_id, references(:articles, on_delete: :delete_all),
        null: false,
        primary_key: true

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:article_favorites, [:user_id])
    create index(:article_favorites, [:article_id])
  end
end
