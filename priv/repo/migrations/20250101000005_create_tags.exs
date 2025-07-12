defmodule Realworld.Repo.Migrations.CreateTags do
  use Ecto.Migration

  def change do
    create table(:tags) do
      add :name, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:tags, [:name])

    # Create join table for articles and tags
    create table(:article_tags, primary_key: false) do
      add :article_id, references(:articles, on_delete: :delete_all),
        null: false,
        primary_key: true

      add :tag_id, references(:tags, on_delete: :delete_all), null: false, primary_key: true

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:article_tags, [:article_id])
    create index(:article_tags, [:tag_id])
  end
end
