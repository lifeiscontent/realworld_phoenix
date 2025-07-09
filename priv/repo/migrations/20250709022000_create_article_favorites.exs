defmodule Realworld.Repo.Migrations.CreateArticleFavorites do
  use Ecto.Migration

  def change do
    create table(:article_favorites, primary_key: false) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :article_id, references(:articles, on_delete: :delete_all), null: false
      
      timestamps(updated_at: false, type: :utc_datetime)
    end

    create index(:article_favorites, [:user_id])
    create index(:article_favorites, [:article_id])
    create unique_index(:article_favorites, [:user_id, :article_id])
  end
end
